# Jamf API Static Group Management Scripts

## Overview
This directory contains two Bash scripts for managing computer membership in Jamf Pro static groups using the Jamf API. These scripts allow you to add or remove a Mac from a specified static group securely and automatically, using encrypted API credentials.

## Scripts

### 1. Jamf API - Static Group - ADD.sh
- **Purpose:** Adds the current Mac to a specified static computer group in Jamf Pro.
- **How it works:**
	- Decrypts Jamf API credentials provided as script parameters.
	- Authenticates to the Jamf API and obtains a bearer token.
	- Retrieves the computer's serial number and constructs the required XML payload.
	- Sends a PUT request to the Jamf API to add the computer to the specified static group.
	- Invalidates the API token and runs `jamf recon` to update inventory.
- **Parameters:**
	- `$4`: Encrypted username and password (`encryptedUSERNAME;encryptedPASSWORD`)
	- `$5`: Encrypted username salt and passphrase (`encryptedSALT;encryptedPASSPHRASE`)
	- `$6`: Encrypted password salt and passphrase (`encryptedSALT;encryptedPASSPHRASE`)
	- `$7`: Static group ID
	- `$8`: Static group name

### 2. Jamf API - Static Group - REMOVE.sh
- **Purpose:** Removes the current Mac from a specified static computer group in Jamf Pro.
- **How it works:**
	- Decrypts Jamf API credentials provided as script parameters.
	- Authenticates to the Jamf API and obtains a bearer token.
	- Retrieves the computer's serial number and constructs the required XML payload.
	- Sends a PUT request to the Jamf API to remove the computer from the specified static group.
	- Invalidates the API token.
- **Parameters:**
	- `$4`: Encrypted username and password (`encryptedUSERNAME;encryptedPASSWORD`)
	- `$5`: Encrypted username salt and passphrase (`encryptedSALT;encryptedPASSPHRASE`)
	- `$6`: Encrypted password salt and passphrase (`encryptedSALT;encryptedPASSPHRASE`)
	- `$7`: Static group ID
	- `$8`: Static group name

## Security
- Credentials are never stored in plain text; they are decrypted at runtime only.
- Jamf API bearer tokens are invalidated at the end of each script.

## Usage
1. **Encrypt your Jamf API credentials** using [EncryptPromt.sh](https://raw.githubusercontent.com/huckholliday/Jamf/refs/heads/main/Scripts/Encryption/EncryptPrompt.sh).
2. **Upload the scripts to Jamf Pro** and attach them to the appropriate policies.
3. **Set script parameters** in the policy as described above.
4. **Run the script as root** (Jamf Pro policies do this by default).

## Requirements
- Jamf Pro server with API access
- Static group(s) created in Jamf Pro
- Encrypted credentials
- macOS with Bash and OpenSSL

## References
- [Jamf Pro API Documentation](https://developer.jamf.com/jamf-pro/docs)
- [EncryptedStrings](https://github.com/brysontyrrell/EncryptedStrings)

---

**Note:** These scripts are templates. Adjust as needed for your organization's environment and static group structure.