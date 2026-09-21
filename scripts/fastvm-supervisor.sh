#!/bin/bash
# Trusted host-side consumer for dashboard system-action requests.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION_FILE="${SCRIPT_DIR}/data/.fastvm/system-action.json"

if [[ ! -f "$ACTION_FILE" ]]; then
    echo "No pending FastVM system action."
    exit 0
fi

action="$(jq -r '.type // empty' "$ACTION_FILE")"
case "$action" in
    recovery|update) echo "$action requested. Run the operator-approved workflow." ;;
    *) echo "Unknown system action: $action" >&2; exit 1 ;;
esac

mv "$ACTION_FILE" "${ACTION_FILE}.handled.$(date +%s)"
echo "Marked $action request as handled."