#!/bin/sh
#
# reports status of rosetta install

RESULT=$(/usr/bin/pgrep -q oahd && echo Yes || echo No)

echo "<result>$RESULT</result>"