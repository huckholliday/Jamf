#!/bin/bash

# SwiftDialog Uninstaller for App Store Apps
# This script uses SwiftDialog to present a list of installed App Store apps, allowing the user to select one for uninstallation.

dialog_command_file="${4:-/var/tmp/dialog.log}"   # $4: Command file path
title="${5:-Uninstall App Store App}"               # $5: Title of the dialog
message="${6:-Select an App Store app to uninstall …}"                      # $6: Message above progress bar
icon="${7:-/System/Applications/App Store.app/Contents/Resources/AppIcon.icns}" # $7: Main icon
overlayicon="${8:-}"                              # $8: Overlay icon (optional)
jamf_recon="${9:-0}"                        # $9: Whether to run jamf recon (1) or not (0)
dialogBinary="/usr/local/bin/dialog"
CURRENT_USER=$(stat -f "%Su" /dev/console)

get_applist() {
    find /Applications -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | \
    sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##' | \
    paste -sd "," -
}

startDialog(){
    "$dialogBinary" \
        --title "$title" \
        --icon "$icon" \
        --overlayicon "$overlayicon" \
        --message "$message" \
        --selecttitle "Installed Apps:",required \
        --selectvalues "$(get_applist)" \
        --small \
        --button1 "Enter" \
        --button2 "Cancel" \
        --position center \
        --moveable \
        --commandfile "$dialog_command_file" \
        | grep "SelectedOption" | awk -F " : " '{print $NF}' &
}

appSelect=$(startDialog)
appSelectClean=$(echo "$appSelect" | tr -d '\n' | sed 's/^"\(.*\)"$/\1/' | sed 's/\.app$//')

if [[ -z "$appSelect" ]]; then
    echo "No app selected. Exiting."
    exit 1
else
    echo "$appSelectClean"
fi

app_path="/Applications/${appSelectClean}.app"
found_something=0

# Remove the app if it exists
if [[ -d "$app_path" ]]; then
    rm -rf "$app_path"
    echo "Removed application: $app_path"
    found_something=1
else
    echo "Application not found: $app_path"
fi

# Remove related plist files
plist_files=$(find /Library/Preferences ~/Library/Preferences -name "*${appSelectClean}*.plist" 2>/dev/null)
if [[ -n "$plist_files" ]]; then
    echo "$plist_files" | xargs rm -f
    echo "Removed plist files:"
    echo "$plist_files"
    found_something=1
else
    echo "No plist files found for: $appSelectClean"
fi

# Remove related cache files
cache_files=$(find /Library/Caches ~/Library/Caches -name "*${appSelectClean}*" 2>/dev/null)
if [[ -n "$cache_files" ]]; then
    echo "$cache_files" | xargs rm -rf
    echo "Removed cache files:"
    echo "$cache_files"
    found_something=1
else
    echo "No cache files found for: $appSelectClean"
fi

if [[ "$found_something" -eq 0 ]]; then
    echo "No app, plist, or cache files found for: $appSelectClean"
fi

exit 0