#!/bin/bash
# FastVM backup-manager: thin host-side CLI that wraps the in-container
# backup scripts. Use this from the project root, e.g.:
#
#     ./backup-manager.sh create [label]
#     ./backup-manager.sh restore <archive>
#     ./backup-manager.sh list
#     ./backup-manager.sh prune

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib-common.sh
source "${SCRIPT_DIR}/scripts/lib-common.sh"
load_fastvm_config

CONTAINER="${FASTVM_NAME:-FastVM}"

usage() {
    cat <<EOF
${FVM_CYAN}FastVM Backup Manager${FVM_NC}

Usage: $(basename "$0") <command> [args]

Commands:
  ${FVM_GREEN}create${FVM_NC} [label]     Create a new snapshot (label defaults to "manual")
  ${FVM_GREEN}restore${FVM_NC} <archive>  Restore a snapshot (creates safety snapshot first)
  ${FVM_GREEN}list${FVM_NC}                List all snapshots
  ${FVM_GREEN}prune${FVM_NC}               Remove snapshots older than \$FASTVM_BACKUP_RETENTION_DAYS

The backup directory is ${FVM_BOLD}${FASTVM_BACKUP_DIR:-./backups}${FVM_NC}.
EOF
}

# Run a script either directly (host-side, against ./data) or inside the
# container if it's running.
run_script() {
    local script="$1"; shift
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
        docker exec -i "$CONTAINER" "/fastvm-scripts/${script}" "$@"
    else
        FASTVM_DATA_ROOT="${SCRIPT_DIR}/data" \
        FASTVM_BACKUP_DIR="${SCRIPT_DIR}/backups" \
        FASTVM_LOG_DIR="${SCRIPT_DIR}/logs" \
            "${SCRIPT_DIR}/scripts/${script}" "$@"
    fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
    create)  run_script backup-create.sh "${1:-manual}" ;;
    restore) [[ $# -eq 1 ]] || { usage; exit 1; }; run_script backup-restore.sh "$1" ;;
    list)    run_script backup-list.sh "${1:-}" ;;
    prune)   run_script backup-scheduler.sh ;;
    -h|--help|help|"") usage ;;
    *) log_error "Unknown command: $cmd"; usage; exit 1 ;;
esac
