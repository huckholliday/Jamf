#!/bin/bash

# This script is designed to be run on a Mac via a Jamf Pro policy to clear failed MDM commands on a regular basis. This
# allows failed MDM commands or profiles to be re-pushed automatically.
#
# API rights required by account specified in jamfpro_user variable:
#
# Jamf Pro Server Objects:
#    Computers: Read
#
# Jamf Pro Server Actions:
#    Flush MDM Commands
#
# Original script from https://aporlebeke.wordpress.com/2019/01/04/auto-clearing-failed-mdm-commands-for-macos-in-jamf-pro/
# GitHub gist: https://gist.github.com/apizz/48da271e15e8f0a9fc6eafd97625eacd#file-ea_clear_failed_mdm_commands-sh
#
#
# Parameters:
# Parameter 4: Encrypted API account username
# Parameter 5: Encrypted API account password
# Parameter 6: Debug mode (true/false) - Enables additional output for debugging purposes

### VARIABLES ###
error=0 # Default exit code of success

jamfpro_url=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
jamfpro_url=${jamfpro_url%%/} # Remove the trailing slash from the Jamf Pro URL if needed.
jamfpro_user="" # Initialize variable
jamfpro_password="" # Initialize variable
machineUUID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { gsub(/"/,"",$3); print $3; }')

# Debug mode with default
debugMode="false"
if [[ "$6" == "true" ]]; then
	debugMode="true"
fi

# Encrypted API account username. Encrypted username should be in Parameter 4
jssAPIUsernameEncrypted="$4"
jssAPIUsernameSalt="<SALT>"
jssAPIUsernamePassphrase="<PASSPHRASE>"

# Encrypted API account password. Encrypted username should be in Parameter 5
jssAPIPasswordEncrypted="$5"
jssAPIPasswordSalt="<SALT>"
jssAPIPasswordPassphrase="<PASSPHRASE>"

### FUNCTIONS ###

function DecryptString() {
	# Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
	echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

function GetJamfProAPIToken() {
	# This function uses Basic Authentication to get a new bearer token for API authentication.
	api_token=$(/usr/bin/curl -X POST --silent -u "${jamfpro_user}:${jamfpro_password}" "${jamfpro_url}/api/v1/auth/token" | plutil -extract token raw -)
}

function APITokenValidCheck() {
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	api_authentication_check=$(/usr/bin/curl --write-out %{http_code} --silent --output /dev/null "${jamfpro_url}/api/v1/auth" --request GET --header "Authorization: Bearer ${api_token}")
}

function CheckAndRenewAPIToken() {
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	APITokenValidCheck

	# If the api_authentication_check has a value of 200, that means that the current
	# bearer token is valid and can be used to authenticate an API call.
	if [[ ${api_authentication_check} == 200 ]]; then
        # If the current bearer token is valid, it is used to connect to the keep-alive endpoint. This will
        # trigger the issuing of a new bearer token and the invalidation of the previous one.
        api_token=$(/usr/bin/curl "${jamfpro_url}/api/v1/auth/keep-alive" --silent --request POST --header "Authorization: Bearer ${api_token}" | plutil -extract token raw -)
	else
        # If the current bearer token is not valid, this will trigger the issuing of a new bearer token
		# using Basic Authentication.
   		GetJamfProAPIToken
	fi
}

function InvalidateToken() {
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	APITokenValidCheck

	# If the api_authentication_check has a value of 200, that means that the current
	# bearer token is valid and can be used to authenticate an API call.
	if [[ ${api_authentication_check} == 200 ]]; then
	    # If the current bearer token is valid, an API call is sent to invalidate the token.
      	authToken=$(/usr/bin/curl "${jamfpro_url}/api/v1/auth/invalidate-token" --silent  --header "Authorization: Bearer ${api_token}" -X POST)
      
		# Explicitly set value for the api_token variable to null.
      	api_token=""
	fi
}

function ClearFailedMDMCommands() { # Clears all failed MDM commands associated with a Jamf Pro computer ID.
	CheckAndRenewAPIToken
	/usr/bin/curl -sf --header "Authorization: Bearer ${api_token}" "${jamfpro_url}/JSSResource/commandflush/computers/id/${computerID}/status/Failed" -X DELETE
}

function GetJamfProComputerID() { # Uses the Mac's hardware UUID to identify the Mac's computer ID in Jamf Pro.
	CheckAndRenewAPIToken
    local computerID=$(/usr/bin/curl -sf --header "Authorization: Bearer ${api_token}" "${jamfpro_url}/JSSResource/computers/udid/${machineUUID}" -X GET -H "accept: application/xml" | /usr/bin/xmllint --xpath "/computer/general/id/text()" - 2>/dev/null)
	echo "$computerID"
}

function GetFailedMDMCommands() { # Uses the Mac's hardware UUID to download the list of failed MDM commands.
	CheckAndRenewAPIToken
    local xmlResult=$(/usr/bin/curl -sf --header "Authorization: Bearer ${api_token}" "${jamfpro_url}/JSSResource/computerhistory/udid/${machineUUID}/subset/Commands" -X GET -H "accept: application/xml" | /usr/bin/xmllint --xpath "/computer_history/commands/failed[node()]" - 2>/dev/null)
	echo "$xmlResult"
}

function debugInfo() {
    # Output info for testing purposes
    echo "Machine UUID: $machineUUID"
    echo "JSS URL: $jamfpro_url"
    echo "Username Salt: $jssAPIUsernameSalt"
    echo "Username Passphrase: $jssAPIUsernamePassphrase"
    echo "Password Salt: $jssAPIPasswordSalt"
    echo "Password Passphrase: $jssAPIPasswordPassphrase"
}

### MAIN PROGRAM ###

echo "Decrypting variables"
jamfpro_user=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
jamfpro_password=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)

# Build a list of failed MDM commands associated with a particular Mac.
echo "Getting any failed commands..."
xmlResult=$(GetFailedMDMCommands)

# Output debug info if debugMode is true
if [[ $debugMode == 'true' ]]; then
    # Run debugInfo function
    echo "Debug mode enabled"
    debugInfo
fi

computerID=$(GetJamfProComputerID)
echo "Computer ID: $computerID"

# Clear failed MDM commands if they exist
if [[ -n "$xmlResult" ]]; then

	echo "Removing failed MDM commands....."
	ClearFailedMDMCommands

	if [[ $? -eq 0 ]]; then
	    echo "Removed failed MDM commands."
	else
	   	echo "ERROR! Problem occurred when removing failed MDM commands!"
	   	error=1
	fi

else
	echo "No failed MDM commands found."
fi

echo "Invalidating token"
InvalidateToken

exit $error