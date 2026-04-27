#!/bin/bash
# FastVM Parallel Application Installation Script
# Optimized with parallel processing and proper error handling

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
JSON_FILE="/options.json"
INSTALL_DIR="/installable-apps"
# Use number of CPU cores, capped at 8, with a minimum of 3
MAX_PARALLEL=$(( $(nproc) > 8 ? 8 : $(nproc) < 3 ? 3 : $(nproc) ))

# =============================================================================
# Logging Functions
# =============================================================================
log_info()    { echo "[INFO] $*"; }
log_error()   { echo "[ERROR] $*" >&2; }
log_success() { echo "[SUCCESS] $*"; }
log_warn()    { echo "[WARN] $*" >&2; }

# =============================================================================
# Error Handler
# =============================================================================
trap 'log_error "Script failed at line $LINENO"' ERR

# =============================================================================
# Helper Functions
# =============================================================================

# Check if jq query returns true (optimized - no grep needed)
jq_check() {
    local query="$1"
    jq -e "$query" "$JSON_FILE" >/dev/null 2>&1
}

# Install a single app with error handling
install_app() {
    local app_name="$1"
    local script_path="$2"

    log_info "Installing $app_name..."
    chmod +x "$script_path"
    if "$script_path" 2>&1; then
        log_success "$app_name installed successfully"
    else
        log_error "Failed to install $app_name"
        return 1
    fi
}

# =============================================================================
# Build Installation Queue
# =============================================================================

declare -a INSTALL_QUEUE
declare -A APP_NAMES

# Default Apps
if jq_check '.defaultapps | contains([0])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/wine.sh")
    APP_NAMES["$INSTALL_DIR/wine.sh"]="Wine"
fi

if jq_check '.defaultapps | contains([1])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/chrome.sh")
    APP_NAMES["$INSTALL_DIR/chrome.sh"]="Chrome"
fi

if jq_check '.defaultapps | contains([2])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/xarchiver.sh")
    APP_NAMES["$INSTALL_DIR/xarchiver.sh"]="Xarchiver"
fi

if jq_check '.defaultapps | contains([3])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/discord.sh")
    APP_NAMES["$INSTALL_DIR/discord.sh"]="Discord"
fi

if jq_check '.defaultapps | contains([4])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/steam.sh")
    APP_NAMES["$INSTALL_DIR/steam.sh"]="Steam"
fi

if jq_check '.defaultapps | contains([5])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/minecraft.sh")
    APP_NAMES["$INSTALL_DIR/minecraft.sh"]="Minecraft"
fi

# Programming Tools
if jq_check '.programming | contains([0])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/openjdk-8-jre.sh")
    APP_NAMES["$INSTALL_DIR/openjdk-8-jre.sh"]="OpenJDK 8"
fi

if jq_check '.programming | contains([1])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/openjdk-17-jre.sh")
    APP_NAMES["$INSTALL_DIR/openjdk-17-jre.sh"]="OpenJDK 17"
fi

if jq_check '.programming | contains([2])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/vscodium.sh")
    APP_NAMES["$INSTALL_DIR/vscodium.sh"]="VSCodium"
fi

# Additional Apps
if jq_check '.apps | contains([0])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/vlc.sh")
    APP_NAMES["$INSTALL_DIR/vlc.sh"]="VLC"
fi

if jq_check '.apps | contains([1])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/libreoffice.sh")
    APP_NAMES["$INSTALL_DIR/libreoffice.sh"]="LibreOffice"
fi

if jq_check '.apps | contains([2])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/synaptic.sh")
    APP_NAMES["$INSTALL_DIR/synaptic.sh"]="Synaptic"
fi

if jq_check '.apps | contains([3])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/aqemu.sh")
    APP_NAMES["$INSTALL_DIR/aqemu.sh"]="AQemu"
fi

if jq_check '.apps | contains([4])' "$JSON_FILE"; then
    INSTALL_QUEUE+=("$INSTALL_DIR/tlauncher.sh")
    APP_NAMES["$INSTALL_DIR/tlauncher.sh"]="TLauncher"
fi

# =============================================================================
# Parallel Installation
# =============================================================================

# Handle empty array with set -u (nounset) - bash treats empty arrays as unset
TOTAL_APPS=0
if [[ -n "${INSTALL_QUEUE[*]}" ]]; then
    TOTAL_APPS=${#INSTALL_QUEUE[@]}
fi

if [[ $TOTAL_APPS -eq 0 ]]; then
    log_info "No applications to install"
    exit 0
fi

log_info "Installing $TOTAL_APPS applications (max parallel: $MAX_PARALLEL)..."

# Create temporary directory for job management
JOB_DIR=$(mktemp -d)
trap "rm -rf $JOB_DIR" EXIT

# Function to run installation with job control
run_with_job_control() {
    local script="$1"
    local name="$2"
    local job_id="$3"

    {
        install_app "$name" "$script" > "$JOB_DIR/job_$job_id.log" 2>&1; _rc=$?
        echo $_rc > "$JOB_DIR/job_$job_id.status"
    } &
    echo $! > "$JOB_DIR/job_$job_id.pid"
    echo "$name" > "$JOB_DIR/job_$job_id.name"
}

# Install apps with limited parallelism
CURRENT_JOBS=0
JOB_ID=0
FAILED_APPS=()

for script in ${INSTALL_QUEUE[@]+"${INSTALL_QUEUE[@]}"}; do
    name="${APP_NAMES[$script]}"

    # Wait if we've reached max parallel jobs
    while [[ $CURRENT_JOBS -ge $MAX_PARALLEL ]]; do
        wait -n 2>/dev/null || true
        CURRENT_JOBS=$((CURRENT_JOBS - 1))
    done

    # Start new job
    run_with_job_control "$script" "$name" "$JOB_ID"
    CURRENT_JOBS=$((CURRENT_JOBS + 1))
    JOB_ID=$((JOB_ID + 1))
done

# Wait for all remaining jobs
wait

# Check results
for ((i=0; i<JOB_ID; i++)); do
    status_file="$JOB_DIR/job_$i.status"
    log_file="$JOB_DIR/job_$i.log"
    name_file="$JOB_DIR/job_$i.name"

    app_name=$(cat "$name_file" 2>/dev/null || echo "Job $i")
    if [[ -f "$status_file" ]]; then
        status=$(cat "$status_file")
        if [[ "$status" -ne 0 ]]; then
            log_error "Installation of '$app_name' failed (exit $status)"
            [[ -f "$log_file" ]] && cat "$log_file" >&2
            FAILED_APPS+=("$app_name")
        fi
    else
        log_error "Installation of '$app_name' produced no status (subshell crash)"
        [[ -f "$log_file" ]] && cat "$log_file" >&2
        FAILED_APPS+=("$app_name")
    fi
done

# =============================================================================
# Summary
# =============================================================================

log_info "Application installation complete!"
log_info "Total apps: $TOTAL_APPS"

if [[ ${#FAILED_APPS[@]} -gt 0 ]]; then
    log_warn "Failed installations: ${#FAILED_APPS[@]}"
    for app in "${FAILED_APPS[@]}"; do
        log_warn "  - $app"
    done
fi
