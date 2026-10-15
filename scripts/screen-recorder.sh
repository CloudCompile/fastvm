#!/bin/bash
# FastVM screen recorder. Wraps ffmpeg + x11grab + pulse audio capture.
# Designed to be controlled by the dashboard, but works standalone:
#
#     screen-recorder.sh start [name]
#     screen-recorder.sh stop
#     screen-recorder.sh status
#     screen-recorder.sh list
#
# Encoding is hardware-accelerated when a GPU is available. Set
# FASTVM_RECORDING_ENCODER=auto (default) to use the detected GPU, or force one
# of: nvenc, vaapi, qsv, software.

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
encoder_choice="${FASTVM_RECORDING_ENCODER:-auto}"

# Software-encode thread budget. The performance profile leaves a core for the
# desktop on small hosts; honour it so a 2-core box is not oversubscribed while
# it is being recorded. Unset on larger hosts => ffmpeg default.
encode_threads="${FASTVM_PERF_ENCODE_THREADS:-}"
sw_threads=()
if [[ -n "$encode_threads" ]]; then
    sw_threads=(-threads "$encode_threads")
fi

# Hardware encoders emit H.264 only; a container-friendly muxer is required.
vcodec="$(resolve_encoder)"

# A compute-only accelerator (e.g. AMD Instinct) has no usable VA-API device;
# record on the CPU rather than failing.
if [[ "$vcodec" == "h264_vaapi" ]] && gpu_is_compute_only; then
    log_warn "Compute-only GPU: VA-API unavailable; using software (libx264)"
    vcodec="libx264"
fi

if [[ "$vcodec" != "libx264" ]]; then
    case "$format" in
        mp4|mkv) ;;
        *) format="mp4" ;;
    esac
fi

# Build the -c:v argument list (hardware encoders need an explicit input format
# and, for VAAPI, an uploaded hwframe).
video_args=()
case "$vcodec" in
    h264_nvenc)
        video_args=(-c:v h264_nvenc -b:v "$bitrate" -preset p4)
        ;;
    h264_qsv)
        video_args=(-c:v h264_qsv -b:v "$bitrate")
        ;;
    h264_vaapi)
        vaapi_render=""
        vaapi_render="$(jq -r '.render_node // ""' "$(gpu_json_path)" 2>/dev/null || true)"
        [[ -n "$vaapi_render" ]] || vaapi_render="$(ls /dev/dri/renderD* 2>/dev/null | head -n1 || true)"
        if [[ -z "$vaapi_render" ]]; then
            log_warn "VAAPI selected but no render node found; falling back to software"
            vcodec="libx264"
            video_args=(-c:v libx264 -b:v "$bitrate" -preset veryfast "${sw_threads[@]}")
        else
            video_args=(-vaapi_device "$vaapi_render" -vf "format=nv12,hwupload" -c:v h264_vaapi -b:v "$bitrate")
        fi
        ;;
    *)
        vcodec="libx264"
        video_args=(-c:v libx264 -b:v "$bitrate" -preset veryfast "${sw_threads[@]}")
        ;;
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
        "${video_args[@]}" \
        -c:a aac -b:a 160k \
        -movflags +faststart \
        "$outfile" \
        > "${FASTVM_LOG_DIR}/recorder.log" 2>&1 &

    echo $! > "$PIDFILE"
    log_success "Recording started (pid $(cat "$PIDFILE"), encoder ${vcodec})"
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
    echo "encoder=${vcodec} requested=${encoder_choice}"
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
