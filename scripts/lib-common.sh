#!/bin/bash
# FastVM common shell library: logging, config loading, helpers.
# Source this from other scripts: source "$(dirname "$0")/lib-common.sh"

# Colors (auto-disable if not a TTY).
if [[ -t 1 ]]; then
    FVM_RED='\033[0;31m'
    FVM_GREEN='\033[0;32m'
    FVM_YELLOW='\033[1;33m'
    FVM_BLUE='\033[0;34m'
    FVM_CYAN='\033[0;36m'
    FVM_MAGENTA='\033[0;35m'
    FVM_BOLD='\033[1m'
    FVM_NC='\033[0m'
else
    FVM_RED='' FVM_GREEN='' FVM_YELLOW='' FVM_BLUE='' FVM_CYAN='' FVM_MAGENTA='' FVM_BOLD='' FVM_NC=''
fi

log_info()    { echo -e "${FVM_BLUE}[INFO]${FVM_NC} $*"; }
log_success() { echo -e "${FVM_GREEN}[ OK ]${FVM_NC} $*"; }
log_warn()    { echo -e "${FVM_YELLOW}[WARN]${FVM_NC} $*"; }
log_error()   { echo -e "${FVM_RED}[FAIL]${FVM_NC} $*" >&2; }
log_step()    { echo -e "${FVM_CYAN}[STEP]${FVM_NC} ${FVM_BOLD}$*${FVM_NC}"; }

# FastVM data roots (overridable for in-container vs host execution).
: "${FASTVM_DATA_ROOT:=/config}"
: "${FASTVM_BACKUP_DIR:=${FASTVM_DATA_ROOT}/backups}"
: "${FASTVM_RECORDINGS_DIR:=${FASTVM_DATA_ROOT}/recordings}"
: "${FASTVM_LOG_DIR:=/var/log/fastvm}"

ensure_dir() {
    local d="$1"
    [[ -d "$d" ]] || mkdir -p "$d"
}

# Load config.env if it exists in the script tree (host invocation).
load_fastvm_config() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
    local cfg="${script_dir}/../config.env"
    if [[ -f "$cfg" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$cfg"
        set +a
    fi
}

# Human-readable bytes.
human_bytes() {
    local bytes=${1:-0}
    awk -v b="$bytes" 'BEGIN{
        split("B KB MB GB TB PB", u);
        i=1; while (b>=1024 && i<6) { b/=1024; i++ }
        printf("%.2f %s", b, u[i])
    }'
}
