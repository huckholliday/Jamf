## Device Compliance Registration Script

Due to users having multiple accounts across different tenants, we encountered numerous failed registrations caused by incorrect account usage or users not adhering to the documented process. To address this, we developed a guided process to assist users through the registration steps, informing them of the correct account to use and upcoming prompts. This script leverages [SwiftDialog](https://github.com/swiftDialog/swiftDialog) to provide user alerts and utilizes the Jamf API to display the required account information and actions for completing the Device Compliance registration with Jamf Pro.

### Prerequisites

- [SwiftDialog](https://github.com/swiftDialog/swiftDialog) must be installed on the Mac. If it is not installed, the script will install it from a Jamf policy.
- The script must be run as root.
- Jamf API calls use encrypted username and password for security. To set up username and password encryption, use [EncryptedStrings](https://raw.githubusercontent.com/huckholliday/Jamf/refs/heads/main/Scripts/Encryption/EncryptPrompt.sh).
- You should already have Device Compliance setup and working in your Jamf tenat. [Device Compliance with Microsoft Entra and Jamf Pro](https://learn.jamf.com/bundle/technical-paper-microsoft-intune-current/page/Device_Compliance_with_Microsoft_Intune_and_Jamf_Pro.html)
- In Jamf you will need to have a policy setup with a custom trigger for starting the Device Compliance process in Jamf.

### Script Output

The script performs the following actions and logs the progress:

1. **Check for Root Privileges**: Ensures the script is run as root.
    ```bash
    if [[ $(id -u) -ne 0 ]]; then
      echo "ERROR: This script must be run as root **EXITING**"
      exit 1
    fi
    ```
2. **Check SwiftDialog Installation Function**: Verifies if SwiftDialog is installed and installs it if necessary.
    ```bash
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
    ```
3. **Decrypt Credentials**: Decrypts the Jamf API username and password.
    ```bash
    DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
    }

    jssAPIUsername=$(DecryptString $jssAPIUsernameEncrypted $jssAPIUsernameSalt $jssAPIUsernamePassphrase)
    jssAPIPassword=$(DecryptString $jssAPIPasswordEncrypted $jssAPIPasswordSalt $jssAPIPasswordPassphrase)
    ```
4. **Retrieve Jamf API Bearer Token**: Gets a bearer token for Jamf API authentication.
    ```bash
    getBearerToken() {
    echo "Getting token"
	response=$(curl -s -u "$jssAPIUsername":"$jssAPIPassword" "$JAMF_URL"/api/v1/auth/token -X POST)
	bearerToken=$(echo "$response" | plutil -extract token raw -)
    }
    ```
5. **Get Computer Details**: Retrieves the site and username associated with the computer from the Jamf API.
    ```bash
    getComputerDetails() {
    # Get computer ID using SERIALFULL
    COMPUTER_ID=$(/usr/bin/curl -sf --header "Authorization: Bearer ${bearerToken}" "${JAMF_URL}/JSSResource/computers/udid/${machineUUID}" -X GET -H "accept: application/xml" | /usr/bin/xmllint --xpath "/computer/general/id/text()" - 2>/dev/null)
    # Get computer details
    response=$(curl -s -H "Authorization: Bearer $bearerToken" "$JAMF_URL/JSSResource/computers/id/$COMPUTER_ID")
    # Extract username
    username=$(echo $response | xmllint --xpath "string(/computer/location/username)" -)
    
    echo "Username: $username"
    }
    ```
6. **Display Confirmation Dialog**: Shows a confirmation dialog to the user.
    ```bash
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

    ```
7. **Start Compliance Registration**: Initiates the device compliance registration process.
    ```bash
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
    ```
8. **Wait for Company Portal**: Waits for the Company Portal app to be opened and closed.
    ```bash
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
    ```
9. **Check AAD Plist**: Verifies the Azure ID from the AAD plist file.
    ```bash
    updateScriptLog "Signing into Conditional Access JamfAAD..."
    dialog_command "progress: 50"
    dialog_command "progresstext: Sign into Conditional Access JamfAAD..."
    check_aad_plist
    ```
    ```bash
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
    ```
10. **Update Jamf Inventory**: Updates the Jamf inventory.
    ```bash
    updateScriptLog "Inventory update to Jamf..."
    dialog_command "progress: 75"
    dialog_command "progresstext: Updating inventory record..."
    InventoryUpdate
    ```
    ```bash
    InventoryUpdate() {
        echo "Starting the inventory update process..."
        jamf recon
    }
    ```
11. **Display Result Dialog**: Shows a success or error dialog based on the registration result.
    ```bash
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
    ```
    ```bash
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
    ```
12. **Invalidate Bearer Token**: Invalidates the Jamf API bearer token.
    ```bash
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
    ```
13. **Cleanup**: Closes the dialog window and removes temporary files.
    ```bash
    # Close out dialog window
    dialog_command "quit:"
    # Removing dialog tmp files
    rm /var/tmp/Dialog_progress.log

    exit 0
    ```

### Additional Information

For more details on SwiftDialog, visit the [SwiftDialog GitHub page](https://github.com/swiftDialog/swiftDialog).

For more details on setting up encrypted strings, visit the [EncryptedStrings GitHub page](https://github.com/brysontyrrell/EncryptedStrings).