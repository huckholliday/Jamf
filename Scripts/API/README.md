# JamfAPI-Template.sh

## Overview

`JamfAPI-Template.sh` is a Bash script template designed for use with Jamf Pro server policies. It provides a secure and reusable framework for performing API operations (GET, POST, PUT, DELETE) against a Jamf Pro instance. The script is intended to be uploaded to a Jamf Pro server and executed as part of a policy workflow.

## Features
- Securely handles Jamf API credentials using encrypted strings, salts, and passphrases.
- Supports decryption of credentials at runtime using OpenSSL.
- Automates the process of obtaining and invalidating Jamf API bearer tokens.
- Provides a section for custom API calls to be added as needed.
- Example usage for retrieving computer IDs by serial number.

## Usage
1. **Prepare Encrypted Credentials:**
    - Use the [Encryption folder](https://github.com/huckholliday/Jamf/Scripts/Encryption) to encrypt your Jamf API username and password.
    - Store the encrypted username, password, salts, and passphrases as Jamf policy parameters.

2. **Script Parameters:**
   - **Parameter 4:** Encrypted username and password, separated by a semicolon (`encryptedUSERNAME;encryptedPASSWORD`).
   - **Parameter 5:** Encrypted username salt and passphrase, separated by a semicolon (`encryptedSALT;encryptedPASSPHRASE`).
   - **Parameter 6:** Encrypted password salt and passphrase, separated by a semicolon (`encryptedSALT;encryptedPASSPHRASE`).

3. **Upload and Configure in Jamf Pro:**
   - Upload the script to your Jamf Pro server.
   - Create a policy and attach the script, providing the required parameters.

4. **Customize API Calls:**
   - Insert your desired API operations in the designated section of the script.

## Security
- Credentials are never stored in plain text; they are decrypted only at runtime.
- Bearer tokens are invalidated at the end of the script to maintain session security.

## Example
The script includes an example of retrieving a computer ID by serial number using the Jamf API.

## Requirements
- Jamf Pro server with API access.
- Local Jamf account with appropriate API permissions.
- Encrypted credentials generated with EncryptedStrings.
- macOS with Bash and OpenSSL available.

## References
- [Jamf Pro API Documentation](https://developer.jamf.com/jamf-pro/docs)
- [EncryptedStrings by Bryson Tyrrell](https://github.com/brysontyrrell/EncryptedStrings)

---

**Note:** This script is a template. You must add your specific API calls in the indicated section to perform the desired operations.
