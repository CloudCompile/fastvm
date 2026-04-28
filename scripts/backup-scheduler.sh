#!/bin/bash
# Run scheduled backups + retention. Invoked by cron inside the container.
# Reads schedule + retention from FASTVM_BACKUP_* env vars.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

if [[ "${FASTVM_BACKUP_ENABLED:-true}" != "true" ]]; then
    log_info "Backups disabled (FASTVM_BACKUP_ENABLED=false). Exiting."
    exit 0
fi

ensure_dir "${FASTVM_BACKUP_DIR}"
ensure_dir "${FASTVM_LOG_DIR}"

LOG="${FASTVM_LOG_DIR}/backup-scheduler.log"
exec >> "$LOG" 2>&1

echo "===== Backup run: $(date -u +'%Y-%m-%d %H:%M:%SZ') ====="
"${SCRIPT_DIR}/backup-create.sh" "scheduled"

# Retention: delete archives older than FASTVM_BACKUP_RETENTION_DAYS.
retention_days="${FASTVM_BACKUP_RETENTION_DAYS:-30}"
if [[ "$retention_days" =~ ^[0-9]+$ ]] && (( retention_days > 0 )); then
    log_info "Pruning archives older than ${retention_days} days"
    find "${FASTVM_BACKUP_DIR}" -maxdepth 1 -type f \
        \( -name 'fastvm-*.tar.*' -o -name 'fastvm-*.tar.*.json' \) \
        -mtime +"${retention_days}" -print -delete || true
fi

echo "===== Backup run finished: $(date -u +'%Y-%m-%d %H:%M:%SZ') ====="
