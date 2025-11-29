#!/bin/bash
#===============================================================================
# Script Name   : full_template.sh
# Description   : [Brief summary of what the script does]
# Author        : HuckHolliday
# Version       : 1.0.0
# Created On    : YYYY-MM-DD
# Last Modified : YYYY-MM-DD
#===============================================================================

#----------------------------------------
# GLOBAL VARIABLES
#----------------------------------------
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"
LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# Example user-defined variables
DEBUG=false
TARGET_DIR="$HOME/Desktop"

#----------------------------------------
# LOGGING FUNCTIONS
#----------------------------------------
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]  $*" | tee -a "$LOG_FILE"
}
log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]  $*" | tee -a "$LOG_FILE" >&2
}
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "$LOG_FILE" >&2
}
log_debug() {
    if [ "$DEBUG" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" | tee -a "$LOG_FILE"
    fi
}

#----------------------------------------
# EXIT HANDLING
#----------------------------------------
cleanup() {
    log_info "Cleaning up before exit..."
    # Add any cleanup commands here (remove temp files, kill processes, etc.)
}
exit_script() {
    local exit_code=$1
    cleanup
    log_info "Exiting with status $exit_code"
    exit "$exit_code"
}
trap 'exit_script 1' INT TERM

#----------------------------------------
# FUNCTIONS
#----------------------------------------
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Options:
  -h, --help       Show this help message
  -v, --version    Show script version
  -d, --debug      Enable debug mode
EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

example_function() {
    log_info "Running example_function..."
    if [ -d "$TARGET_DIR" ]; then
        log_info "Target directory exists: $TARGET_DIR"
    else
        log_warn "Target directory does not exist: $TARGET_DIR"
    fi
}

#----------------------------------------
# SCRIPT MAIN LOGIC
#----------------------------------------
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit_script 0 ;;
            -v|--version) show_version; exit_script 0 ;;
            -d|--debug) DEBUG=true; shift ;;
            *) log_error "Unknown option: $1"; show_help; exit_script 1 ;;
        esac
        shift
    done

    log_info "Starting $SCRIPT_NAME..."
    log_debug "Debug mode enabled"

    # Call your functions here
    example_function

    # Exit successfully
    exit_script 0
}

#----------------------------------------
# SCRIPT ENTRY POINT
#----------------------------------------
main "$@"