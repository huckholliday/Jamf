# SwiftDialog-Progress.sh

## Overview
`SwiftDialog-Progress.sh` is a Bash script template for displaying a progress bar using SwiftDialog during a series of tasks, such as software installation or configuration. It is designed for use in Jamf Pro policies or other macOS automation workflows where user feedback is important.

## Features
- Displays a customizable progress window using SwiftDialog
- Shows progress and status text for each step in a process
- Accepts parameters for customizing the message, icon, overlay icon, and command file
- Includes example steps (prepare, download, install, finish) that can be replaced with your own logic
- Optionally runs `jamf recon` and reports its status in the progress window
- Handles overlay icon logic and basic error checking (macOS version, root, dialog binary)

## Usage
1. **Install SwiftDialog** on the target Mac at `/usr/local/bin/dialog`.
2. **Upload the script to Jamf Pro** or use it in your own deployment workflow.
3. **Parameters:**
   - **$4:** Path to the dialog command file (default: `/var/tmp/dialog.log`)
   - **$5:** Message above the progress bar (default: `Installing …`)
   - **$6:** Main icon (default: App Store icon)
   - **$7:** Overlay icon (optional)
   - **$8:** Run `jamf recon` at the end (0 = no, 1 = yes)
4. **Customize the steps** in the script as needed for your workflow.

## Requirements
- macOS 11 Big Sur or later
- SwiftDialog installed at `/usr/local/bin/dialog`
- Script must be run as root

## Example
The script simulates four steps (preparing, downloading, installing, finishing) and updates the progress bar and text for each. You can replace these with your own functions.

## References
- [SwiftDialog GitHub](https://github.com/bartreardon/swiftDialog)

---

**Note:** This script is a template. Modify the custom script section to fit your deployment or installation process.
