#!/bin/bash
# FastVM screen recorder. Wraps ffmpeg + x11grab + pulse audio capture.
# Designed to be controlled by the dashboard, but works standalone:
#
#     screen-recorder.sh start [name]
#     screen-recorder.sh stop
#     screen-recorder.sh status
#     screen-recorder.sh list

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

PIDFILE="${FASTVM_LOG_DIR}/recorder.pid"
NAMEFILE="${FASTVM_LOG_DIR}/recorder.name"
ensure_dir "${FASTVM_RECORDINGS_DIR}"
ensure_dir "${FASTVM_LOG_DIR}"

format="${FASTVM_RECORDING_FORMAT:-mp4}"
bitrate="${FASTVM_RECORDING_BITRATE:-5M}"
fps="${FASTVM_RECORDING_FRAMERATE:-30}"
codec="${FASTVM_RECORDING_CODEC:-h264}"

case "$codec" in
    hevc)  vcodec="libx265" ;;
    vp9)   vcodec="libvpx-vp9"; format="webm" ;;
    h264|*) vcodec="libx264" ;;
esac

start_recording() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        log_error "Already recording (pid $(cat "$PIDFILE"))"
        exit 1
    fi
    command -v ffmpeg >/dev/null 2>&1 || { log_error "ffmpeg not installed"; exit 1; }

    local label="${1:-recording}"
    local safe_label
    safe_label="$(printf '%s' "$label" | tr -c 'A-Za-z0-9._-' '_')"
    local ts; ts="$(date -u +'%Y%m%dT%H%M%SZ')"
    local outfile="${FASTVM_RECORDINGS_DIR}/${ts}-${safe_label}.${format}"
    echo "$outfile" > "$NAMEFILE"

    local display="${DISPLAY:-:1}"
    local resolution
    resolution=$(xdpyinfo -display "$display" 2>/dev/null | awk '/dimensions/{print $2; exit}')
    [[ -z "$resolution" ]] && resolution="1920x1080"

    log_step "Starting recording -> $(basename "$outfile") (${resolution} @ ${fps}fps, ${vcodec})"

    nohup ffmpeg -y \
        -f x11grab -framerate "$fps" -video_size "$resolution" -i "$display" \
        -f pulse -i default \
        -c:v "$vcodec" -b:v "$bitrate" -preset veryfast \
        -c:a aac -b:a 160k \
        -movflags +faststart \
        "$outfile" \
        > "${FASTVM_LOG_DIR}/recorder.log" 2>&1 &

    echo $! > "$PIDFILE"
    log_success "Recording started (pid $(cat "$PIDFILE"))"
}

stop_recording() {
    [[ -f "$PIDFILE" ]] || { log_warn "No active recording"; return 0; }
    local pid; pid="$(cat "$PIDFILE")"
    if kill -0 "$pid" 2>/dev/null; then
        # Send 'q' so ffmpeg writes the moov atom cleanly.
        kill -INT "$pid" 2>/dev/null || true
        for _ in {1..10}; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.5
        done
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"
    fi
    rm -f "$PIDFILE"
    local outfile; outfile="$(cat "$NAMEFILE" 2>/dev/null || echo "")"
    log_success "Recording stopped${outfile:+: $outfile}"
}

status_recording() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "recording"
        cat "$NAMEFILE" 2>/dev/null || true
    else
        echo "idle"
    fi
}

list_recordings() {
    shopt -s nullglob
    for f in "${FASTVM_RECORDINGS_DIR}"/*.{mp4,mkv,webm}; do
        size=$(stat -c '%s' "$f" 2>/dev/null || stat -f '%z' "$f")
        printf '%s\t%s\t%s\n' "$(basename "$f")" "$size" "$(human_bytes "$size")"
    done
}

cmd="${1:-status}"; shift || true
case "$cmd" in
    start)  start_recording "${1:-recording}" ;;
    stop)   stop_recording ;;
    status) status_recording ;;
    list)   list_recordings ;;
    *) log_error "Unknown command: $cmd"; exit 1 ;;
esac
