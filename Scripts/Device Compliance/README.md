## Device Compliance Registration Script

Due to users having multiple accounts across different tenants, we encountered numerous failed registrations caused by incorrect account usage or users not adhering to the documented process. To address this, we developed a guided process to assist users through the registration steps, informing them of the correct account to use and upcoming prompts. This script leverages [SwiftDialog](https://github.com/swiftDialog/swiftDialog) to provide user alerts and utilizes the Jamf API to display the required account information and actions for completing the Device Compliance registration with Jamf Pro.

### Prerequisites

- [SwiftDialog](https://github.com/swiftDialog/swiftDialog) must be installed on the Mac. If it is not installed, the script will install it from a Jamf policy.
- The script must be run as root.
- Jamf API calls use encrypted username and password for security. To set up username and password encryption, use [EncryptedStrings](https://github.com/brysontyrrell/EncryptedStrings).

### Script Output

The script performs the following actions and logs the progress:

1. **Check for Root Privileges**: Ensures the script is run as root.
2. **Check SwiftDialog Installation**: Verifies if SwiftDialog is installed and installs it if necessary.
3. **Decrypt Credentials**: Decrypts the Jamf API username and password.
4. **Retrieve Jamf API Bearer Token**: Gets a bearer token for Jamf API authentication.
5. **Get Computer Details**: Retrieves the site and username associated with the computer from the Jamf API.
6. **Display Confirmation Dialog**: Shows a confirmation dialog to the user.
7. **Start Compliance Registration**: Initiates the device compliance registration process.
8. **Wait for Company Portal**: Waits for the Company Portal app to be opened and closed.
9. **Check AAD Plist**: Verifies the Azure ID from the AAD plist file.
10. **Update Jamf Inventory**: Updates the Jamf inventory.
11. **Display Result Dialog**: Shows a success or error dialog based on the registration result.
12. **Invalidate Bearer Token**: Invalidates the Jamf API bearer token.
13. **Cleanup**: Closes the dialog window and removes temporary files.

### Additional Information

For more details on SwiftDialog, visit the [SwiftDialog GitHub page](https://github.com/swiftDialog/swiftDialog).

For more details on setting up encrypted strings, visit the [EncryptedStrings GitHub page](https://github.com/brysontyrrell/EncryptedStrings).