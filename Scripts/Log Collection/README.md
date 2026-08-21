# Log Collection Script Explanation

## Overview
The **Log-Collection.sh** script is a Bash utility designed to facilitate automated log collection and upload from macOS devices to Jamf Pro. It allows end-users to collect system logs through a Self Service policy and automatically attach them to their device record for IT support and troubleshooting purposes.

## Purpose
This script serves as a bridge between macOS client systems and Jamf Pro, enabling:
- Centralized log collection from multiple files/locations
- Secure packaging of logs into a single zip archive
- Automatic upload of logs to the device's record in Jamf Pro
- OAuth-based authentication with Jamf Pro for secure API communication

## Requirements
- **Jamf Pro** instance with API access configured
- **macOS** version 10.13 (High Sierra) or later
- **OAuth Client Credentials** (Client ID and Client Secret) for Jamf Pro API authentication
- Proper encryption setup for the Client Secret (optional but recommended)
- Jamf Pro API clients and roles with the permissions Create/Read Computers and Create File Attachments. (Jamf known issue PI-008067 is open to adjust so Update Computers can be used instead of Create Computers permissions)

## How It Works

### 1. **Authentication Setup**
- Retrieves the Jamf Pro URL from the device's local configuration
- Decrypts the Client Secret using the provided salt and passphrase
- Obtains an OAuth bearer token from Jamf Pro using Client ID and Client Secret
- Validates that the token was successfully obtained before proceeding

### 2. **Log Collection**
- Collects specified log file paths provided as a parameter
- Creates a compressed zip archive with a descriptive filename format: `{ComputerName}-{CurrentUser}-{Timestamp}.zip`
- Stores the zip file temporarily in `/private/tmp/`

### 3. **Log Upload**
- Retrieves the device's Jamf Pro ID using its serial number
- Uploads the zip file to the device record in Jamf Pro as an attachment via the API
- Uses the OAuth bearer token for secure API authentication

### 4. **Cleanup**
- Invalidates the OAuth bearer token (securely logs out)
- Removes the temporary zip file from the device
- Exits successfully

## Parameters

| Parameter | Description |
|-----------|-------------|
| **Parameter 4** | Client ID (plaintext) for Jamf Pro OAuth authentication |
| **Parameter 5** | Encrypted Client Secret for Jamf Pro OAuth authentication |
| **Parameter 6** | Client Secret Salt and Passphrase (format: `salt;passphrase`) |
| **Parameter 7** | Log file paths to collect (space-separated list) |

### Example Parameter Configuration
```bash
# Parameter 4: Client ID
myClientID

# Parameter 5: Encrypted Client Secret
U2FsdGVkX1...

# Parameter 6: Salt and Passphrase
mySalt;myPassphrase

# Parameter 7: Log paths (space-separated)
/var/log/system.log /private/var/log/jamf.log /var/log/install.log
```

## Key Variables Used

### System Variables
- `mySerial`: Device serial number (used to identify the device in Jamf Pro)
- `currentUser`: Current logged-in user
- `compHostName`: Computer's local hostname
- `timeStamp`: Current date and time in `YYYY-MM-DD-HH-MM-SS` format

### Jamf Pro Variables
- `JAMF_URL`: Automatically detected from device's Jamf Pro configuration
- `bearerToken`: OAuth access token obtained for API requests

## Security Features

1. **OAuth Authentication**: Uses Client Credentials OAuth flow instead of basic authentication for better security
2. **Encrypted Client Secret**: Supports encrypted Client Secret using AES-256 encryption
3. **Token Management**: Automatically invalidates the OAuth token after use to prevent unauthorized access
4. **Temporary File Cleanup**: Removes sensitive log archives from the device after upload

## Encryption

The Client Secret is encrypted using AES-256 encryption. If you need to encrypt your Client Secret, you can use the encryption scripts available in the repository:
- Reference: `/scripts/Jamf/Scripts/Encryption/`
- Tool: [Jamf Encryption Scripts](https://github.com/huckholliday/Jamf/tree/main/Scripts/Encryption)

## API Endpoints Used

1. **OAuth Token Endpoint**: `POST /api/oauth/token` - Obtain bearer token
2. **Computer Lookup**: `GET /JSSResource/computers/serialnumber/{serial}/subset/general` - Get device ID
3. **File Upload**: `POST /JSSResource/fileuploads/computers/id/{id}` - Upload log file
4. **Token Invalidation**: `POST /api/v1/auth/invalidate-token` - Revoke bearer token

## Output

Success scenario:
- Log file successfully uploaded to Jamf Pro device record
- Temporary files cleaned up
- Script exits with code `0`

Error scenario (if token retrieval fails):
- Error message: "ERROR: Failed to obtain bearer token. Check Client ID/Secret and Jamf Pro URL."
- Script exits with code `1`

## Use Case

This script is typically deployed as a Self Service policy in Jamf Pro, allowing end-users to:
- Click a button in Self Service to collect logs
- Automatically package and upload their logs for IT support
- Enable faster troubleshooting and support ticket resolution

## Revision History

- **2020-12-01**: Added support for macOS Big Sur
- **2021-02-24**: Fixed missing variables
- **2026-08-21**: Converted to Jamf Pro API OAuth client credentials authentication and added automatic Jamf Pro URL detection

## Author
Originally written by Joshua Roskos | Jamf

For more information, visit: https://github.com/kc9wwh/logCollection
