#!/usr/bin/env bash
# DecryptString.sh
# Script to prompt for encrypted string, salt, and passphrase, then decrypt.

function DecryptString() {
    local ENCRYPTED="$1"
    local SALT="$2"
    local K="$3"

    # Require openssl
    if ! command -v openssl >/dev/null 2>&1; then
        echo "Error: openssl not found in PATH" >&2
        return 2
    fi

    # Decrypt
    local PLAINTEXT
    if ! PLAINTEXT="$(printf '%s' "$ENCRYPTED" | openssl enc -aes256 -md md5 -a -d -A -S "$SALT" -k "$K" 2>/dev/null)"; then
        echo "Error: decryption failed. Check values." >&2
        return 3
    fi

    printf '%s\n' "$PLAINTEXT"
}

function prompt_and_decrypt() {
    local ENCRYPTED SALT K

    read -r -p "Enter the encrypted string: " ENCRYPTED
    read -r -p "Enter the salt (hex): " SALT
    read -r -p "Enter the passphrase: " K

    if [[ -z "$ENCRYPTED" || -z "$SALT" || -z "$K" ]]; then
        echo "All three values are required." >&2
        return 1
    fi

    local RESULT
    if RESULT="$(DecryptString "$ENCRYPTED" "$SALT" "$K")"; then
        echo
        echo "Decrypted result:"
        echo "  $RESULT"
    else
        echo "Decryption unsuccessful."
        return 1
    fi
}

# Run when invoked directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    prompt_and_decrypt
fi