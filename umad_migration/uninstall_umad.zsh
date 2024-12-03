#!/bin/bash
 
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
 
UserID=$(id -u $loggedInUser)
launchctl bootout gui/$UserID /Library/LaunchAgents/com.erikng.umad.plist
launchctl bootout gui/$UserID /Library/LaunchDaemons/com.erikng.umad.check_dep_record.plist
launchctl bootout gui/$UserID /Library/LaunchDaemons/com.erikng.umad.trigger_nag.plist
 
launchctl bootout system /Library/LaunchAgents/com.erikng.umad.plist
launchctl bootout system /Library/LaunchDaemons/com.erikng.umad.check_dep_record.plist
launchctl bootout system /Library/LaunchDaemons/com.erikng.umad.trigger_nag.plist
 
launchctl unload /Library/LaunchAgents/com.erikng.umad.plist
launchctl unload /Library/LaunchDaemons/com.erikng.umad.check_dep_record.plist
launchctl unload /Library/LaunchDaemons/com.erikng.umad.trigger_nag.plist
 
sudo rm -rf /Library/LaunchAgents/com.erikng.umad.plist
sudo rm -rf /Library/LaunchDaemons/com.erikng.umad.check_dep_record.plist
sudo rm -rf /Library/LaunchDaemons/com.erikng.umad.trigger_nag.plist
rm -rf /Library/umad/*
rm -rf /Library/umad/
 

exit 0
