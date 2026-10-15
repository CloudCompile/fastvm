#!/bin/bash
# Maximise Discord performance on the machine the container actually has.
#
# Discord is Electron (Chromium + Node). Its throughput is gated by three
# things, none of which are "more CPU threads":
#   1. the resources the container is allowed to use,
#   2. the Chromium flags it launches with,
#   3. the video pipeline (hardware decode when a graphics GPU exists).
#
# This script reports the resource view, detects the GPU, and prints the launch
# flags. It never assumes a GPU: on a plain 2c/8g host it emits the CPU-only
# flag set. It is deliberately conservative — every flag below is safe on a
# small CPU-only box, and anything model-specific (thread count) is derived
# from the measured CPU budget.
#
# Usage:
#   discord-tune.sh flags     # print the Discord launch flags (one line)
#   discord-tune.sh report    # human-readable resource + tuning report
#   discord-tune.sh apply     # report, and persist the flags under /config
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh" 2>/dev/null || true

FLAGS_FILE="${FASTVM_DATA_ROOT:-/config}/.fastvm/discord-flags.txt"

# --- Resources actually available to this container --------------------------

detect_cpus() {
    # An explicit FASTVM_CPU_LIMIT wins; 0 means "no limit" so fall through.
    if [[ -n "${FASTVM_CPU_LIMIT:-}" && "${FASTVM_CPU_LIMIT}" != "0" ]]; then
        echo "${FASTVM_CPU_LIMIT}"
        return
    fi

    # cgroup v2: "<quota> <period>", or "max" when unlimited.
    local q
    q="$(cat /sys/fs/cgroup/cpu.max 2>/dev/null || true)"
    if [[ -n "$q" && "${q%% *}" != "max" && "${q%% *}" != "" ]]; then
        echo $(( (${q%% *} + ${q##* } - 1) / ${q##* } ))
        return
    fi

    # cgroup v1.
    local quota period
    quota="$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || true)"
    period="$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us 2>/dev/null || true)"
    if [[ -n "$quota" && "$quota" != "-1" && -n "$period" && "$period" != "0" ]]; then
        echo $(( (quota + period - 1) / period ))
        return
    fi

    nproc 2>/dev/null || echo 1
}

detect_mem_mb() {
    if [[ -n "${FASTVM_MEMORY_LIMIT:-}" && "${FASTVM_MEMORY_LIMIT}" != "0" ]]; then
        local v="${FASTVM_MEMORY_LIMIT}"
        case "$v" in
            *g|*G) echo $(( ${v%[gG]} * 1024 )); return ;;
            *m|*M) echo "${v%[mM]}"; return ;;
        esac
    fi

    local limit
    limit="$(cat /sys/fs/cgroup/memory.max 2>/dev/null || true)"
    if [[ -z "$limit" || "$limit" == "max" ]]; then
        limit="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || true)"
    fi
    # Fall back to host RAM when there is no limit or the "unlimited" sentinel.
    if [[ -z "$limit" || "$limit" == "max" || "$limit" -ge 9000000000000000000 ]] 2>/dev/null; then
        limit="$(awk '/MemTotal/{print $2*1024}' /proc/meminfo 2>/dev/null || echo 0)"
    fi
    echo $(( limit / 1024 / 1024 ))
}

# "graphics" (has a video engine), "compute" (accelerator with no display
# engine, e.g. AMD Instinct), or "none".
gpu_kind() {
    if [[ -x "${FASTVM_SCRIPTS_DIR:-/fastvm-scripts}/gpu-detect.sh" ]]; then
        FASTVM_DATA_ROOT="${FASTVM_DATA_ROOT:-/config}" \
            "${FASTVM_SCRIPTS_DIR:-/fastvm-scripts}/gpu-detect.sh" detect >/dev/null 2>&1 || true
    fi
    if declare -F gpu_is_compute_only >/dev/null 2>&1 && gpu_is_compute_only; then
        echo compute
        return
    fi
    local node
    for node in /dev/dri/card[0-9]*; do
        if [[ -e "$node" ]]; then
            echo graphics
            return
        fi
    done
    echo none
}

shm_mb() {
    df -Pm /dev/shm 2>/dev/null | awk 'NR==2{print $2}' || echo 0
}

# --- Chromium launch flags ---------------------------------------------------

build_flags() {
    local cpus="$1" kind="$2"
    local flags=""
    # Chromium honours only the last --enable-features, so collect them and emit
    # a single flag.
    local features="WebRtcAllowInputVolumeAdjustment,WebRTC-PiggybackOptimization"

    # Shared memory. Chromium keeps render surfaces in /dev/shm; a small tmpfs
    # makes it fall back to slow paths or crash. Below 512 MB, route shared
    # memory to disk instead of fighting the limit.
    if [[ "$(shm_mb)" -lt 512 ]]; then
        flags+=" --disable-dev-shm-usage"
    fi

    flags+=" --autoplay-policy=no-user-gesture-required"

    # Match Chromium's thread pools to the CPU budget so it neither starves a
    # 2-core box nor over-subscribes a big one. Clamped to a sane range.
    local raster=$(( cpus / 2 ))
    (( raster < 1 )) && raster=1
    (( raster > 4 )) && raster=4
    flags+=" --num-raster-threads=${raster} --renderer-process-limit=${cpus}"

    # Video pipeline.
    if [[ "$kind" == "graphics" ]]; then
        flags+=" --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
        features+=",VaapiVideoDecoder,VaapiVideoEncoder"
    else
        # No graphics engine (headless VPS, or a compute-only accelerator).
        # Skip the GPU stack and keep the GPU process in-process so we do not
        # pay for a separate process that can never do useful work here.
        flags+=" --disable-gpu --in-process-gpu"
        # Grayscale glyph rasterization is cheaper than subpixel (LCD) text for
        # the software compositor, which matters during screen streaming.
        flags+=" --disable-lcd-text"
    fi

    flags+=" --enable-features=${features}"

    echo "${flags# }"
}

print_report() {
    local cpus="$1" mem_mb="$2" kind="$3" flags="$4"
    local gpu_text
    case "$kind" in
        graphics) gpu_text="graphics GPU (VA-API video decode enabled)" ;;
        compute)  gpu_text="compute-only accelerator (no video engine; CPU rasterization)" ;;
        *)        gpu_text="none (CPU rasterization)" ;;
    esac
    echo "FastVM Discord tuning"
    echo "  CPUs available : ${cpus}"
    echo "  Memory         : ${mem_mb} MB"
    echo "  /dev/shm       : $(shm_mb) MB"
    echo "  GPU            : ${gpu_text}"
    echo "  Launch flags   : ${flags}"
}

main() {
    local mode="${1:-report}"
    local cpus mem_mb kind flags
    cpus="$(detect_cpus)"
    mem_mb="$(detect_mem_mb)"
    kind="$(gpu_kind)"
    flags="$(build_flags "$cpus" "$kind")"

    case "$mode" in
        flags) echo "$flags" ;;
        report) print_report "$cpus" "$mem_mb" "$kind" "$flags" ;;
        apply)
            print_report "$cpus" "$mem_mb" "$kind" "$flags"
            ensure_dir "$(dirname "$FLAGS_FILE")"
            echo "$flags" > "$FLAGS_FILE"
            echo "  Written to     : ${FLAGS_FILE}"
            ;;
        *) echo "usage: $0 {flags|report|apply}" >&2; exit 2 ;;
    esac
}

main "$@"
