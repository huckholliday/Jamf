#!/bin/bash
#===============================================================================
# Script Name   : SwiftDialog-Template.sh
# Description   : macOS script template with logging, cleanup, and SwiftDialog UI
# Author        : [Your Name]
# Version       : 1.0.0
# Created On    : YYYY-MM-DD
#===============================================================================

#----------------------------------------
# GLOBAL VARIABLES
#----------------------------------------
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"
LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"
DEBUG=false

# SwiftDialog
DIALOG_BIN="/usr/local/bin/dialog"  # Adjust if installed elsewhere
DIALOG_CMD_FILE=$(mktemp /var/tmp/${SCRIPT_NAME%.sh}.XXXXXX)
TITLE="Script Progress"
ICON="SF=hammer.fill color1=blue"
PROGRESS_TOTAL=5

#----------------------------------------
# LOGGING FUNCTIONS
#----------------------------------------
log_info()  { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]  $*" | tee -a "$LOG_FILE"; }
log_warn()  { echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN]  $*" | tee -a "$LOG_FILE" >&2; }
log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "$LOG_FILE" >&2; }
log_debug() { [ "$DEBUG" = true ] && echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" | tee -a "$LOG_FILE"; }

#----------------------------------------
# CLEANUP & EXIT HANDLING
#----------------------------------------
cleanup() {
    log_info "Cleaning up..."
    [ -f "$DIALOG_CMD_FILE" ] && rm -f "$DIALOG_CMD_FILE"
}
exit_script() {
    local code=$1
    cleanup
    log_info "Exiting with status $code"
    exit "$code"
}
trap 'exit_script 1' INT TERM

#----------------------------------------
# SWIFTDIALOG FUNCTIONS
#----------------------------------------
log_dialog() {
    echo "$*" >> "$DIALOG_CMD_FILE"
}

start_progress() {
    "$DIALOG_BIN" \
        --title "$TITLE" \
        --icon "$ICON" \
        --progress --progresstext "Starting..." \
        --commandfile "$DIALOG_CMD_FILE" &
    sleep 1
}

update_progress() {
    local step="$1"
    local text="$2"
    log_dialog "progress: $step"
    log_dialog "progresstext: $text"
}

stop_progress() {
    log_dialog "quit:"
    sleep 1
}

prompt_user() {
    "$DIALOG_BIN" \
        --title "$TITLE" \
        --message "Do you want to continue?" \
        --button1text "Yes" \
        --button2text "No"
    return $?  # 0 if Yes, 2 if No
}

#----------------------------------------
# SCRIPT FUNCTIONS
#----------------------------------------
example_task() {
    log_info "Running example task..."
    sleep 1
    log_info "Task complete."
}

#----------------------------------------
# MAIN SCRIPT
#----------------------------------------
main() {
    # Argument parsing
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "Usage: $SCRIPT_NAME [-d|--debug]"
                exit_script 0 ;;
            -v|--version)
                echo "$SCRIPT_NAME version $VERSION"
                exit_script 0 ;;
            -d|--debug)
                DEBUG=true; shift ;;
            *)
                log_error "Unknown option: $1"
                exit_script 1 ;;
        esac
        shift
    done

    log_info "Starting $SCRIPT_NAME..."
    log_debug "Debug mode enabled"

    # Confirm with user
    if ! prompt_user; then
        log_warn "User canceled operation."
        exit_script 1
    fi

    # Progress workflow
    start_progress
    for ((i=1; i<=PROGRESS_TOTAL; i++)); do
        update_progress "$i" "Step $i of $PROGRESS_TOTAL"
        example_task
    done
    stop_progress

    exit_script 0
}

#----------------------------------------
# ENTRY POINT
#----------------------------------------
main "$@"