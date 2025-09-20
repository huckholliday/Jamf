#!/bin/bash 
##########################################################################################
# Created by: Logan Holliday
# Date: 10.07.2023
# Update 04/01/2024 by Logan Holliday
# Description: Script to run when Zero Touch enrollment is completed that reports to a Slack channel on base security apps and link to enrolled computer in Jamf Pro
# Encrypting Jamf API username and password can use https://github.com/brysontyrrell/EncryptedStrings
#
################################################################################################# 

### Set variables ###
# Serial of current machine used to get computer ID in other veriables
SERIAL="$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')"
# Current local username
currentUser="$( /usr/bin/stat -f %Su /dev/console )"
# Get OS and build version
OSVersion="$(sw_vers -productVersion)"
OSBuild="$( sw_vers -buildVersion )"
# Get Jamf URL from preference plist
JAMF_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')
# Slack webhook URL that is created by Slack admins for specific channel use should be in Parameter 6
webhook_url="$6"


# Encrypted API account username. Encrypted username should be in Parameter 4, Make sure to change SALT KEY and PASSPHRASE
jssAPIUsernameEncrypted="$4"
jssAPIUsernameSalt="SALTKEY"
jssAPIUsernamePassphrase="PASSPHRASE"

# Encrypted API account password. Encrypted username should be in Parameter 5, Make sure to change SALT KEY and PASSPHRASE
jssAPIPasswordEncrypted="$5"
jssAPIPasswordSalt="SALTKEY"
jssAPIPasswordPassphrase="PASSPHRASE"

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

# Get FileVault status locally 
fv_check=$(diskutil info / | grep "FileVault" | awk '{print $2}')
if [ "$fv_check" == "Yes" ]; then
    fv_status=":lock: Enabled :lock:"
    echo "FileVault is enabled."
else
    fv_status=":warning: NOT ENABLED :warning:"
    echo "FileVault is disabled."
fi

# Get the computer ID in Jamf to link in Slack post.
COMPUTER_ID=$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/serialnumber/$SERIAL" | xpath -q -e '/computer/general/id/text()')
# Get the computer model information
MODEL="$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/id/$COMPUTER_ID" | xpath -e '/computer/hardware/model/text()' 2>/dev/null)"
# Get Site information for computer
SITE="$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/id/$COMPUTER_ID" | xpath -e '/computer/general/site/name/text()' 2>/dev/null)"
# Define the URL you want to include in the Slack message
link_url="$JAMF_URL/computers.html?id=$COMPUTER_ID&o=r"

# Get AD Username from assigned user in Jamf and compare to local username
adUser="$(curl -s -X GET -H "Authorization: Bearer ${bearerToken}" "$JAMF_URL/JSSResource/computers/id/$COMPUTER_ID" | xpath -e '/computer/location/username/text()' 2>/dev/null)"
adUser_without_domain="${adUser%%@*}"
# Make both reported usernames lowercase
adUser_lowercase=$(echo "$adUser_without_domain" | tr '[:upper:]' '[:lower:]')
currentUser_lowercase=$(echo "$currentUser" | tr '[:upper:]' '[:lower:]')
# Compare local username to assigned user's username
if [[ "$currentUser_lowercase" == "$adUser_lowercase" ]]; then
    userRESULT="$adUser_lowercase"
    echo "Local and AD username are the same."
else
    userRESULT=":warning: Local username and AD username differ :warning:"
    echo "Username mismatch. $currentUser_lowercase/$adUser_lowercase"
fi

# Check security app statuses and update Slack attachment color based on results
if [[ "$fv_status" != ":warning: NOT ENABLED :warning:" ]]; then
    attachment_color="#0000ff"
    echo "Success color set"
    else
    attachment_color="#FF0000"
    echo "Warning color set"
fi

# Slack message content
message="*${HOSTNAME} Enrollment Completed*"
attachment="{\"text\":\"OS Version: ${OSVersion} (${OSBuild})\",\"color\":\"${attachment_color}\",\"title\":\"View Computer in Jamf\",\"title_link\":\"$link_url\",\"fallback\":\"Fallback message for non-attachment viewers\",\"fields\":[{\"value\":\"Site: ${SITE}\",\"short\":false},{\"value\":\"Model: ${MODEL}\",\"short\":false},{\"value\":\"Serial: ${SERIAL}\",\"short\":false},{\"value\":\"Username: ${userRESULT}\",\"short\":false},{\"title\":\"Security Settings\"},{\"value\":\"FileVault Status: ${fv_status}\"}]}"

# Formatted message for Slack webhook
payload="{\"text\":\"$message\",\"attachments\":[$attachment]}"

# Send payload message to Slack webhook
/usr/bin/curl -sSX POST -H 'Content-type: application/json' --data "$payload" $webhook_url 2>&1
echo "Slack message sent"

invalidateToken
exit 0