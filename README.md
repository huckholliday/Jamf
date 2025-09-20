# Jamf Scripts & Resources Repository

## Overview
This repository contains a comprehensive collection of scripts, extension attributes, and automation resources for Jamf Pro environments. The content is organized by function and use case, supporting a wide range of Mac management, deployment, compliance, and reporting workflows.

---

## Repository Structure & Contents

### ExtensionAttributes/
- **Custom Extension Attributes** for Jamf inventory and reporting:
	- `iCloudAccount.sh`: Reports iCloud account status.
	- `Nudge - Deferral Count.sh`: Tracks Nudge deferral counts.
	- `RosettaCheck.sh`: Checks for Rosetta installation.

### Scripts/
#### API/
- **Jamf API Automation**
	- `Clear Failed MDM Commands/`: Script and README for clearing failed MDM commands via API.
	- `Template/`: A secure template for Jamf API scripts with README.

#### Device Compliance/
- **Compliance Automation**
	- `DeviceCompliance-SwiftDialog.sh`: Uses SwiftDialog for compliance prompts.

#### Encryption/
- **Encryption Utilities**
	- `DecryptPrompt.sh`, `EncryptPrompt.sh`: Scripts for encrypting/decrypting strings, useful for secure credential handling.

#### Reset/
- **Reset & Troubleshooting**
	- `MSFT-Teams-Reset.sh`: Resets Microsoft Teams for troubleshooting.

#### Slack Webhook Notification/
- **Slack Integration**
	- `SlackNotification-CompletedEnrollment.sh`: Notifies Slack when Zero Touch enrollment completes.
	- `README.md`: Documentation for Slack notification integration.

#### Static Group Management/
- **Static Group Membership Management**
	- `Jamf API - Static Group - ADD.sh`: Adds a Mac to a static group via API.
	- `Jamf API - Static Group - REMOVE.sh`: Removes a Mac from a static group via API.
	- `README.md`: Documentation for static group management scripts.

#### SwiftDialog Progress Window/
- **User Feedback & Progress**
	- `SwiftDialog-Progress.sh`: Shows a progress bar for installations or tasks.
	- `README.md`: Documentation for SwiftDialog progress usage.

#### Uninstallers/
- **Automated Uninstallers**
	- `SwiftDialog-Uninstall-AppStoreApps.sh`, `SwiftDialog-Uninstall-Chrome.sh`, `SwiftDialog-Uninstall-MSFTEdge.sh`: Scripts for uninstalling common applications with user feedback.

### Software Deplyoment/
#### gcloud cli/
- **Google Cloud CLI Deployment**
	- `Install-gcloud-cli.sh`: Installs the Google Cloud SDK (gcloud CLI) for the current user.
	- `README.md`: Documentation for gcloud CLI deployment.

#### Multiple Site Installers/
- **Multi-Tenant Security App Deployment**
	- `Absolute-Consolidation.sh`: Installs Absolute for the correct tenant based on site.
	- `Crowdstrike-GroupTagging.sh`: Tags Crowdstrike Falcon with the correct group for the site.
	- `README.md`: Documentation for multi-site installer logic.

---

## How to Use
- Each folder contains a README.md (where applicable) with details on usage, parameters, and requirements.
- Scripts are designed for use in Jamf Pro policies, with secure credential handling and parameterization for flexibility.
- Extension attributes can be imported into Jamf Pro for enhanced inventory and reporting.

## Security
- Many scripts use encrypted credentials and secure API token handling.
- See individual script documentation for details on required permissions and security best practices.

---

**Note:** This repository is intended for Jamf Pro administrators and Mac management professionals. Review and test scripts in your environment before deploying widely.
