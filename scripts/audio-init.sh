#!/bin/bash
# Initialize PulseAudio for the FastVM desktop. Runs once at container start
# and again whenever the X session restarts (idempotent).
#
# KasmVNC ships a built-in audio bridge over WebSockets. We just need a
# user-mode PulseAudio instance with a TCP/native socket KasmVNC can read.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

if ! command -v pulseaudio >/dev/null 2>&1; then
    log_warn "PulseAudio not installed; audio support disabled."
    exit 0
fi

PULSE_CONFIG_DIR="${HOME:-/config}/.config/pulse"
ensure_dir "$PULSE_CONFIG_DIR"

# Drop our default.pa if the user doesn't have one yet.
if [[ ! -f "${PULSE_CONFIG_DIR}/default.pa" ]] && [[ -f /etc/fastvm/pulseaudio-default.pa ]]; then
    cp /etc/fastvm/pulseaudio-default.pa "${PULSE_CONFIG_DIR}/default.pa"
fi

# If the existing config is missing the KasmVNC audio bridge socket setup,
# replace it with our default to ensure the native socket is available.
if [[ -f "${PULSE_CONFIG_DIR}/default.pa" ]] && [[ -f /etc/fastvm/pulseaudio-default.pa ]]; then
    if ! grep -q 'module-native-protocol-unix.*socket=/tmp/pulse-socket' "${PULSE_CONFIG_DIR}/default.pa" 2>/dev/null; then
        cp /etc/fastvm/pulseaudio-default.pa "${PULSE_CONFIG_DIR}/default.pa"
    fi
fi

# Kill any stale daemon, then restart.
pulseaudio --kill 2>/dev/null || true
sleep 0.5
# PULSE_RUNTIME_PATH=/defaults matches what the XFCE panel plugin expects.
mkdir -p /defaults && chown abc:abc /defaults 2>/dev/null || true
PULSE_RUNTIME_PATH=/defaults pulseaudio --start --exit-idle-time=-1 --log-target=syslog --daemonize=yes \
    --file="${PULSE_CONFIG_DIR}/default.pa" 2>/dev/null || \
    PULSE_RUNTIME_PATH=/defaults pulseaudio --start --exit-idle-time=-1 --log-target=syslog --daemonize=yes

# Pre-create a virtual sink so apps that bind to a fixed device still work.
pactl load-module module-null-sink \
    sink_name=fastvm_sink sink_properties=device.description=FastVM_Speakers \
    >/dev/null 2>&1 || true
pactl set-default-sink fastvm_sink 2>/dev/null || true

log_success "PulseAudio initialized (sink=fastvm_sink)"
