#!/bin/bash

# macOS WPJ and jamfAAD item clean up
# By Bryce Carlson - 3/2/2021
# Heavily updated 2024-01-03 by Nick Kuras
#
# This script will remove the Workplace Join items made by Company Portal durring a device registration. It will also clear the jamfAAD items from the gatherAADInfo command run after a sucessful WPJ
# Clearing this data will allow for a re-registration devices side.
#
# NOTE: THIS SCRIPT WILL NOT CLEAR AZURE AD RECORDS (those are created by Company Portal). IT MAY CLEAR MEM RECORDS IF A JAMFAAD GATHER AAD INFO COMMAND RUNS AFTER THIS AS THE AAD ID IS NOW MISSING. THIS WILL RESULT IN A DEACTIVATION OF THE DEVICE RECORD SENT FROM JAMF PRO TO AAD (AND AAD TO MEM).
#
# Source: https://github.com/macbuddy-howto/jamfAAD-and-WPJ-scripts/blob/main/jamf-wpj-clean-up

# Jamf parameters
# Parameter 4 - Should Company Portal be removed? Valid entry: Yes/No
# Parameter 5 - Should Microsoft Teams be removed? Valid entry: Yes/No
# Parameter 6 - Encrypted string of username for Jamf Pro API access account
# Parameter 7 - Salt and passphrase for username, separated with a ; and no spaces (ex: 12345;abcde)
# Parameter 8 - Encrypted string of password for Jamf Pro API access account
# Parameter 9 - Salt and passphrase for password, separated with a ; and no spaces  (ex: 12345;abcde)
# Parameter 10 - ID number of Target Group (ex: 123)
# Parameter 11 - Name of Target Group (ex: S1 - My Test Group)

### VARIABLES ###

# Variable to run as current user
currentuser=$( /usr/bin/stat -f "%Su" /dev/console )
echo "Current user: $currentuser"
CompanyPortal=$4
MSFTTeams=$5

# URL for Jamf
jssAddress=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
jssAddressCleaned=$(echo ${jssAddress%/}) # Removes trailing slash, if exists

# Encrypted username with salt and passphrase info, default is $4. Salt and passphrase come in via $5 and are split at the ;
jssAPIUsernameEncrypted="$6"
jssUsernameInput="$7"
IFS=';' read -ra jssUsernameBits <<< "$jssUsernameInput"
jssAPIUsernameSalt=${jssUsernameBits[0]}
jssAPIUsernamePassphrase=${jssUsernameBits[1]}

# Encrypted password with salt and passphrase info, default is $6. Salt and passphrase come in via $7 and are split at the ;
jssAPIPasswordEncrypted="$8"
jssPasswordInput="$9"
IFS=';' read -ra jssPasswordBits <<< "$jssPasswordInput"
jssAPIPasswordSalt=${jssPasswordBits[0]}
jssAPIPasswordPassphrase=${jssPasswordBits[1]}

# Group ID and Name in Jamf come in via $8 and are split at the ;
targetGroupID="${10}"
targetGroupName="${11}"

xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>" # XML header stuff
jamfAPI="${jssAddressCleaned}/JSSResource/computergroups/id/" # Jamf API URL

# Get computer name and serial number for later use
computerName=$(/usr/sbin/scutil --get ComputerName)
machineSerial=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

# Jamf API bearer token stuff
bearerToken=""
tokenExpirationEpoch="0"

# Variable for current logged in user AAD ID cert and WPJ key 
AAD_ID=$(su $currentuser -c "security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/  \"alis\"<blob>=\"//;s/.$//'")
echo "AAD ID Value:"
echo "$AAD_ID"

### FUNCTIONS ###

function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
}

function removeFromGroup() {
    echo "Removing machine from group"
    apiData="<computer_group><id>${targetGroupID}</id><name>${targetGroupName}</name><computer_deletions><computer><serial_number>${machineSerial}</serial_number></computer></computer_deletions></computer_group>"

    # Flags: -s Silent -S Show error -k insecure -i include header -u User password
    curl -sSki "${jamfAPI}${targetGroupID}" \
        -H "Authorization: Bearer ${bearerToken}" \
        -H "Content-Type: text/xml" \
        -d "${xmlHeader}${apiData}" \
        -X PUT

    # Wait a few seconds in case there has been a network change
    sleep 15

    jamf recon
}

getBearerToken() {
    echo "Getting token"
	response=$(curl -s -u "$jssAPIUsername":"$jssAPIPassword" "$jssAddressCleaned"/api/v1/auth/token -X POST)
    #echo "Response: " "$response"
	bearerToken=$(echo "$response" | plutil -extract token raw -)
    #echo "Bearer token: " "$bearerToken"
	tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
    echo "Token expiration: " "$tokenExpiration"
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
    #echo "Token expiration epoch: " "$tokenExpirationEpoch"
}

checkTokenExpiration() {
    nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
    if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
    then
        echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
    else
        echo "No valid token available, getting new token"
        getBearerToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $jssAddressCleaned/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
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

### MAIN PROGRAM ###

# Decrypt the API user strings
jssAPIUsername=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
jssAPIPassword=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)

# Unload the jamfaad launch agent
echo "Unloading and removing jamfaad launch agent"
su $currentuser -c "launchctl unload /Library/LaunchAgents/com.jamf.management.jamfAAD.agent.plist"
rm -rf /Library/LaunchAgents/com.jamf.management.jamfAAD.agent.plist

