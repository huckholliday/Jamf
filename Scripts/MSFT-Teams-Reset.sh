#!/bin/zsh --no-rcs

####################################################################################################
#
# Script for reseting Microsoft Teams
#
####################################################################################################
#
# HISTORY
#
#  - Version 1.0, September 6, 2025 by Logan Holliday
#
#
####################################################################################################

# Verify we are running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root **EXITING**"
  exit 1
fi

# Get the currently logged in user
CURRENT_USER=$(stat -f "%Su" /dev/console)
echo "Current logged in user: $CURRENT_USER"

# Stop Microsoft Teams processes
if pgrep -f "Microsoft Teams" > /dev/null; then
  pkill -f "Microsoft Teams"
fi
echo "Stopped Microsoft Teams processes."

# Remove Microsoft Teams application (macOS example)
if [ -d "/Applications/Microsoft Teams.app" ]; then
  rm -rf "/Applications/Microsoft Teams.app"
  echo "Removed Microsoft Teams application from Applications folder."
else
  echo "Microsoft Teams application not found in Applications folder."
fi

# Remove Teams cache and data (macOS example)
if [ -d "/Users/${CURRENT_USER}/Library/Application Support/Microsoft/Teams" ]; then
  rm -rf /Users/${CURRENT_USER}/Library/Application\ Support/Microsoft/Teams
  echo "Removed Teams data from Application Support."
else
  echo "Teams data not found in Application Support."
fi

if [ -d "/Users/${CURRENT_USER}/Library/Caches/com.microsoft.teams" ]; then
  rm -rf /Users/${CURRENT_USER}/Library/Caches/com.microsoft.teams
  echo "Removed Teams cache."
else
  echo "Teams cache not found."
fi

if [ -f "/Users/${CURRENT_USER}/Library/Preferences/com.microsoft.teams2.helper.plist" ]; then
  rm -rf /Users/${CURRENT_USER}/Library/Preferences/com.microsoft.teams2.helper.plist
  echo "Removed Teams preferences plist."
else
  echo "Teams preferences plist not found."
fi

if [ -d "/Users/${CURRENT_USER}/Library/Logs/Microsoft Teams" ]; then
  rm -rf /Users/${CURRENT_USER}/Library/Logs/Microsoft\ Teams
  echo "Removed Teams logs."
else
  echo "Teams logs not found."
fi
echo "Cleared Microsoft Teams cache and data."

# Reinstall Teams from Jamf policy
jamf policy -event teams

# Relaunch Teams
if [ -d "/Applications/Microsoft Teams.app" ]; then
  open -a "Microsoft Teams"
  echo "Relaunched Microsoft Teams."
else
  echo "Microsoft Teams application not found in Applications folder. Cannot relaunch."
fi

# Confirm Teams is running
if pgrep -f "Microsoft Teams" > /dev/null; then
  echo "Microsoft Teams is running successfully."
else
  echo "ERROR: Microsoft Teams failed to launch."
fi

exit 0