#!/bin/bash
# FastVM performance profile.
#
# FastVM is frequently run on machines far smaller than the image assumes: a
# 2 vCPU / 8 GB Codespace with no GPU. On those hosts the desktop is rasterized
# by Mesa's software driver (llvmpipe) and the default settings leave a lot on
# the table:
#
#   * llvmpipe parallelises across *all* host CPUs unless told otherwise, so it
#     oversubscribes a 2-core box and thrashes;
#   * a compositing window manager burns CPU re-compositing every frame that is
#     about to be streamed anyway;
#   * the recorder's software encoder uses a preset/thread count tuned for a
#     workstation.
#
# This script measures the resources the container actually has, classifies the
# host into a profile, and derives the environment and compositor settings that
# suit it. It is deliberately conservative and never assumes a GPU: the GPU
# path is left untouched (see gpu-session-env.sh).
#
#     perf-profile.sh report   # human-readable summary (default)
#     perf-profile.sh json     # machine-readable profile record
#     perf-profile.sh env      # KEY=VALUE exports for this host
#     perf-profile.sh apply    # write perf-profile.json + perf-env.sh
#     perf-profile.sh session  # apply compositor settings for the live session
#     perf-profile.sh bench    # time a software encode at the derived threads
#
# Test hooks (used by CI, no small host required):
#   FASTVM_PERF_FORCE_CPUS, FASTVM_PERF_FORCE_MEM_MB, FASTVM_PERF_FORCE_SHM_MB

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

STATE_DIR="${FASTVM_DATA_ROOT:-/config}/.fastvm"
PROFILE_JSON="${STATE_DIR}/perf-profile.json"
PROFILE_ENV="${STATE_DIR}/perf-env.sh"

# --- Resources actually available to this container --------------------------

detect_cpus() {
    if [[ -n "${FASTVM_PERF_FORCE_CPUS:-}" ]]; then
        echo "${FASTVM_PERF_FORCE_CPUS}"
        return
    fi
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
    if [[ -n "${FASTVM_PERF_FORCE_MEM_MB:-}" ]]; then
        echo "${FASTVM_PERF_FORCE_MEM_MB}"
        return
    fi
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

shm_mb() {
    if [[ -n "${FASTVM_PERF_FORCE_SHM_MB:-}" ]]; then
        echo "${FASTVM_PERF_FORCE_SHM_MB}"
        return
    fi
    df -Pm /dev/shm 2>/dev/null | awk 'NR==2{print $2}' || echo 0
}

# "graphics" (has a video engine), "compute" (accelerator with no display
# engine, e.g. AMD Instinct), or "none".
gpu_kind() {
    if [[ -n "${FASTVM_PERF_FORCE_GPU_KIND:-}" ]]; then
        echo "${FASTVM_PERF_FORCE_GPU_KIND}"
        return
    fi
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

# --- Classification ----------------------------------------------------------

# Map the measured budget to a profile. Kept pure so CI can pin it.
classify() {
    local cpus="$1" mem_mb="$2"
    if (( cpus <= 2 || mem_mb <= 4096 )); then
        echo constrained
    elif (( cpus <= 4 || mem_mb <= 8192 )); then
        echo balanced
    else
        echo performance
    fi
}

# llvmpipe threads: one per vCPU, never fewer than one.
raster_threads() {
    local cpus="$1"
    (( cpus < 1 )) && cpus=1
    echo "$cpus"
}

# Software-encode threads for the recorder: leave a core for the desktop.
encode_threads() {
    local cpus="$1" t=$(( cpus - 1 ))
    (( t < 1 )) && t=1
    echo "$t"
}

# --- Derived environment -----------------------------------------------------

# Emit KEY=VALUE lines for the host. `kind` is the GPU kind so a real GPU is
# never forced onto the software path.
profile_env() {
    local profile="$1" kind="$2" cpus="$3"
    local raster; raster="$(raster_threads "$cpus")"
    local enc; enc="$(encode_threads "$cpus")"

    case "$profile" in
        constrained|balanced)
            # Only steer Mesa to llvmpipe when there is no graphics GPU to use.
            if [[ "$kind" != "graphics" ]]; then
                echo "LIBGL_ALWAYS_SOFTWARE=1"
                echo "GALLIUM_DRIVER=llvmpipe"
                echo "LP_NUM_THREADS=${raster}"
                echo "MESA_GLTHREAD=true"
                # Do not make every GL app block on a vblank it cannot see.
                echo "vblank_mode=0"
                echo "__GL_SYNC_TO_VBLANK=0"
            fi
            echo "FASTVM_PERF_ENCODE_THREADS=${enc}"
            ;;
        *)
            # performance: leave defaults alone; a workstation does not need help.
            ;;
    esac
}

