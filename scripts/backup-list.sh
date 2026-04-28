#!/bin/bash
# List FastVM snapshots. Outputs JSON when --json is passed (used by the
# dashboard), or a human-friendly table otherwise.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

mode="table"
[[ "${1:-}" == "--json" ]] && mode="json"

ensure_dir "${FASTVM_BACKUP_DIR}"

shopt -s nullglob
archives=("${FASTVM_BACKUP_DIR}"/fastvm-*.tar.*)
shopt -u nullglob

# Filter out .json sidecars.
filtered=()
for f in "${archives[@]}"; do
    [[ "$f" == *.json ]] && continue
    filtered+=("$f")
done

if [[ "$mode" == "json" ]]; then
    printf '['
    first=1
    for archive in "${filtered[@]}"; do
        meta="${archive}.json"
        if [[ -f "$meta" ]]; then
            content=$(cat "$meta")
        else
            size=$(stat -c '%s' "$archive" 2>/dev/null || stat -f '%z' "$archive")
            mtime=$(stat -c '%Y' "$archive" 2>/dev/null || stat -f '%m' "$archive")
            content=$(printf '{"archive":"%s","size_bytes":%s,"created_unix":%s,"label":"unknown"}' \
                "$(basename "$archive")" "$size" "$mtime")
        fi
        if [[ $first -eq 0 ]]; then printf ','; fi
        printf '%s' "$content"
        first=0
    done
    printf ']\n'
    exit 0
fi

if [[ ${#filtered[@]} -eq 0 ]]; then
    log_info "No snapshots found in ${FASTVM_BACKUP_DIR}"
    exit 0
fi

printf '%-40s  %-12s  %-20s  %s\n' "ARCHIVE" "SIZE" "CREATED (UTC)" "LABEL"
printf '%-40s  %-12s  %-20s  %s\n' "----------------------------------------" "------------" "--------------------" "------"
for archive in "${filtered[@]}"; do
    name=$(basename "$archive")
    size=$(stat -c '%s' "$archive" 2>/dev/null || stat -f '%z' "$archive")
    mtime=$(stat -c '%Y' "$archive" 2>/dev/null || stat -f '%m' "$archive")
    created=$(date -u -d "@${mtime}" +'%Y-%m-%d %H:%M:%S' 2>/dev/null || date -u -r "${mtime}" +'%Y-%m-%d %H:%M:%S')
    label="-"
    if [[ -f "${archive}.json" ]] && command -v jq >/dev/null 2>&1; then
        label=$(jq -r '.label // "-"' "${archive}.json")
    fi
    printf '%-40s  %-12s  %-20s  %s\n' "$name" "$(human_bytes "$size")" "$created" "$label"
done