# Close the Company Portal and Teams apps, if open
echo "Closing Company Portal"
killall "Company Portal"
echo "Closing Teams"
pkill Teams
echo "Closing any existing login prompts"
killall "Jamf Conditional Access"

# Remove various apps for deeper cleaning
# Company Portal
if [[ "$CompanyPortal" == "Yes" ]]; then
    echo "Removing Company Portal"
    rm -rf /Applications/Company\ Portal.app
else
    echo "Ignoring Company Portal"
fi

# Teams
if [[ "$MSFTTeams" == "Yes" ]]; then
    echo "Removing Teams"
    rm -rf /Applications/Microsoft\ Teams\ \(work\ or\ school\).app
    rm -rf /Applications/Microsoft\ Teams.app
else
    echo "Ignoring Microsoft Teams"
fi

# jamfAAD items
echo "Running jamfaad clean command"
su $currentuser -c "/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access clean"

echo "Removing keychain password items for jamfAAD"
su $currentuser -c "security delete-generic-password -l 'com.jamf.management.jamfAAD'"
rm -rf /Users/$currentuser/Library/Saved\ Application\ State/com.jamfsoftware.selfservice.mac.savedState
rm -r /Users/$currentuser/Library/Cookies/com.jamf.management.jamfAAD.binarycookies
rm -rf /Users/$currentuser/Library/Saved\ Application\ State/com.jamf.management.jamfAAD.savedState

# Company Portal app items
echo "Removing keychain password items for Company Portal app (v2.6 and higher with new com.microsoft.CompanyPortalMac bundle ID)"
rm -r /Users/$currentuser/Library/Cookies/com.microsoft.CompanyPortalMac.binarycookies
rm -rf /Users/$currentuser/Library/Saved\ Application\ State/com.microsoft.CompanyPortalMac.savedState
rm -r /Users/$currentuser/Library/Preferences/com.microsoft.CompanyPortalMac.plist
rm -r /Library/Preferences/com.microsoft.CompanyPortalMac.plist
rm -rf /Users/$currentuser/Library/Application\ Support/com.microsoft.CompanyPortalMac
rm -rf /Users/$currentuser/Library/Application\ Support/com.microsoft.CompanyPortalMac.usercontext.info
su $currentuser -c "security delete-generic-password -l 'https://device.login.microsoftonline.com'"
su $currentuser -c "security delete-generic-password -l 'https://device.login.microsoftonline.com/' "
su $currentuser -c "security delete-generic-password -l 'https://enterpriseregistration.windows.net' "
su $currentuser -c "security delete-generic-password -l 'https://enterpriseregistration.windows.net/' "
su $currentuser -c "security delete-generic-password -l 'com.microsoft.CompanyPortal'"
su $currentuser -c "security delete-generic-password -l 'com.microsoft.CompanyPortal.enrollment'"
su $currentuser -c "security delete-generic-password -l 'com.microsoft.CompanyPortalMac'"
su $currentuser -c "security delete-generic-password -l 'com.microsoft.CompanyPortal.HockeySDK'"
su $currentuser -c "security delete-generic-password -l 'com.microsoft.adalcache'"
su $currentuser -c "security delete-generic-password -l 'enterpriseregistration.windows.net'"
su $currentuser -c "security delete-generic-password -a 'com.microsoft.workplacejoin.thumbprint' "
su $currentuser -c "security delete-generic-password -a 'com.microsoft.workplacejoin.registeredUserPrincipalName' "

echo "Clearing things from root user"
security delete-generic-password -l 'https://device.login.microsoftonline.com'
security delete-generic-password -l 'https://device.login.microsoftonline.com/'
security delete-generic-password -l 'https://enterpriseregistration.windows.net'
security delete-generic-password -l 'https://enterpriseregistration.windows.net/'
security delete-generic-password -l 'com.jamf.management.jamfAAD'
security delete-generic-password -l 'com.microsoft.CompanyPortal'
security delete-generic-password -l 'com.microsoft.CompanyPortal.enrollment'
security delete-generic-password -l 'com.microsoft.CompanyPortalMac'
security delete-generic-password -l 'com.microsoft.CompanyPortal.HockeySDK'
security delete-generic-password -l 'com.microsoft.adalcache'
security delete-generic-password -l 'enterpriseregistration.windows.net'
security delete-generic-password -a 'com.microsoft.workplacejoin.thumbprint'
security delete-generic-password -a 'com.microsoft.workplacejoin.registeredUserPrincipalName'

# Remove AAD ID from keychain
echo "Removing WPJ for Device AAD ID $AAD_ID for $currentuser"
su $currentuser -c "security delete-identity -c $AAD_ID"
#echo "Removing WPJ for Device AAD ID $AAD_ID for $currentuser from SHA hash $CERT_BY_HASH"
echo "Removing WPJ for root user, if exists"
root_AAD_ID=$(security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/  \"alis\"<blob>=\"//;s/.$//')
security delete-identity -c $root_AAD_ID

# Check for existing bearer token, then request if expired/not there
checkTokenExpiration

# Use Jamf API to remove device from static cleanup group
removeFromGroup

# Invalidate any bearer tokens
invalidateToken

exit 0