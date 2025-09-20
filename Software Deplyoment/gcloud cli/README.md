# Install-gcloud-cli.sh

## Overview
`Install-gcloud-cli.sh` is a Zsh script designed to automate the silent installation of the latest Google Cloud SDK (gcloud CLI) on macOS devices. It is intended for use in Jamf Pro policies or other automated deployment workflows.

## Features
- Detects CPU architecture (Intel or Apple Silicon) and downloads the correct installer
- Accepts a version parameter for the gcloud CLI to install
- Installs the SDK silently for the current user
- Checks if gcloud is already installed and skips installation if present
- Handles permissions for the installed files and configuration
- Cleans up downloaded files after installation

## Usage
1. **Upload the script to Jamf Pro** or use it in your own deployment workflow.
2. **Set the version parameter** in the Jamf Pro policy (Parameter 4), e.g., `449.0.0-darwin`.
3. **The script will:**
   - Check if gcloud is already installed
   - Download and install the correct version for the detected architecture
   - Set permissions and run the installer as the current user

## Requirements
- macOS device (Intel or Apple Silicon)
- Jamf Pro (optional, for automated deployment)
- Internet access to download the Google Cloud SDK

## Notes
- The script must be run as root (as with most Jamf Pro scripts)
- The version parameter must match the format used by Google Cloud SDK releases
- The script is silent and requires no user interaction

## References
- [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs/install)

---

**Note:** Review and test the script in your environment before deploying widely. Adjust paths or logic as needed for your organization's requirements.