# Whether the compositor should be turned off for this host. Compositing on a
# software rasterizer costs CPU for pixels that are streamed away regardless.
want_compositing_off() {
    local profile="$1" kind="$2"
    [[ "$kind" == "graphics" ]] && { echo false; return; }
    case "$profile" in
        constrained|balanced) echo true ;;
        *) echo false ;;
    esac
}

# --- Output ------------------------------------------------------------------

print_report() {
    local cpus="$1" mem_mb="$2" shm="$3" kind="$4" profile="$5"
    echo "FastVM performance profile"
    echo "  CPUs available : ${cpus}"
    echo "  Memory         : ${mem_mb} MB"
    echo "  /dev/shm       : ${shm} MB"
    case "$kind" in
        graphics) echo "  GPU            : graphics (hardware path untouched)" ;;
        compute)  echo "  GPU            : compute-only accelerator (software desktop)" ;;
        *)        echo "  GPU            : none (software desktop)" ;;
    esac
    echo "  Profile        : ${profile}"
    echo "  Compositing off: $(want_compositing_off "$profile" "$kind")"
    echo "  Environment    :"
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && echo "    ${line}"
    done < <(profile_env "$profile" "$kind" "$cpus")
    if [[ "$(want_compositing_off "$profile" "$kind")" == "true" ]]; then
        echo "  Note           : compositor disabled to keep the stream on the CPU budget"
    fi
}

print_json() {
    local cpus="$1" mem_mb="$2" shm="$3" kind="$4" profile="$5"
    local line json_env=""
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        json_env+="${json_env:+,}\"${line%%=*}\":\"${line#*=}\""
    done < <(profile_env "$profile" "$kind" "$cpus")
    printf '{'
    printf '"cpus":%s,"memory_mb":%s,"shm_mb":%s,' "$cpus" "$mem_mb" "$shm"
    printf '"gpu_kind":"%s","profile":"%s",' "$kind" "$profile"
    printf '"compositing_off":%s,' "$(want_compositing_off "$profile" "$kind")"
    printf '"raster_threads":%s,"encode_threads":%s,' \
        "$(raster_threads "$cpus")" "$(encode_threads "$cpus")"
    printf '"env":{%s}' "$json_env"
    printf '}\n'
}

write_env_file() {
    local profile="$1" kind="$2" cpus="$3"
    ensure_dir "$STATE_DIR"
    {
        echo "# Generated by perf-profile.sh — do not edit."
        profile_env "$profile" "$kind" "$cpus" | sed 's/^/export /'
    } > "$PROFILE_ENV"
}

apply() {
    local cpus="$1" mem_mb="$2" shm="$3" kind="$4" profile="$5"
    ensure_dir "$STATE_DIR"
    print_json "$cpus" "$mem_mb" "$shm" "$kind" "$profile" > "$PROFILE_JSON"
    write_env_file "$profile" "$kind" "$cpus"
    print_report "$cpus" "$mem_mb" "$shm" "$kind" "$profile"
    echo "  Written to     : ${PROFILE_JSON}"
    echo "  Session env    : ${PROFILE_ENV}"
}

