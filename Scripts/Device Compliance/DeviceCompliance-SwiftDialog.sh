#!/bin/bash

#################################################################################################    
#
#
# Description: This script will use SwiftDialog to alert the user of required accounts and actions to take for registering in the Device Compliance process with Jamf Pro.
# Requires Swift Dialog to be installed on the Mac. If it is not installed, the script will install it from a Jamf policy.
# https://github.com/swiftDialog/swiftDialog
# Jamf API calls use encrypted username and password for security. To setup username and password encryption use https://github.com/brysontyrrell/EncryptedStrings
# Script must be run as root
#
# Jamf parameters
# Parameter 4 - Encrypted username string
# Parameter 5 - Encrypted username salt and passphrase as salt;passphrase
# Parameter 6 - Encrypted password string
# Parameter 7 - Encrypted password salt and passphrase as salt;passphrase
# Parameter 8 - SwiftDialog custom trigger name (ex: JCDialog)
# Parameter 9 - Device Compliance Registration custom trigger name (ex: dc-sd-reg)
# Parameter 10 - SwiftDialog icon custom image URL
# Parameter 11 - Help URL for the info button
#
# Created by: Logan Holliday
# 
# 
################################################################################################# 

# Verify we are running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root **EXITING**"
  exit 1
fi

#############
# Variables #
#############

# Path to SwiftDialog
dialogBinary="/usr/local/bin/dialog"
#Username information from Jamf Connect
currentuser=$( /usr/bin/stat -f "%Su" /dev/console )
# WPJ CHeck 
userHome=$(dscl . read "/Users/$loggedInUser" NFSHomeDirectory | awk -F ' ' '{print $2}')
# Get computer ID using SERIALFULL
machineUUID=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk '/IOPlatformUUID/ { gsub(/"/,"",$3); print $3; }')
JAMF_URL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')"
# Script parameter input of encrypted username and password
jssAPIUsernameEncrypted="$4"
jssAPIPasswordEncrypted="$6"
# Encrypted API account username salt and passphrase
jssUserInformationInput="$5"
IFS=';' read -ra jssUserInfoBits <<< "$jssUserInformationInput"
jssAPIUsernameSalt=${jssUserInfoBits[0]}
jssAPIUsernamePassphrase=${jssUserInfoBits[1]}
# Encrypted API account password salt and passphrase
jssPassInformationInput="$7"
IFS=';' read -ra jssPassInfoBits <<< "$jssPassInformationInput"
jssAPIPasswordSalt=${jssPassInfoBits[0]}
jssAPIPasswordPassphrase=${jssPassInfoBits[1]}
# Jamf API bearer token stuff
bearerToken=""
tokenExpirationEpoch="0" 
# XML header stuff
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
# Log for progress of script
scriptLog="/var/tmp/Registration.DC.log"
DialogCommandFile="/var/tmp/Dialog_progress.log"
# SwiftDialog Settings
title="Device Compliance Registration"
infobuttonaction="https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-intune-current/page/Computer_Regisration_for_End_Users.html"
infobuttontext="Registration Guide"
helpURL="${11}" # URL for help button
icon="${10}" # Custom icon for SwiftDialog
swiftInstaller="$8" # Jamf custom trigger for installing SwiftDialog
dcRegistration="$9" # Jamf custom trigger for Device Compliance Registration policy

#############
# Functions #
#############

# Check if the script log exists, if not create it
if [[ ! -f "${DialogCommandFile}" ]]; then
    touch "${DialogCommandFile}"
fi

