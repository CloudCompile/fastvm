#!/bin/bash
# KasmVNC/baseimage-kasmvnc owns PulseAudio initialization. Keep this script
# as a compatibility hook for existing FastVM integrations, but do not start,
# replace, or reconfigure the base image's audio server.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

if [[ "${FASTVM_AUDIO_ENABLED:-true}" != "true" ]]; then
    log_info "Audio is disabled by FASTVM_AUDIO_ENABLED"
    exit 0
fi

log_info "Using PulseAudio/KasmVNC audio provided by the base image"
