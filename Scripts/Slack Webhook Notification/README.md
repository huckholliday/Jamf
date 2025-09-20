# SlackNotification-CompletedEnrollment.sh

## Overview
`SlackNotification-CompletedEnrollment.sh` is a Bash script designed to notify a Slack channel when a Zero Touch enrollment is completed on a Mac. It gathers key security and system information, checks FileVault status, and posts a summary (including a link to the enrolled computer in Jamf Pro) to a specified Slack channel using a webhook.

## Features
- Reports to Slack when a device completes Zero Touch enrollment
- Posts OS version, build, model, serial, site, and username details
- Checks and reports FileVault status
- Compares local username to Jamf-assigned username and flags mismatches
- Includes a direct link to the computer record in Jamf Pro
- Uses encrypted Jamf API credentials for secure authentication
- Color-codes Slack message based on security status

## Usage
1. **Encrypt Jamf API credentials** using [EncryptPromt.sh](https://raw.githubusercontent.com/huckholliday/Jamf/refs/heads/main/Scripts/Encryption/EncryptPrompt.sh).
2. **Upload the script to Jamf Pro** and attach it to a policy that runs at the end of enrollment.
3. **Provide the following parameters:**
	- **Parameter 4:** Encrypted Jamf API username
	- **Parameter 5:** Encrypted Jamf API password
	- **Parameter 6:** Slack webhook URL for the target channel
4. **Set the correct salt and passphrase** in the script for decryption.

## Security
- Credentials are never stored in plain text; they are decrypted at runtime only.
- Jamf API bearer tokens are invalidated at the end of the script.

## Requirements
- Jamf Pro server with API access
- Slack webhook URL for the target channel
- Encrypted Jamf API credentials
- macOS with Bash and OpenSSL

## References
- [Jamf Pro API Documentation](https://developer.jamf.com/jamf-pro/docs)
- [EncryptedStrings](https://github.com/brysontyrrell/EncryptedStrings)

---

**Note:** This script is intended for use in automated Jamf Pro workflows and should be customized as needed for your environment.