# Function to update the script log
updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# Check if Swift Dialog is installed
checkDialogApp() {
  if [[ ! -f "$dialogBinary" ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: Dialog not found. Installing..."
    echo "Swift Dialog not found. Running Jamf policy to install Swift Dialog."
    jamf policy -event "$swiftInstaller"
  else
    updateScriptLog "PRE-FLIGHT CHECK: Dialog found."
    echo "Swift Dialog is installed."
  fi
}

# This function sends a command to a command file. Used for Dialog progress bar
dialog_command() {
    echo "$@" >> "$DialogCommandFile"
    sleep 0.1
}

# Notification to user before starting registration process
SwiftDialogConfirmation() {
      "$dialogBinary" \
      --title "$title" \
      --icon "$icon" \
      --iconsize "250" \
      --button1text "Register" \
      --messagefont size=14 \
      --message "# Important Notice \n \n Please use your $username credentials when prompted for a username and password." \
      --checkbox "I understand and acknowledge the instructions given to me.",enableButton1 --button1disabled \
      --quitkey k \
      --ontop \
      --infobuttontext "$infobuttontext" \
      --infobuttonaction "$infobuttonaction"
}

# Displays a SwiftDialog progress window with a custom message and icon during the device compliance registration process.
SwiftDialogProgress() {
      "$dialogBinary" \
      --title "$title" \
      --icon "$icon" \
      --iconsize "250" \
      --small \
      --messagefont size=14 \
      --message "Registration in process, please follow all prompts." \
      --quitkey k \
      --moveable \
      --messageposition center \
      --messagealign center \
      --position topleft \
      --button1disabled \
      --commandfile "$DialogCommandFile" \
      --infobuttontext "$infobuttontext" \
      --infobuttonaction "$infobuttonaction" \
      --progress &
}

# Displays a SwiftDialog window with a message indicating that the device compliance registration is incomplete.
SwiftDialogIncomplete() {
      "$dialogBinary" \
      --title "$title" \
      --icon "$icon" \
      --iconsize "250" \
      --small \
      --overlayicon "SF=exclamationmark.triangle.fill,color=auto" \
      --messagefont size=14 \
      --message "**Registration has encoutered an error.** \n \n Please contact support before attempting to register again." \
      --messageposition center \
      --messagealign center \
      --ontop \
      --button1text "Get Help" \
      --button1action "$helpURL" \
      --quitkey k \
      --position center
}

# Displays a SwiftDialog window with a message indicating that the device compliance registration is complete.
SwiftDialogComplete() {
      "$dialogBinary" \
      --title "$title" \
      --icon "$icon" \
      --iconsize "250" \
      --small \
      --messagefont size=14 \
      --message "Registration is now complete!" \
      --messageposition center \
      --messagealign center \
      --quitkey k \
      --timer 120 \
      --hidetimerbar true \
      --position center \
      --button1text "OK" \
      --infobuttontext "$infobuttontext" \
      --infobuttonaction "$infobuttonaction" \
      --moveable
}

# Jamf inventory update
InventoryUpdate() {
  echo "Starting the inventory update process..."
  jamf recon
}

# Compliance Registration policy trigger
ComplianceRegistration() {
  echo "Starting the device compliance registration process..."
  jamf policy -event "$dcRegistration"
}

# Decrypt String
DecryptString() {
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

# Prints the site and username associated with the computer from Jamf API.
getComputerDetails() {
  # Get computer ID using SERIALFULL
  COMPUTER_ID=$(/usr/bin/curl -sf --header "Authorization: Bearer ${bearerToken}" "${JAMF_URL}/JSSResource/computers/udid/${machineUUID}" -X GET -H "accept: application/xml" | /usr/bin/xmllint --xpath "/computer/general/id/text()" - 2>/dev/null)
  # Get computer details
  response=$(curl -s -H "Authorization: Bearer $bearerToken" "$JAMF_URL/JSSResource/computers/id/$COMPUTER_ID")
  # Extract username
  username=$(echo $response | xmllint --xpath "string(/computer/location/username)" -)
  
  echo "Username: $username"
}

# This function checks for the existence of the Azure Active Directory (AAD) plist file for the current user and verifies if the user has an Azure ID. It continuously loops until the plist file is found and the Azure ID is confirmed.
check_aad_plist(){
  while :; do
    if [[ -f "/Users/$currentuser/Library/Preferences/com.jamf.management.jamfAAD.plist" ]]; then
      haveAzureID=$(defaults read "/Users/$currentuser/Library/Preferences/com.jamf.management.jamfAAD.plist" have_an_Azure_id 2>/dev/null)
      if [[ "$haveAzureID" == "1" ]]; then
        echo "AAD ID found and confirmed."
        AAD_ID="Registered Successful"
        break
      else
        echo "WPJ Key Present. AAD ID not acquired for user."
        AAD_ID="Registration Error"
      fi
    fi
  done

}

# Function to check AAD_ID and display appropriate SwiftDialog
checkAADIDAndDisplayResult() {
  if [[ "$AAD_ID" == "Registered Successful" ]]; then
    killall "Dialog"
    sleep 5
    SwiftDialogComplete
  else
    killall "Dialog"
    sleep 5
    SwiftDialogIncomplete
  fi
  rm $scriptLog
}

# Function to wait for the Company Portal app to be opened and then continue after it is closed
checkCompanyPortalApp() {
  echo "Waiting for Company Portal to be opened..."
  local start_time=$(date +%s)
  local timeout=240  # 4 minutes in seconds

  while ! pgrep -x "Company Portal" > /dev/null; do
    sleep 5
    local current_time=$(date +%s)
    if (( current_time - start_time > timeout )); then
      echo "ERROR: Company Portal did not open within 4 minutes **EXITING**"
      invalidateToken
      # Close out dialog window
      dialog_command "quit:"
      SwiftDialogIncomplete
      exit 1
    fi
  done

  echo "Company Portal is open. Waiting for it to close..."
  while pgrep -x "Company Portal" > /dev/null; do
    sleep 5
  done
  echo "Company Portal is no longer open."
}

# Decrypt the username and password for Jamf API bearer token
echo "Decrypting"
jssAPIUsername=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
jssAPIPassword=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)

#############
#  Script   #
#############

checkDialogApp

getBearerToken

getComputerDetails

# This checks if the SwiftDialog command executes successfully. If it does, it will run the ComplianceRegistration function. If it does not, it will exit the script.
SwiftDialogConfirmation
if [[ $? -eq 0 ]]; then
  SwiftDialogProgress
  updateScriptLog "Sign into Company Portal..."
  dialog_command "progress: 20"
  dialog_command "progresstext: Sign into Company Portal with $username..."
  ComplianceRegistration
  # Adding to extra 2 seconds
  sleep 2
  else
  echo "ERROR: Process canceled or failed **EXITING**"
  SwiftDialogIncomplete
  exit 1
fi

# Signing into Company Portal...
updateScriptLog "Signing into Company Portal..."
dialog_command "progress: 25"
dialog_command "progresstext: Sign into Company Portal with $username..."
checkCompanyPortalApp
# Adding to extra 2 seconds
sleep 2

# Signing into Conditional Access JamfAAD
updateScriptLog "Signing into Conditional Access JamfAAD..."
dialog_command "progress: 50"
dialog_command "progresstext: Sign into Conditional Access JamfAAD..."
check_aad_plist
# Adding to extra 2 seconds
sleep 2

# Inventory update to Jamf
updateScriptLog "Inventory update to Jamf..."
dialog_command "progress: 75"
dialog_command "progresstext: Updating inventory record..."
InventoryUpdate
# Adding to extra 2 seconds
sleep 2

# Confirming registration
updateScriptLog "Confirming registration..."
dialog_command "progress: 95"
dialog_command "progresstext: Confirming registration..."
checkAADIDAndDisplayResult

invalidateToken
# Close out dialog window
dialog_command "quit:"
# Removing dialog tmp files
rm /var/tmp/Dialog_progress.log

exit 0