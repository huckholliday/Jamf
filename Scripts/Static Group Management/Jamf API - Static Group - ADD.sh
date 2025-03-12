#!/bin/sh

# Script for adding computer to a static group in JSS.

# Parameter 4 - Script parameter input of encrypted username and password as encryptedUSERNAME;encryptedPASSWORD
# Parameter 5 - Script parameter input of encrypted username salt and passphrase as encryptedSALT;encryptedPASSPHRASE
# Parameter 6 - Script parameter input of encrypted password salt and passphrase as encryptedSALT;encryptedPASSPHRASE
# Parameter 7 - ID of Static Computer Group
# Parameter 8 - Full name of Static Computer Group

# Verify we are running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root **EXITING**"
  exit 1
fi

### Variables ###

# URL for Jamf
jssAddress=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
jssAddressCleaned=$(echo ${jssAddress%/}) # Removes trailing slash, if exists
JAMF_URL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')"

# Script parameter input of encrypted username and password as encryptedUSERNAME;encryptedPASSWORD
jssUserInformationInput="$4"
IFS=';' read -ra jssUserInfoBits <<< "$jssUserInformationInput"
jssAPIUsernameEncrypted=${jssUserInfoBits[0]}
jssAPIPasswordEncrypted=${jssUserInfoBits[1]}

# Script parameter input of encrypted username salt and passphrase as encryptedSALT;encryptedPASSPHRASE
jssUserSaltPassInformationInput="$5"
IFS=';' read -ra jssUserSaltPassInfoBits <<< "$jssUserSaltPassInformationInput"
jssAPIUsernameSalt=${jssUserSaltPassInfoBits[0]}
jssAPIUsernamePassphrase=${jssUserSaltPassInfoBits[1]}

# Script parameter input of encrypted password salt and passphrase as encryptedSALT;encryptedPASSPHRASE
jssPasswordSaltPassInformationInput="$6"
IFS=';' read -ra jssPasswordSaltPassInfoBits <<< "$jssPasswordSaltPassInformationInput"
jssAPIPasswordSalt=${jssPasswordSaltPassInfoBits[0]}
jssAPIPasswordPassphrase=${jssPasswordSaltPassInfoBits[1]}

# TargetGroupID name should be $7 in JSS - replacing for testing
TargetGroupID="$7"
TargetGroupName="$8"

# Jamf API bearer token stuff
bearerToken=""
tokenExpirationEpoch="0" 

# XML header stuff
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>" # XML header stuff
jamfAPI="${jssAddressCleaned}/JSSResource/computergroups/id/" # Jamf API URL

# API Process
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

# Get Jamf API Bearer token for session
getBearerToken() {
    echo "Getting token"
	response=$(curl -s -u "$jssAPIUsername":"$jssAPIPassword" "$JAMF_URL"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
}

# Invalidate Bearer Token for session
invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL"/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}

# Decrypt the username and password for Jamf API bearer token
echo "Decrypting"
jssAPIUsername=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
jssAPIPassword=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)

getBearerToken

ComputerName=$(/usr/sbin/scutil --get ComputerName)
machineSerial=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')
apiURL="JSSResource/computergroups/id/"

# Add computer to a group
echo "Adding ${ComputerName} to static group, ID: ${TargetGroupID} NAME: ${TargetGroupName}"

apiData="<computer_group><id>${TargetGroupID}</id><name>${TargetGroupName}</name><computer_additions><computer><serial_number>${machineSerial}</serial_number></computer></computer_additions></computer_group>"

# Flags: -s Silent -S Show error -k insecure -i include header -u User password
curl -sSki "${jamfAPI}${TargetGroupID}" \
    -H "Authorization: Bearer ${bearerToken}" \
    -H "Content-Type: text/xml" \
    -d "${xmlHeader}${apiData}" \
    -X PUT

invalidateToken

jamf recon

exit 0