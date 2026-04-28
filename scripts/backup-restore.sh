#!/bin/bash
# Restore a FastVM snapshot. Validates checksum, makes a safety snapshot of
# the current state, then extracts the archive into FASTVM_DATA_ROOT.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") <archive>

Restore the data directory from a FastVM snapshot archive.
Pass either a full path or a filename inside \$FASTVM_BACKUP_DIR.

A safety snapshot of the current data is created automatically with the
label "pre-restore" before the restore happens.
EOF
}

[[ $# -eq 1 ]] || { usage; exit 1; }

archive="$1"
[[ -f "$archive" ]] || archive="${FASTVM_BACKUP_DIR}/${archive}"
[[ -f "$archive" ]] || { log_error "Archive not found: $1"; exit 1; }

metafile="${archive}.json"
if [[ -f "$metafile" ]] && command -v jq >/dev/null 2>&1; then
    expected_hash=$(jq -r '.sha256 // empty' "$metafile")
    if [[ -n "$expected_hash" ]]; then
        log_step "Verifying archive checksum"
        actual_hash="$(sha256sum "$archive" | awk '{print $1}')"
        if [[ "$expected_hash" != "$actual_hash" ]]; then
            log_error "Checksum mismatch! Refusing to restore."
            log_error "expected: $expected_hash"
            log_error "actual:   $actual_hash"
            exit 2
        fi
        log_success "Checksum verified"
    fi
fi

log_step "Creating safety snapshot before restore"
"${SCRIPT_DIR}/backup-create.sh" "pre-restore" >/dev/null || \
    log_warn "Safety snapshot failed; continuing"

log_step "Restoring $(basename "$archive") -> ${FASTVM_DATA_ROOT}"

case "$archive" in
    *.tar.zst) tar_flag="--zstd" ;;
    *.tar.xz)  tar_flag="--xz" ;;
    *.tar.gz)  tar_flag="--gzip" ;;
    *) log_error "Unknown archive format: $archive"; exit 1 ;;
esac

ensure_dir "${FASTVM_DATA_ROOT}"
tar $tar_flag \
    --exclude='./backups' \
    --exclude='./recordings' \
    -xf "$archive" \
    -C "${FASTVM_DATA_ROOT}"

log_success "Restore complete. Restart the container for full effect:"
log_info "    docker restart \"\${FASTVM_NAME:-FastVM}\""
