#!/bin/bash

# Script to get the current version of Perforce p4v installed on the computer.
# Created by Logan Holliday 03/05/2024

if [ -f "/Applications/p4v.app/Contents/MacOS/p4v" ] ; then
    version_output=$(/Applications/p4v.app/Contents/MacOS/p4v -p4vc -V)
    version_numbers=$(echo "$version_output" | head -n 2 | grep -oE '[0-9]+\.[0-9]+/[0-9]+' | awk '{print $1}')
else
    version_numbers="Not Installed"
fi

echo "<result>$version_numbers</result>"