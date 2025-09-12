#!/bin/bash

# Remove Microsoft Edge Script
# This script will remove Microsoft Edge and its associated files from a macOS system and show progress using SwiftDialog.

# Jamf Script Parameters
dialog_command_file="${4:-/var/tmp/dialog.log}"   # $4: Command file path
message="${5:-Installing …}"                      # $5: Message above progress bar
icon="${6:-/System/Applications/App Store.app/Contents/Resources/AppIcon.icns}" # $6: Main icon
overlayicon="${7:-}"                              # $7: Overlay icon (optional)
jamf_recon="${8:-0}"                              # $8: Run Jamf recon (0/1)

dialogBinary="/usr/local/bin/dialog"

# Function to send commands to SwiftDialog
dialogUpdate() {
    local dcommand="$1"
    if [[ -n $dialog_command_file ]]; then
        echo "$dcommand" >> "$dialog_command_file"
        echo "Dialog: $dcommand"
    fi
}

# Sanity checks
if [[ $(sw_vers -buildVersion) < "20A" ]]; then
    echo "This script requires at least macOS 11 Big Sur."
    exit 98
fi

if [[ $(id -u) -ne 0 ]]; then
    echo "This script should be run as root"
    exit 97
fi

if [[ ! -x $dialogBinary ]]; then
    echo "Cannot find dialog at $dialogBinary"
    exit 95
fi

# Overlay icon logic
if [[ -z $overlayicon ]]; then
    if [[ -f "/Library/Application Support/Dialog/Dialog.png" ]]; then
        overlayicon="/Library/Application Support/Dialog/Dialog.png"
    else
        overlayicon=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path 2>/dev/null)
    fi
fi

# Start SwiftDialog
"$dialogBinary" \
    --title none \
    --icon "$icon" \
    --overlayicon "$overlayicon" \
    --message "$message" \
    --mini \
    --progress 100 \
    --position topright \
    --moveable \
    --commandfile "$dialog_command_file" &

sleep 0.5

# --- Begin Custom Script Section ---
# Example: Simulate install steps with progress
# Define your custom functions
applications() {
    # Paths to Edge app bundles
    EDGE_APPS=(
        "/Applications/Microsoft Edge.app"
        "/Applications/Microsoft Edge Beta.app"
        "/Applications/Microsoft Edge Dev.app"
        "/Applications/Microsoft Edge Canary.app"
        "/Users/$CURRENT_USER/Applications/Microsoft Edge.app"
    )

    # Remove Edge applications
    for APP in "${EDGE_APPS[@]}"; do
        if [ -d "$APP" ]; then
            echo "Removing: $APP"
            rm -rf "$APP"
        fi
    done
    sleep 1

}

userDirectories() {
    USER_DIRS=(
        "/Users/$CURRENT_USER/Library/Application Support/Microsoft Edge"
        "/Users/$CURRENT_USER/Library/Application Support/Microsoft/Edge"
        "/Users/$CURRENT_USER/Library/Caches/Microsoft Edge"
        "/Users/$CURRENT_USER/Library/Caches/Microsoft/Edge"
        "/Users/$CURRENT_USER/Library/Preferences/com.microsoft.Edge.plist"
        "/Users/$CURRENT_USER/Library/Saved Application State/com.microsoft.edgemac.savedState"
        "/Users/$CURRENT_USER/Library/Logs/Microsoft Edge"
    )

    for DIR in "${USER_DIRS[@]}"; do
        if [ -e "$DIR" ]; then
            echo "Removing: $DIR"
            rm -rf "$DIR"
        fi
    done
    sleep 1
}

systemDirectories() {
    SYSTEM_DIRS=(
        "/Library/Preferences/com.microsoft.Edge.plist"
        "/Library/LaunchAgents/com.microsoft.EdgeUpdater.plist"
        "/Library/LaunchDaemons/com.microsoft.EdgeUpdater.Update.plist"
        "/Library/Microsoft/EdgeUpdater"
    )

    for DIR in "${SYSTEM_DIRS[@]}"; do
        if [ -e "$DIR" ]; then
            echo "Removing: $DIR"
            rm -rf "$DIR"
        fi
    done
    sleep 1
}

finish() {
    # Jamf recon if requested
    if [[ "$jamf_recon" == "1" ]]; then
        dialogUpdate "progress: 0"
        dialogUpdate "progresstext: Reporting …"
        jamf recon
    fi
    sleep 1
}

# Steps and corresponding functions
steps=("Removing Application..." "Removing User Directories..." "Removing System Directories..." "Cleaning Up...")
functions=(applications userDirectories systemDirectories finish)

for i in "${!steps[@]}"; do
    increment=$((100 / ${#steps[@]}))
    dialogUpdate "progress: $(( (i+1) * increment ))"
    dialogUpdate "progresstext: ${steps[$i]}"
    ${functions[$i]}
done
# --- End Custom Script Section ---

# Close SwiftDialog
dialogUpdate "progress: complete"
dialogUpdate "progresstext: Done"
sleep 0.5
dialogUpdate "quit:"
sleep 0.5
killall "Dialog" 2>/dev/null

exit 0