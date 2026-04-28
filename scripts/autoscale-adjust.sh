#!/bin/bash
# Host-side autoscale adjuster. Reads the latest decision written by
# autoscale-monitor.sh (inside the container) and updates docker-compose
# resource limits via FASTVM_CPU_LIMIT / FASTVM_MEMORY_LIMIT in config.env,
# then restarts the container so the new limits take effect.
#
# Run from cron on the host, e.g. */5 * * * *

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"
load_fastvm_config

CONTAINER="${FASTVM_NAME:-FastVM}"
[[ "${FASTVM_AUTOSCALE_ENABLED:-false}" == "true" ]] || { log_info "Autoscale disabled"; exit 0; }

state_file="${SCRIPT_DIR}/../logs/autoscale.state"
[[ -f "$state_file" ]] || { log_warn "No autoscale state yet ($state_file)"; exit 0; }

decision=$(grep -oP '"decision":"\K[^"]+' "$state_file" || echo "steady")
[[ "$decision" == "steady" ]] && exit 0

# Parse current limits.
cpu="${FASTVM_CPU_LIMIT:-2}"
mem="${FASTVM_MEMORY_LIMIT:-4g}"
mem_num="${mem%[gG]}"

min_cpu="${FASTVM_AUTOSCALE_MIN_CPU:-1}"
max_cpu="${FASTVM_AUTOSCALE_MAX_CPU:-4}"
min_mem="${FASTVM_AUTOSCALE_MIN_MEMORY:-2g}"
max_mem="${FASTVM_AUTOSCALE_MAX_MEMORY:-8g}"
min_mem_num="${min_mem%[gG]}"
max_mem_num="${max_mem%[gG]}"

case "$decision" in
    scale_up)
        new_cpu=$(( cpu + 1 ))
        (( new_cpu > max_cpu )) && new_cpu=$max_cpu
        new_mem=$(( mem_num + 1 ))
        (( new_mem > max_mem_num )) && new_mem=$max_mem_num
        ;;
    scale_down)
        new_cpu=$(( cpu - 1 ))
        (( new_cpu < min_cpu )) && new_cpu=$min_cpu
        new_mem=$(( mem_num - 1 ))
        (( new_mem < min_mem_num )) && new_mem=$min_mem_num
        ;;
    *) exit 0 ;;
esac

if (( new_cpu == cpu )) && (( new_mem == mem_num )); then
    log_info "Already at limit boundary; no change."
    exit 0
fi

log_step "Autoscale ${decision}: ${cpu}cpu/${mem_num}g -> ${new_cpu}cpu/${new_mem}g"

cfg="${SCRIPT_DIR}/../config.env"
sed -i.bak \
    -e "s/^FASTVM_CPU_LIMIT=.*/FASTVM_CPU_LIMIT=${new_cpu}/" \
    -e "s/^FASTVM_MEMORY_LIMIT=.*/FASTVM_MEMORY_LIMIT=${new_mem}g/" \
    "$cfg"

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    log_info "Restarting $CONTAINER with new limits"
    (cd "${SCRIPT_DIR}/.." && docker compose up -d --force-recreate fastvm)
fi

log_success "Autoscale adjustment applied."
