#!/bin/bash

# Jamf Connect installer package name and where we've placed it with this 
#  metapackage
INSTALLER_FILENAME="/usr/local/jamfconnect/JamfConnect-2.45.1.pkg"

# Jamf Connect launch agent package name and where we've placed it with this 
#  metapackage
LAUNCHAGENT_FILENAME="/usr/local/jamfconnect/JamfConnectLaunchAgent.pkg"

# If we're coming in from Jamf Pro, we should have been passed a target mount
#   point.  Otherwise, assume root directory is target drive.

TARGET_MOUNT=$3
if [ -z "$TARGET_MOUNT" ]; then 
    TARGET_MOUNT="/"
fi 

# Install the JamfConnect software
/usr/sbin/installer -pkg "$INSTALLER_FILENAME" -target "$TARGET_MOUNT"

# Install the JamfConnectLaunchAgent software
/usr/sbin/installer -pkg "$LAUNCHAGENT_FILENAME" -target "$TARGET_MOUNT"

# Remove the JamfConnect.pkg file
rm -f "$INSTALLER_FILENAME"

# Remove the JamfConnectLaunchAgent.pkg file
rm -f "$LAUNCHAGENT_FILENAME"

# Install Rosetta on Apple Silicon
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
    echo "Apple Silicon - Installing Rosetta"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
elif [ "$arch" == "i386" ]; then
    echo "Intel - Skipping Rosetta"
else
    echo "Unknown Architecture"
fi

#####################################################################
# For zero touch enrollment only!  If an enrollment computer is on a slow
# network connection, the user may be presented with a standard macOS login
# window asking for a typed user name and password.  We must kill the 
# loginwindow IF and ONLY IF we're at the Setup Assistant user still.  If we 
# kill the loginwindow process while a user is actually using the computer, they
# will be unceremoniously kicked out of their current session.
#
# Thanks to Richard Pures for additions to this script,
#####################################################################

# For macOS Big Sur - Wait until they've decided that Apple Setup is Done.

while [ ! -f "/var/db/.AppleSetupDone" ]; do
    sleep 2
done

# Look for a user
loggedinuser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
    
# If loginwindow, setup assistant or no user, then we're in an automated device 
#   enrollment environment.
if [[ "$loggedinuser" == "loginwindow" ]] || [[ "$loggedinuser" == "_mbsetupuser" ]] || [[ "$loggedinuser" == "root" ]] || [[ -z "$loggedinuser" ]];
    then
        # Now check to see if Setup Assistant is a running process.  
        # If Setup Assistant is running, we're not at the login screen yet. 
        #   Exit and let macOS finish setup assistant and display the new Jamf 
        #   Connect login screen.
        [[ $( /usr/bin/pgrep "Setup Assistant" ) ]] && exit 0
        
        # Otherwise, kill the login window so it reloads and shows the Jamf 
        #   Connect login window instead.
        /usr/bin/killall -9 loginwindow
    fi

exit 0