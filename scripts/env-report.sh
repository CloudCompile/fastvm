#!/usr/bin/env bash
# FastVM environment report.
#
# Detects the kind of host FastVM is running on (GitHub Codespaces, a cloud VM,
# plain Docker) and the things that silently change what works: whether hardware
# virtualisation (/dev/kvm) is available, and how big /dev/shm is.
#
# Writes .fastvm/environment.json and can print it. Best-effort: never fails the
# container, and every probe degrades to "unknown".

set -uo pipefail

DATA_ROOT="${FASTVM_DATA_ROOT:-/config}"
STATE_DIR="${DATA_ROOT}/.fastvm"
OUT_JSON="${STATE_DIR}/environment.json"

log()  { printf '%s\n' "$*"; }

# "codespaces", "github-actions", "docker", "vm", or "unknown".
detect_kind() {
    if [[ "${CODESPACES:-false}" == "true" ]]; then
        echo "codespaces"; return
    fi
    if [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        echo "github-actions"; return
    fi
    if [[ -f /.dockerenv ]]; then
        echo "docker"; return
    fi
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        local v; v="$(systemd-detect-virt 2>/dev/null || true)"
        if [[ -n "$v" && "$v" != "none" ]]; then
            echo "vm"; return
        fi
    fi
    echo "unknown"
}

# DMI product name is the most portable cloud hint inside a container.
detect_cloud() {
    local dmi=""
    [[ -r /sys/class/dmi/id/product_name ]] && dmi="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
    case "$dmi" in
        *"Compute Engine"*) echo "gcp" ;;
        *"Amazon EC2"*|*"EC2"*) echo "aws" ;;
        *"Virtual Machine"*|*"VirtualBox"*) echo "azure-or-virtualbox" ;;
        "") echo "unknown" ;;
        *)  echo "$dmi" ;;
    esac
}

# True when /dev/kvm exists and is usable for acceleration.
kvm_available() {
    [[ -e /dev/kvm ]] || return 1
    [[ -r /dev/kvm && -w /dev/kvm ]] || return 1
    return 0
}

shm_mb() {
    df -Pm /dev/shm 2>/dev/null | awk 'NR==2{print $2}' || echo 0
}

cpus() {
    if command -v nproc >/dev/null 2>&1; then nproc; else echo 0; fi
}

memory_mb() {
    awk '/MemTotal/{printf "%d\n", $2/1024}' /proc/meminfo 2>/dev/null || echo 0
}

# Free megabytes on the filesystem holding DATA_ROOT (the workspace in a
# Codespace). Image pulls and backups live here.
disk_free_mb() {
    df -Pm "${DATA_ROOT}" 2>/dev/null | awk 'NR==2{print $4}' || echo 0
}

# Emit a JSON array of notices. Each notice is {id, severity, message}.
notices_json() {
    local kind="$1" kvm="$2" shm="$3" disk="$4"
    local items=()

    if [[ "$kind" == "codespaces" ]]; then
        items+=('{"id":"codespaces","severity":"info","message":"GitHub Codespaces: ports 3000 (desktop) and 3001 (dashboard) are forwarded; the desktop opens automatically."}')
    fi
    if [[ "$kvm" != "true" ]]; then
        items+=('{"id":"no-kvm","severity":"info","message":"No /dev/kvm: virtual machines and emulator guests (Android, aqemu) run in software and will be slow."}')
    fi
    if [[ "${shm:-0}" -lt 512 ]]; then
        items+=("{\"id\":\"small-shm\",\"severity\":\"warn\",\"message\":\"/dev/shm is ${shm} MB (<512); Chromium/Electron apps may need --disable-dev-shm-usage. Raise FASTVM_SHM_SIZE.\"}")
    fi
    if [[ "${disk:-0}" -gt 0 && "${disk:-0}" -lt 8192 ]]; then
        items+=("{\"id\":\"low-disk\",\"severity\":\"warn\",\"message\":\"Only ${disk} MB free on the workspace filesystem; image pulls and backups need several GB.\"}")
    fi

    local joined=""
    local IFS=,
    joined="${items[*]:-}"
    printf '[%s]' "$joined"
}

json_bool() { [[ "$1" == "true" ]] && echo true || echo false; }

collect() {
    local kind cloud kvm shm cpu mem disk
    kind="$(detect_kind)"
    cloud="$(detect_cloud)"
    if kvm_available; then kvm=true; else kvm=false; fi
    shm="$(shm_mb)"; cpu="$(cpus)"; mem="$(memory_mb)"; disk="$(disk_free_mb)"

    cat <<EOF
{
  "kind": "${kind}",
  "cloud": "${cloud}",
  "kvm": $(json_bool "$kvm"),
  "shm_mb": ${shm},
  "cpus": ${cpu},
  "memory_mb": ${mem},
  "disk_free_mb": ${disk},
  "notices": $(notices_json "$kind" "$kvm" "$shm" "$disk")
}
EOF
}

print_report() {
    local kind cloud kvm shm cpu mem disk
    kind="$(detect_kind)"; cloud="$(detect_cloud)"
    if kvm_available; then kvm=true; else kvm=false; fi
    shm="$(shm_mb)"; cpu="$(cpus)"; mem="$(memory_mb)"; disk="$(disk_free_mb)"

    log "FastVM environment"
    log "  Host kind      : ${kind}"
    log "  Cloud          : ${cloud}"
    log "  Hardware virt  : $([[ "$kvm" == true ]] && echo "available (/dev/kvm)" || echo "unavailable (software only)")"
    log "  /dev/shm       : ${shm} MB"
    log "  CPUs / memory  : ${cpu} / ${mem} MB"
    log "  Disk free      : ${disk} MB"

    emit() { log "    - [$1] $2"; }
    [[ "$kind" == "codespaces" ]] && emit info "GitHub Codespaces: ports 3000 (desktop) and 3001 (dashboard) are forwarded; the desktop opens automatically."
    [[ "$kvm" != "true" ]] && emit info "No /dev/kvm: virtual machines and emulator guests (Android, aqemu) run in software and will be slow."
    [[ "${shm:-0}" -lt 512 ]] && emit warn "/dev/shm is ${shm} MB (<512); Chromium/Electron apps may need --disable-dev-shm-usage. Raise FASTVM_SHM_SIZE."
    [[ "${disk:-0}" -gt 0 && "${disk:-0}" -lt 8192 ]] && emit warn "Only ${disk} MB free on the workspace filesystem; image pulls and backups need several GB."
    return 0
}

write_json() {
    mkdir -p "$STATE_DIR"
    collect > "$OUT_JSON"
    log "Wrote ${OUT_JSON}"
}

case "${1:-report}" in
    report) print_report ;;
    json)   collect ;;
    write)  write_json ;;
    *)      echo "usage: env-report.sh [report|json|write]" >&2; exit 2 ;;
esac
