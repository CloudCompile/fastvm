#!/bin/bash
# Create a compressed snapshot of the FastVM data directory.
# Designed to run inside the container (where /config is mounted) but works
# anywhere FASTVM_DATA_ROOT points at a real directory.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

LABEL="${1:-manual}"
COMPRESSION="${FASTVM_BACKUP_COMPRESSION:-gzip}"

ensure_dir "${FASTVM_BACKUP_DIR}"
ensure_dir "${FASTVM_LOG_DIR}"

ts="$(date -u +'%Y%m%dT%H%M%SZ')"
safe_label="$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '_')"

case "$COMPRESSION" in
    zstd)  ext="tar.zst"; tar_flag="--zstd" ;;
    xz)    ext="tar.xz";  tar_flag="--xz" ;;
    gzip|*) ext="tar.gz"; tar_flag="--gzip"; COMPRESSION="gzip" ;;
esac

archive="${FASTVM_BACKUP_DIR}/fastvm-${ts}-${safe_label}.${ext}"
metafile="${archive}.json"

log_step "Creating snapshot: $(basename "$archive")"
log_info "Source: ${FASTVM_DATA_ROOT}"
log_info "Compression: ${COMPRESSION}"

if [[ ! -d "${FASTVM_DATA_ROOT}" ]]; then
    log_error "Data directory not found: ${FASTVM_DATA_ROOT}"
    exit 1
fi

# Use ionice/nice when available so we don't stall the desktop.
prefix=()
command -v ionice >/dev/null 2>&1 && prefix+=(ionice -c2 -n7)
command -v nice    >/dev/null 2>&1 && prefix+=(nice -n 19)

start=$(date +%s)
"${prefix[@]}" tar $tar_flag \
    --exclude='./backups' \
    --exclude='./recordings' \
    --exclude='./.cache' \
    --exclude='./Downloads/.cache' \
    -cf "$archive" \
    -C "${FASTVM_DATA_ROOT}" .
end=$(date +%s)

size=$(stat -c '%s' "$archive" 2>/dev/null || stat -f '%z' "$archive")
duration=$(( end - start ))
hash="$(sha256sum "$archive" | awk '{print $1}')"

cat > "$metafile" <<EOF
{
    "archive": "$(basename "$archive")",
    "label": "${safe_label}",
    "timestamp_utc": "${ts}",
    "created_unix": ${end},
    "duration_seconds": ${duration},
    "size_bytes": ${size},
    "size_human": "$(human_bytes "$size")",
    "compression": "${COMPRESSION}",
    "sha256": "${hash}",
    "fastvm_version": "${FASTVM_VERSION:-1.0.0}",
    "source": "${FASTVM_DATA_ROOT}"
}
EOF

log_success "Snapshot created: $(basename "$archive") ($(human_bytes "$size"), ${duration}s)"
echo "$archive"
