#!/bin/bash
# FastVM autoscale monitor. Watches CPU/memory pressure and writes scaling
# recommendations to /var/log/fastvm/autoscale.log. The actual resource
# adjustment happens on the host via autoscale-adjust.sh, since a container
# can't change its own cgroup limits.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

if [[ "${FASTVM_AUTOSCALE_ENABLED:-false}" != "true" ]]; then
    log_info "Autoscale disabled. Set FASTVM_AUTOSCALE_ENABLED=true to enable."
    exit 0
fi

interval="${FASTVM_AUTOSCALE_INTERVAL:-30}"
interval="${interval%s}"
cpu_threshold="${FASTVM_AUTOSCALE_CPU_THRESHOLD:-80}"
mem_threshold="${FASTVM_AUTOSCALE_MEMORY_THRESHOLD:-80}"

ensure_dir "${FASTVM_LOG_DIR}"
LOG="${FASTVM_LOG_DIR}/autoscale.log"
STATE="${FASTVM_LOG_DIR}/autoscale.state"

high_streak=0
low_streak=0

# Read CPU% from /proc/stat by sampling deltas.
cpu_sample() {
    awk '/^cpu / {idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; print total" "idle}' /proc/stat
}

read_mem_pct() {
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END{ if (t>0) printf "%.0f", (t-a)*100/t; else print 0 }' /proc/meminfo
}

prev=$(cpu_sample)
sleep "$interval"
while true; do
    cur=$(cpu_sample)
    p_total=$(awk '{print $1}' <<< "$prev"); p_idle=$(awk '{print $2}' <<< "$prev")
    c_total=$(awk '{print $1}' <<< "$cur");  c_idle=$(awk '{print $2}' <<< "$cur")
    d_total=$(( c_total - p_total ))
    d_idle=$(( c_idle - p_idle ))
    cpu_pct=0
    (( d_total > 0 )) && cpu_pct=$(awk -v t="$d_total" -v i="$d_idle" 'BEGIN{printf "%.0f",(t-i)*100/t}')
    mem_pct=$(read_mem_pct)
    prev="$cur"

    decision="steady"
    if (( cpu_pct >= cpu_threshold )) || (( mem_pct >= mem_threshold )); then
        high_streak=$(( high_streak + 1 ))
        low_streak=0
        if (( high_streak >= 3 )); then
            decision="scale_up"
            high_streak=0
        fi
    elif (( cpu_pct < 50 )) && (( mem_pct < 50 )); then
        low_streak=$(( low_streak + 1 ))
        high_streak=0
        if (( low_streak >= 10 )); then
            decision="scale_down"
            low_streak=0
        fi
    else
        high_streak=0
        low_streak=0
    fi

    {
        printf '{"ts":%s,"cpu_pct":%s,"mem_pct":%s,"decision":"%s","high_streak":%s,"low_streak":%s}\n' \
            "$(date +%s)" "$cpu_pct" "$mem_pct" "$decision" "$high_streak" "$low_streak"
    } | tee -a "$LOG" > "$STATE"

    sleep "$interval"
done
