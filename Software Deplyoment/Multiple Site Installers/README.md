# Multiple Site Installers: Absolute & Crowdstrike

## Overview
This directory contains two Bash scripts designed for Jamf Pro deployment, enabling automated installation and configuration of security applications (Absolute and Crowdstrike) for multiple sites or tenants. Each script uses the Jamf API to determine the device's assigned site and then installs or configures the application accordingly, ensuring the correct tenant or group tagging is applied.

## Scripts

### 1. Absolute-Consolidation.sh
- **Purpose:** Installs the Absolute agent for the correct tenant based on the device's site assignment in Jamf Pro.
- **How it works:**
  - Uses encrypted Jamf API credentials to securely authenticate.
  - Retrieves the device's site from Jamf Pro using its serial number.
  - Maps the site name to a specific studio/tenant code.
  - Moves the appropriate Absolute installer package for that site into place and runs the installer.
  - Ensures each site installs the Absolute agent configured for its own tenant.
- **Requirements:**
  - A Composer PKG containing all tenant-specific Absolute files, organized by site.
  - Jamf API account with read permissions.
  - Encrypted credentials (**Encrypt Jamf API credentials** using [EncryptPromt.sh](https://github.com/huckholliday/Jamf/Scripts/Encryption/EncryptPromt.sh)).

### 2. Crowdstrike-GroupTagging.sh
- **Purpose:** Tags the Crowdstrike Falcon installation with the correct group for the device's site after the main PKG install.
- **How it works:**
  - Uses encrypted Jamf API credentials to securely authenticate.
  - Retrieves the device's site from Jamf Pro using its serial number.
  - Maps the site name to a specific studio/group code.
  - Sets the Crowdstrike license and applies the correct grouping tag for the site using `falconctl`.
  - Ensures each site is properly tagged in Crowdstrike for reporting and policy assignment.
- **Requirements:**
  - Crowdstrike Falcon must already be installed.
  - Jamf API account with read permissions.
  - Encrypted credentials (**Encrypt Jamf API credentials** using [EncryptPromt.sh](https://github.com/huckholliday/Jamf/Scripts/Encryption/EncryptPromt.sh)).

## Common Features
- Both scripts:
  - Use Jamf Pro API to determine the device's site.
  - Map site names to internal codes for tenant/group assignment.
  - Use encrypted credentials for secure API access.
  - Are intended to be run as post-install scripts in Jamf Pro policies.

## Usage
1. **Encrypt Jamf API credentials** using [EncryptPromt.sh](https://github.com/huckholliday/Jamf/Scripts/Encryption/EncryptPromt.sh).
2. **Upload the scripts to Jamf Pro** and attach them to the appropriate policies:
   - For Absolute: Attach to the policy that installs the Absolute PKG.
   - For Crowdstrike: Attach to run after the Crowdstrike PKG install.
3. **Set script parameters** in the policy:
   - **Parameter 4:** `encryptedUSERNAME;encryptedPASSWORD`
   - **Parameter 5:** (for Crowdstrike) Crowdstrike license key
   - **Parameter 5:** (for Absolute) Debug mode (optional)
4. **Customize site-to-code mapping** in the scripts as needed for your environment.

## Security
- Credentials are never stored in plain text; they are decrypted at runtime only.
- Jamf API bearer tokens are invalidated at the end of each script.

## References
- [Jamf Pro API Documentation](https://developer.jamf.com/jamf-pro/docs)
- [EncryptedStrings](https://github.com/brysontyrrell/EncryptedStrings)

---

**Note:** These scripts are templates. Adjust the site mapping and PKG structure as needed for your organization's environment and application requirements.
