#!/bin/bash

#################################################################################################    
#
# Description: This script uses SwiftDialog to guide users through the Device Compliance registration process with Jamf Pro.
# Requires SwiftDialog and Jamf API credentials (encrypted). 
# https://github.com/swiftDialog/swiftDialog
# https://github.com/brysontyrrell/EncryptedStrings
# Script must be run as root.
#
# Jamf parameters:
# $4 - Encrypted username string
# $5 - Encrypted username salt and passphrase (format: salt;passphrase)
# $6 - Encrypted password string
# $7 - Encrypted password salt and passphrase (format: salt;passphrase)
# $8 - SwiftDialog custom trigger name (e.g., JCDialog)
# $9 - Device Compliance Registration custom trigger name (e.g., dc-sd-reg)
# $10 - SwiftDialog icon custom image URL
# $11 - Help URL for the info button
#
# Created by: Logan Holliday
#
################################################################################################# 

# Ensure script is run as root
if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root. Exiting."
  exit 1
fi

#############
# Variables #
#############

dialogBinary="/usr/local/bin/dialog"
currentuser=$(stat -f "%Su" /dev/console)
userHome=$(dscl . read "/Users/$currentuser" NFSHomeDirectory | awk '{print $2}')
machineUUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/ {print $4}')
JAMF_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')

# Encrypted credentials
jssAPIUsernameEncrypted="$4"
jssAPIPasswordEncrypted="$6"
IFS=';' read -r jssAPIUsernameSalt jssAPIUsernamePassphrase <<< "$5"
IFS=';' read -r jssAPIPasswordSalt jssAPIPasswordPassphrase <<< "$7"

# Jamf parameters
swiftInstaller="$8"
dcRegistration="$9"
icon="$10"
helpURL="$11"

# Other variables
scriptLog="/var/tmp/Registration.DC.log"
DialogCommandFile="/var/tmp/Dialog_progress.log"
title="Device Compliance Registration"
infobuttontext="Registration Guide"
infobuttonaction="https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-intune-current/page/Computer_Regisration_for_End_Users.html"

#############
# Functions #
#############

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$scriptLog"
}

checkDialogApp() {
  if [[ ! -f "$dialogBinary" ]]; then
    log "PRE-FLIGHT CHECK: SwiftDialog not found. Installing..."
    jamf policy -event "$swiftInstaller"
  else
    log "PRE-FLIGHT CHECK: SwiftDialog found."
  fi
}

dialogCommand() {
  echo "$@" >> "$DialogCommandFile"
  sleep 0.1
}

showDialog() {
  "$dialogBinary" "$@"
}

decryptString() {
  echo "$1" | openssl enc -aes256 -md md5 -d -a -A -S "$2" -k "$3"
}

getBearerToken() {
  log "Fetching Jamf API token..."
  local response
  response=$(curl -s -u "$jssAPIUsername:$jssAPIPassword" "$JAMF_URL/api/v1/auth/token" -X POST)
  bearerToken=$(echo "$response" | plutil -extract token raw -)
}

invalidateToken() {
  local responseCode
  responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer $bearerToken" "$JAMF_URL/api/v1/auth/invalidate-token" -X POST -s -o /dev/null)
  if [[ $responseCode -eq 204 ]]; then
    log "Token successfully invalidated."
  elif [[ $responseCode -eq 401 ]]; then
    log "Token already invalid."
  else
    log "Error invalidating token."
  fi
}

checkAADPlist() {
  while :; do
    if [[ -f "/Users/$currentuser/Library/Preferences/com.jamf.management.jamfAAD.plist" ]]; then
      local haveAzureID
      haveAzureID=$(defaults read "/Users/$currentuser/Library/Preferences/com.jamf.management.jamfAAD.plist" have_an_Azure_id 2>/dev/null)
      if [[ "$haveAzureID" == "1" ]]; then
        log "AAD ID confirmed."
        AAD_ID="Registered Successful"
        break
      else
        log "AAD ID not acquired."
        AAD_ID="Registration Error"
      fi
    fi
    sleep 5
  done
}

checkCompanyPortalApp() {
  log "Waiting for Company Portal to open..."
  local start_time=$(date +%s)
  local timeout=240

  while ! pgrep -x "Company Portal" > /dev/null; do
    sleep 5
    if (( $(date +%s) - start_time > timeout )); then
      log "ERROR: Company Portal did not open within 4 minutes. Exiting."
      invalidateToken
      dialogCommand "quit:"
      showDialog --message "Registration failed. Contact support." --button1text "OK"
      exit 1
    fi
  done

  log "Company Portal opened. Waiting for it to close..."
  while pgrep -x "Company Portal" > /dev/null; do
    sleep 5
  done
  log "Company Portal closed."
}

#############
#  Script   #
#############

# Decrypt credentials
log "Decrypting credentials..."
jssAPIUsername=$(decryptString "$jssAPIUsernameEncrypted" "$jssAPIUsernameSalt" "$jssAPIUsernamePassphrase")
jssAPIPassword=$(decryptString "$jssAPIPasswordEncrypted" "$jssAPIPasswordSalt" "$jssAPIPasswordPassphrase")

# Pre-flight checks
checkDialogApp
getBearerToken

# Start registration process
showDialog --title "$title" --icon "$icon" --button1text "Register" --message "Please follow the instructions." --checkbox "I understand." --button1disabled
if [[ $? -eq 0 ]]; then
  dialogCommand "progress: 20"
  dialogCommand "progresstext: Signing into Company Portal..."
  checkCompanyPortalApp

  dialogCommand "progress: 50"
  dialogCommand "progresstext: Signing into Conditional Access..."
  checkAADPlist

  dialogCommand "progress: 75"
  dialogCommand "progresstext: Updating inventory..."
  jamf recon

  dialogCommand "progress: 95"
  dialogCommand "progresstext: Confirming registration..."
  if [[ "$AAD_ID" == "Registered Successful" ]]; then
    showDialog --message "Registration complete!" --button1text "OK"
  else
    showDialog --message "Registration failed. Contact support." --button1text "Get Help" --button1action "$helpURL"
  fi
else
  log "ERROR: Registration canceled or failed."
  showDialog --message "Registration failed. Contact support." --button1text "OK"
  exit 1
fi

# Cleanup
invalidateToken
dialogCommand "quit:"
rm -f "$DialogCommandFile" "$scriptLog"

exit 0