# Turn off desktop compositing for the live session when the profile calls for
# it. Mirrors gpu-session-env.sh, but also applies on CPU-only hosts.
disable_compositing() {
    local de="${FASTVM_DE:-}"
    de="${de^^}"
    case "$de" in
        XFCE*)
            if command -v xfconf-query >/dev/null 2>&1; then
                xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false >/dev/null 2>&1 || true
            fi
            ;;
        KDE*|PLASMA*)
            if command -v kwriteconfig6 >/dev/null 2>&1; then
                kwriteconfig6 --file kwinrc --group Compositing --key Enabled false >/dev/null 2>&1 || true
            elif command -v kwriteconfig5 >/dev/null 2>&1; then
                kwriteconfig5 --file kwinrc --group Compositing --key Enabled false >/dev/null 2>&1 || true
            fi
            ;;
        MATE*)
            if command -v gsettings >/dev/null 2>&1; then
                gsettings set org.mate.Marco.general compositing-manager false >/dev/null 2>&1 || true
            fi
            ;;
        *) : ;;  # GNOME/Cinnamon/Budgie/Unity cannot disable compositing.
    esac
}

session() {
    local cpus mem_mb kind profile
    cpus="$(detect_cpus)"; mem_mb="$(detect_mem_mb)"
    kind="$(gpu_kind)"; profile="$(classify "$cpus" "$mem_mb")"
    if [[ "$(want_compositing_off "$profile" "$kind")" == "true" ]]; then
        log_info "perf: profile=${profile}, disabling compositor"
        disable_compositing
    fi
}

# A small, honest local measurement: time a fixed software encode at the derived
# thread count versus the library default. Proves the clamp helps (or is neutral)
# on this host instead of asserting it. Skipped cleanly without ffmpeg.
bench() {
    local cpus mem_mb kind profile enc
    cpus="$(detect_cpus)"; mem_mb="$(detect_mem_mb)"
    kind="$(gpu_kind)"; profile="$(classify "$cpus" "$mem_mb")"
    enc="$(encode_threads "$cpus")"
    if ! command -v ffmpeg >/dev/null 2>&1; then
        log_warn "ffmpeg not installed; benchmark skipped"
        return 0
    fi
    local common=(-hide_banner -loglevel error -f lavfi -i testsrc=size=1280x720:rate=30 -t 5 -c:v libx264 -f null -)
    echo "FastVM encode benchmark (profile=${profile}, cpus=${cpus})"
    local t_default t_clamped
    t_default="$( { TIMEFORMAT='%R'; time ffmpeg "${common[@]}" >/dev/null 2>&1; } 2>&1 )"
    t_clamped="$( { TIMEFORMAT='%R'; time ffmpeg "${common[@]}" -threads "$enc" >/dev/null 2>&1; } 2>&1 )"
    echo "  default threads : ${t_default}s"
    echo "  clamped (${enc})    : ${t_clamped}s"
    echo "  (lower is better; a near-tie means the clamp is free on this host)"
}

main() {
    local mode="${1:-report}"
    local cpus mem_mb shm kind profile
    cpus="$(detect_cpus)"
    mem_mb="$(detect_mem_mb)"
    shm="$(shm_mb)"
    kind="$(gpu_kind)"
    profile="${FASTVM_PERF_PROFILE:-auto}"
    [[ "$profile" == "auto" || -z "$profile" ]] && profile="$(classify "$cpus" "$mem_mb")"

    case "$mode" in
        report) print_report "$cpus" "$mem_mb" "$shm" "$kind" "$profile" ;;
        json)   print_json "$cpus" "$mem_mb" "$shm" "$kind" "$profile" ;;
        env)    profile_env "$profile" "$kind" "$cpus" ;;
        apply)  apply "$cpus" "$mem_mb" "$shm" "$kind" "$profile" ;;
        session) session ;;
        bench)  bench ;;
        *) echo "usage: $0 {report|json|env|apply|session|bench}" >&2; exit 2 ;;
    esac
}

main "$@"
