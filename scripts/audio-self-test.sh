#!/bin/bash
# Verify both PulseAudio playback and capture paths.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

[[ "${FASTVM_AUDIO_ENABLED:-true}" == "true" ]] || {
    log_info "Audio disabled; verification skipped"
    exit 0
}

command -v pactl >/dev/null || { log_error "pactl is not installed"; exit 1; }
command -v paplay >/dev/null || { log_error "paplay is not installed"; exit 1; }
command -v parec >/dev/null || { log_error "parec is not installed"; exit 1; }

pactl info >/dev/null
default_sink=$(pactl get-default-sink)
default_source=$(pactl get-default-source)
[[ -n "$default_sink" && "$default_sink" != "@NONE@" ]]
[[ -n "$default_source" && "$default_source" != "@NONE@" ]]

tmp_dir="${TMPDIR:-/tmp}/fastvm-audio-test"
mkdir -p "$tmp_dir"
trap 'rm -rf "$tmp_dir"' EXIT

# Generate a short silence-free tone, play it, and capture the microphone.
tone="$tmp_dir/tone.wav"
if command -v sox >/dev/null 2>&1; then
    sox -n -r 48000 -c 2 "$tone" synth 0.25 sine 440 >/dev/null 2>&1
else
    ffmpeg -hide_banner -loglevel error -f lavfi -i sine=frequency=440:duration=0.25 \
        -ar 48000 -ac 2 "$tone" -y
fi
paplay --device="$default_sink" "$tone" &
play_pid=$!
timeout 3 parec --device="$default_source" --format=s16le --rate=48000 --channels=1 \
    >"$tmp_dir/capture.raw"
wait "$play_pid"
[[ -s "$tmp_dir/capture.raw" ]] || { log_error "Audio input captured no samples"; exit 1; }

log_success "Audio output and input verified (sink=${default_sink}, source=${default_source})"