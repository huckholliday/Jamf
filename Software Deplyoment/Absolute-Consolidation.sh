#!/bin/bash

# # # # # # # # # # # # # # # # # # # 
# Script for installing Absolute for each site's specific tenant
# Jamf API account only needs read permissions
# Encrypting Jamf API username and password can use https://github.com/brysontyrrell/EncryptedStrings
# This does require a PKG file to be made in composer with all Absolute tenant files in separate folders for each studio/site with the Absolute installer in the root folder.
# # # # # # # # # # # # # # # # # # # 

### Set variables ###
JAMF_URL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')"
SERIALFULL="$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')"

# Script parameter for debug mode to be set in policy as parameter 5
debugMode="$5"

# Script parameter input of encrypted username and password as encryptedUSERNAME;encryptedpassword (API account with read access)
jssUserInformationInput="$4"
IFS=';' read -ra jssUserInfoBits <<< "$jssUserInformationInput"
jssAPIUsernameEncrypted=${jssUserInfoBits[0]}
jssAPIPasswordEncrypted=${jssUserInfoBits[1]}
# Encrypted API account username salt and passphrase
jssAPIUsernameSalt="SALT"
jssAPIUsernamePassphrase="PASSPHRASE"
# Encrypted API account password salt and passphrase
jssAPIPasswordSalt="SALT"
jssAPIPasswordPassphrase="PASSPHRASE"
# Jamf API bearer token stuff
bearerToken=""
tokenExpirationEpoch="0" 
# XML header stuff
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

#############
# FUNCTIONS #
#############

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

#################
# ACTUAL SCRIPT #
#################

# Decrypt the username and password for Jamf API bearer token
echo "Decrypting"
jssAPIUsername=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
jssAPIPassword=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)
getBearerToken

# Get site of machine from Jamf Pro API
SiteName=$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/serialnumber/$SERIALFULL" | xpath -q -e '/computer/general/site/name/text()')

# Run studio security app installs
# Convert SiteName to studio specific code
    case "$SiteName" in
        "Site 1" )
        studioID=A1
        ;;
        "Site 2" )
        studioID=B2
        ;;
        "Site 3" )
        studioID=C3
  esac

# Absolute installer
echo "Installing for $studioID"
mv /private/tmp/Absolute/AbsoluteFullAgent.pkg /private/tmp/Absolute/$studioID/
/usr/sbin/installer -pkg /private/tmp/Absolute/$studioID/AbsoluteFullAgent.pkg -target /

# Clear bearer token
invalidateToken
exit 0