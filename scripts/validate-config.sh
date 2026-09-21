#!/bin/bash
# Validate FastVM configuration before installation or deployment.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"
load_fastvm_config

fail=0
valid_de='^(XFCE4|KDE|GNOME|Cinnamon|LXQT|I3|Budgie|fastvm-os|FASTVM-OS)$'
valid_preset='^(none|minimal|gaming|development|office|content-creation|hidencloud-free-vps)$'
valid_bool='^(true|false)$'
valid_schedule='^(disabled|daily|weekly|hourly)$'
valid_compression='^(gzip|zstd|xz)$'
valid_format='^(mp4|webm|mkv)$'
valid_codec='^(h264|hevc|vp9)$'

check_regex() {
    local name="$1" value="$2" pattern="$3"
    if [[ ! "$value" =~ $pattern ]]; then
        log_error "${name} has invalid value: ${value}"
        fail=1
    fi
}
check_range() {
    local name="$1" value="$2" min="$3" max="$4"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value < min || value > max )); then
        log_error "${name} must be an integer between ${min} and ${max}: ${value}"
        fail=1
    fi
}

check_regex FASTVM_DE "${FASTVM_DE:-XFCE4}" "$valid_de"
check_regex FASTVM_PRESET "${FASTVM_PRESET:-none}" "$valid_preset"
check_regex FASTVM_RECORDING_FORMAT "${FASTVM_RECORDING_FORMAT:-mp4}" "$valid_format"
check_regex FASTVM_RECORDING_CODEC "${FASTVM_RECORDING_CODEC:-h264}" "$valid_codec"
check_regex FASTVM_BACKUP_COMPRESSION "${FASTVM_BACKUP_COMPRESSION:-gzip}" "$valid_compression"
check_regex FASTVM_BACKUP_AUTO_SCHEDULE "${FASTVM_BACKUP_AUTO_SCHEDULE:-daily}" "$valid_schedule"
for name in FASTVM_AUDIO_ENABLED FASTVM_CLIPBOARD_ENABLED FASTVM_RECORDING_ENABLED FASTVM_BACKUP_ENABLED FASTVM_AUTOSCALE_ENABLED FASTVM_HEALTHCHECK_DISABLE FASTVM_ALLOW_QUERY_TOKEN FASTVM_PRIVILEGED; do
    check_regex "$name" "${!name:-false}" "$valid_bool"
done
check_range FASTVM_PORT "${FASTVM_PORT:-3000}" 1 65535
check_range FASTVM_DASHBOARD_HOST_PORT "${FASTVM_DASHBOARD_HOST_PORT:-3001}" 1 65535
check_range FASTVM_DASHBOARD_PORT "${FASTVM_DASHBOARD_PORT:-8099}" 1 65535
check_range FASTVM_RECORDING_FRAMERATE "${FASTVM_RECORDING_FRAMERATE:-30}" 1 240
check_range FASTVM_BACKUP_RETENTION_DAYS "${FASTVM_BACKUP_RETENTION_DAYS:-30}" 0 36500

if (( fail )); then exit 1; fi
log_success "FastVM configuration is valid"
