#!/bin/bash

# This script will check the local machine to confirm registration status

# Get current user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

#Check if wpj key is present
WPJKey=$(/usr/bin/security dump "/Users/$loggedInUser/Library/Keychains/login.keychain-db" | grep MS-ORGANIZATION-ACCESS)
if [ ! -z "$WPJKey" ]
    then
    #check if jamfAAD plist exists
    plist="/Users/$loggedInUser/Library/Preferences/com.jamf.management.jamfAAD.plist"
    if [ ! -f "$plist" ]; then
        #plist doesn't exist
        echo "registration is incomplete"
        exit 1
    fi
    #enable recurring gatherAADInfo
    su -l $loggedInUser -c "/usr/bin/defaults write ~/Library/Preferences/com.jamf.management.jamfAAD.plist have_an_Azure_id -bool true"
    #reset timer to force recurring gatherAADInfo
    su -l $loggedInUser -c "/usr/bin/defaults write ~/Library/Preferences/com.jamf.management.jamfAAD.plist last_aad_token_timestamp 0"
    #run recurring gatherAADInfo
    su -l $loggedInUser -c "/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access gatherAADInfo -recurring"
    exit 0
fi
echo "no WPJ key found"
exit 1