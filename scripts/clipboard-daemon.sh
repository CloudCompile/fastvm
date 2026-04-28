#!/bin/bash
# Watch the X11 clipboard and write changes to a file the dashboard can
# read/write. Polls every 200ms to keep CPU usage minimal.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

if ! command -v xclip >/dev/null 2>&1; then
    log_warn "xclip not installed; clipboard sync disabled."
    exit 0
fi

ensure_dir "${FASTVM_DATA_ROOT}/.fastvm"
SHARED="${FASTVM_DATA_ROOT}/.fastvm/clipboard.txt"
touch "$SHARED"

# 10 MB cap so a runaway paste can't OOM the container.
MAX_BYTES=$((10 * 1024 * 1024))
last_x=""
last_shared=""

read_x_clip() {
    xclip -selection clipboard -o 2>/dev/null || true
}
write_x_clip() {
    printf '%s' "$1" | xclip -selection clipboard -i 2>/dev/null || true
}

trap 'log_info "Clipboard daemon stopping"; exit 0' TERM INT
log_success "Clipboard daemon started (shared file: ${SHARED})"

while true; do
    cur_x=$(read_x_clip)
    cur_shared=$(<"$SHARED")

    # X clipboard changed -> push to shared file
    if [[ "$cur_x" != "$last_x" ]] && [[ "$cur_x" != "$cur_shared" ]]; then
        if (( ${#cur_x} <= MAX_BYTES )); then
            printf '%s' "$cur_x" > "$SHARED"
            last_shared="$cur_x"
        fi
        last_x="$cur_x"
    fi

    # Shared file changed (browser pushed) -> sync into X clipboard
    if [[ "$cur_shared" != "$last_shared" ]] && [[ "$cur_shared" != "$cur_x" ]]; then
        write_x_clip "$cur_shared"
        last_x="$cur_shared"
        last_shared="$cur_shared"
    fi

    sleep 0.2
done
