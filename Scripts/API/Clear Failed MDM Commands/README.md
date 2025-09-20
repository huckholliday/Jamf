# Clear-Failed-MDM-Commands.sh

## Overview
`Clear-Failed-MDM-Commands.sh` is a Bash script designed to be run on a Mac via a Jamf Pro policy. Its purpose is to automatically clear failed MDM (Mobile Device Management) commands for the device in Jamf Pro, allowing those commands or profiles to be re-pushed as needed.

## Features
- Uses encrypted Jamf API credentials for secure authentication
- Retrieves the device's Jamf Pro computer ID using its hardware UUID
- Checks for any failed MDM commands associated with the device
- Clears failed MDM commands if found
- Supports debug mode for additional output and troubleshooting
- Invalidates the API token at the end of execution

## Usage
1. **Encrypt your Jamf API credentials** using [Encryption prompt](https://raw.githubusercontent.com/huckholliday/Jamf/refs/heads/main/Scripts/Encryption/EncryptPrompt.sh).
2. **Upload the script to Jamf Pro** and attach it to a policy.
3. **Set script parameters** in the policy:
   - **Parameter 4:** Encrypted API account username
   - **Parameter 5:** Encrypted API account password
   - **Parameter 6:** Debug mode (`true` or `false`)
4. **Assign the policy to run on Macs as needed (e.g., on a schedule or as a self-service policy).**

## Requirements
- Jamf Pro server with API access
- API account with the following rights:
  - Computers: Read
  - Flush MDM Commands
- Encrypted credentials
- macOS with Bash and OpenSSL

## Security
- Credentials are never stored in plain text; they are decrypted at runtime only.
- Jamf API bearer tokens are invalidated at the end of the script.

## References
- [Original script inspiration](https://aporlebeke.wordpress.com/2019/01/04/auto-clearing-failed-mdm-commands-for-macos-in-jamf-pro/)
- [GitHub Gist](https://gist.github.com/apizz/48da271e15e8f0a9fc6eafd97625eacd#file-ea_clear_failed_mdm_commands-sh)
- [EncryptedStrings](https://github.com/brysontyrrell/EncryptedStrings)

---

**Note:** This script is intended for use in Jamf Pro automation and should be tested in your environment before wide deployment.
