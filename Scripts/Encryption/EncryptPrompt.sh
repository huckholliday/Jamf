# --- Prompt user and output encrypted, salt, and passphrase ---

# Safer GenerateEncryptedString that returns all three values
# Usage: read ENC SALT K < <(GenerateEncryptedString "string")
function GenerateEncryptedString() {
    local STRING="${1}"

    # Require non-empty input
    if [[ -z "$STRING" ]]; then
        echo "Error: empty string" >&2
        return 1
    fi

    # Require openssl
    if ! command -v openssl >/dev/null 2>&1; then
        echo "Error: openssl not found in PATH" >&2
        return 2
    fi

    # Generate salt and passphrase
    local SALT
    SALT="$(openssl rand -hex 8)" || return 3
    local K
    K="$(openssl rand -hex 12)" || return 4

    # Encrypt
    local ENCRYPTED
    ENCRYPTED="$(printf '%s' "$STRING" | openssl enc -aes256 -md md5 -a -A -S "$SALT" -k "$K")" || return 5

    # Emit values as a single line suitable for process substitution
    printf '%s %s %s\n' "$ENCRYPTED" "$SALT" "$K"
}

# Interactive flow
function prompt_and_encrypt() {
    local INPUT
    # -s hides typing in case you are pasting a secret
    read -r -s -p "Enter the string to encrypt: " INPUT
    echo

    # Confirm non-empty
    if [[ -z "$INPUT" ]]; then
        echo "No input provided. Exiting."
        return 1
    fi

    local ENCRYPTED SALT K
    if read -r ENCRYPTED SALT K < <(GenerateEncryptedString "$INPUT"); then
        echo
        echo "Encrypted:"
        echo "  $ENCRYPTED"
        echo "Salt:"
        echo "  $SALT"
        echo "Passphrase:"
        echo "  $K"
        echo
        echo "Tip: store Salt and Passphrase in your script and pass only the Encrypted value as a parameter."
    else
        echo "Failed to generate encrypted values." >&2
        return 1
    fi
}

# Run when invoked directly, skip when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    prompt_and_encrypt
fi