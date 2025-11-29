#!/bin/bash
#===============================================================================
# Script Name   : minimal_template.sh
# Description   : [Brief summary of what this script does]
# Author        : HuckHolliday
# Version       : 1.0.0
# Created On    : YYYY-MM-DD
#===============================================================================

#----------------------------------------
# VARIABLES
#----------------------------------------
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"
LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# Example user variable
TARGET_DIR="$HOME/Desktop"

#----------------------------------------
# LOGGING
#----------------------------------------
log() {
    local level="$1"; shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" | tee -a "$LOG_FILE"
}

#----------------------------------------
# EXIT HANDLING
#----------------------------------------
cleanup() {
    log "INFO" "Cleaning up..."
    # Add any cleanup tasks here
}
exit_script() {
    local code=$1
    cleanup
    log "INFO" "Exiting with code $code"
    exit "$code"
}
trap 'exit_script 1' INT TERM

#----------------------------------------
# FUNCTIONS
#----------------------------------------
example_function() {
    log "INFO" "Running example_function..."
    [ -d "$TARGET_DIR" ] && log "INFO" "Target exists: $TARGET_DIR" || log "WARN" "Missing target: $TARGET_DIR"
}

#----------------------------------------
# MAIN SCRIPT
#----------------------------------------
main() {
    log "INFO" "Starting $SCRIPT_NAME version $VERSION"
    example_function
    exit_script 0
}

#----------------------------------------
# ENTRY POINT
#----------------------------------------
main "$@"