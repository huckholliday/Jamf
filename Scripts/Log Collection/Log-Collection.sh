#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2021 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script was designed to be used in a Self Service policy to allow the facilitation
# or log collection by the end-user and upload the logs to the device record in Jamf Pro
# as an attachment.
#
# REQUIREMENTS:
#           - Jamf Pro
#           - macOS Clients running version 10.13 or later
#
#
# For more information, visit https://github.com/kc9wwh/logCollection
#
# Written by: Joshua Roskos | Jamf
#
#
# Revision History
# 2020-12-01: Added support for macOS Big Sur
# 2021-02-24: Fixed missing variables
# 2026-08-21: Converted to Jamf Pro API OAuth client credentials (Client ID/Secret) auth
#             and automatic Jamf Pro URL detection
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Parameter 4 - Client ID (plaintext)
# Parameter 5 - Encrypted Client Secret
# Parameter 6 - Client Secret Salt;Client Secret Passphrase
# Parameter 7 - Log file paths to collect (space-separated)
#
# Encrypting the Client Secret can use https://github.com/huckholliday/Jamf/tree/main/Scripts/Encryption
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## User Variables
JAMF_URL="$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')"

clientID="$4"
clientSecretEncrypted="$5"

clientSecretSaltPassInput="$6"
IFS=';' read -ra clientSecretSaltPassBits <<< "$clientSecretSaltPassInput"
clientSecretSalt=${clientSecretSaltPassBits[0]}
clientSecretPassphrase=${clientSecretSaltPassBits[1]}

logFiles="$7"

## System Variables
mySerial=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
currentUser=$( stat -f%Su /dev/console )
compHostName=$( scutil --get LocalHostName )
timeStamp=$( date '+%Y-%m-%d-%H-%M-%S' )

## Jamf API bearer token
bearerToken=""

## Functions
DecryptString() {
    # Usage: DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

getBearerToken() {
    local response
    response=$( curl -s -X POST "$JAMF_URL/api/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "client_id=$clientID" \
        --data-urlencode "client_secret=$clientSecret" \
        --data-urlencode "grant_type=client_credentials" )
    bearerToken=$( echo "$response" | plutil -extract access_token raw - )
}

invalidateToken() {
    local responseCode
    responseCode=$( curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $bearerToken" "$JAMF_URL/api/v1/auth/invalidate-token" )
    if [[ "$responseCode" == "204" ]]; then
        echo "Token successfully invalidated"
    else
        echo "Note: Token invalidation returned HTTP $responseCode"
    fi
    bearerToken=""
}

## Decrypt Client Secret
clientSecret=$( DecryptString "$clientSecretEncrypted" "$clientSecretSalt" "$clientSecretPassphrase" )

getBearerToken
if [[ -z "$bearerToken" ]]; then
    echo "ERROR: Failed to obtain bearer token. Check Client ID/Secret and Jamf Pro URL."
    exit 1
fi

## Log Collection
fileName="${compHostName}-${currentUser}-${timeStamp}.zip"
zip "/private/tmp/${fileName}" $logFiles

## Upload Log File
jamfProID=$( curl -s -H "Authorization: Bearer $bearerToken" "$JAMF_URL/JSSResource/computers/serialnumber/$mySerial/subset/general" | xpath -e "//computer/general/id/text()" )

curl -s -H "Authorization: Bearer $bearerToken" "$JAMF_URL/JSSResource/fileuploads/computers/id/$jamfProID" -F name=@"/private/tmp/${fileName}" -X POST

## Cleanup
invalidateToken
rm "/private/tmp/${fileName}"
exit 0

