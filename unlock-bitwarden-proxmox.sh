#!/bin/bash
# Load Proxmox API token from Bitwarden
# This script unlocks the Bitwarden vault and retrieves the token
# Usage: eval "$(./unlock-bitwarden-proxmox.sh)"
#
# Requirements:
#   - bw CLI installed: https://bitwarden.com/help/cli/
#   - Item name set to BITWARDEN_ITEM_NAME (defaults to "proxmox ansible")
#
# Works with: fish (and bash/zsh via eval)

set -e

ITEM_NAME="${BITWARDEN_ITEM_NAME:-proxmox ansible}"

# Check if bw CLI is installed
if ! command -v bw &> /dev/null; then
    echo "Error: bw CLI not found. Install from: https://bitwarden.com/help/cli/" >&2
    exit 1
fi

# Unlock the vault if not already unlocked
if [ -z "$BW_SESSION" ]; then
    export BW_SESSION="$(bw unlock --raw)"
fi

# Retrieve the token from Bitwarden by searching for the "API Key" field
TOKEN=$(bw get item "$ITEM_NAME" | jq -r '.fields[] | select(.name=="API Key") | .value' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Could not retrieve 'API Key' field from Bitwarden item '$ITEM_NAME'" >&2
    exit 1
fi

# Output export commands (eval will execute these in the calling shell)
printf "set -gx BW_SESSION %s; set -gx PROXMOX_API_TOKEN %s\n" "$BW_SESSION" "$TOKEN"
