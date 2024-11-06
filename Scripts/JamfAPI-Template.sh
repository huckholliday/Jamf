#!/bin/bash

# # # # # # # # # # # # # # # # # # # 
# This script template would be uploaded to Jamf Pro server and run in a policy when API is needed for gathering information, putting information, updating information, or deleting information in the Jamf Pro site.
# You must have a local account made in Jamf first with correct permissions needed for API calls and the username/password must be encrypted with the Salt/Pass Phrase saved to use in this script and encrypted data added to Policy.
# Encrypting Jamf API username and password can use https://github.com/brysontyrrell/EncryptedStrings
# # # # # # # # # # # # # # # # # # # 

### Set variables ###
JAMF_URL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')"
# Script parameter for debug mode to be set in policy as parameter 5
debugMode="$5"
# Script parameter input of encrypted username and password as encryptedUSERNAME;encryptedPASSWORD
jssUserInformationInput="$4"
IFS=';' read -ra jssUserInfoBits <<< "$jssUserInformationInput"
jssAPIUsernameEncrypted=${jssUserInfoBits[0]}
jssAPIPasswordEncrypted=${jssUserInfoBits[1]}
# Encrypted API account username salt and passphrase.
jssAPIUsernameSalt="UPDATEsaltWHENENCRYPTINGUSERINFORMATION"
jssAPIUsernamePassphrase="UPDATEpassphraseWHENENCRYPTINGUSERINFORMATION"
# Encrypted API account password salt and passphrase.
jssAPIPasswordSalt="UPDATEsaltWHENENCRYPTINGUSERINFORMATION"
jssAPIPasswordPassphrase="UPDATEpassphraseWHENENCRYPTINGUSERINFORMATION"
# Jamf API bearer token stuff
bearerToken=""
tokenExpirationEpoch="0" 

# XML header stuff
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

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

# # # # # # # # # # # # # # # # # # # 
# SCRIPT AND API CALLS WILL GO HERE #
# # # # # # # # # # # # # # # # # # # 
# EXAMPLE: COMPUTER_ID=$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/serialnumber/$SERIAL" | xpath -q -e '/computer/general/id/text()')


# Clear bearer token
invalidateToken
exit 0