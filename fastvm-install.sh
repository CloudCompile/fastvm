#!/bin/bash
# FastVM Installation Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"
VERSION="2.0.0"

# =============================================================================
# Colors
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }
log_step()    { echo -e "${CYAN}[STEP]${NC} ${BOLD}$*${NC}"; }

# =============================================================================
# Error Handler
# =============================================================================
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        log_error "Installation failed (exit $exit_code)"
        log_info  "Check the output above for details."
    fi
}
trap cleanup EXIT
trap 'log_error "Script failed at line $LINENO"' ERR

# =============================================================================
# Banner
# =============================================================================
show_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'BANNER'
  ███████╗ █████╗ ███████╗████████╗██╗   ██╗███╗   ███╗
  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██║   ██║████╗ ████║
  █████╗  ███████║███████╗   ██║   ██║   ██║██╔████╔██║
  ██╔══╝  ██╔══██║╚════██║   ██║   ╚██╗ ██╔╝██║╚██╔╝██║
  ██║     ██║  ██║███████║   ██║    ╚████╔╝ ██║ ╚═╝ ██║
  ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝     ╚═╝
BANNER
    echo -e "${NC}"
    echo -e "  ${DIM}Linux desktop. In a tab.${NC}   ${MAGENTA}v${VERSION}${NC}"
    echo ""
}

# =============================================================================
# Prerequisites
# =============================================================================
check_prerequisites() {
    log_step "Checking prerequisites"

    local missing=()

    if ! command -v docker &>/dev/null; then
        missing+=("docker")
    elif ! docker info &>/dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    else
        log_success "Docker $(docker --version | awk '{print $3}' | tr -d ',')"
    fi

    if command -v docker-compose &>/dev/null; then
        DOCKER_COMPOSE="docker-compose"
        log_success "Docker Compose (v1)"
    elif docker compose version &>/dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
        log_success "Docker Compose (v2)"
    else
        missing+=("docker-compose")
    fi

    if ! command -v git &>/dev/null; then
        missing+=("git")
    else
        log_success "Git $(git --version | awk '{print $3}')"
    fi

    if ! command -v jq &>/dev/null; then
        log_warn "jq not found — installing…"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq jq
        elif command -v yum &>/dev/null; then
            sudo yum install -y jq
        elif command -v brew &>/dev/null; then
            brew install jq
        else
            missing+=("jq")
        fi
    else
        log_success "jq $(jq --version)"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing: ${missing[*]}"
        exit 1
    fi
    export DOCKER_COMPOSE
}

# =============================================================================
# Load & apply preset
# =============================================================================
load_configuration() {
    log_step "Loading configuration"

    if [[ -f "$CONFIG_FILE" ]]; then
        set -a; source "$CONFIG_FILE"; set +a  # shellcheck disable=SC1090
        log_success "Loaded $CONFIG_FILE"
    else
        log_warn "config.env not found — using defaults"
    fi

    # If a preset is set, apply it now (merges into config.env).
    if [[ -n "${FASTVM_PRESET:-}" ]] && [[ "${FASTVM_PRESET}" != "none" ]]; then
        local preset_file="${SCRIPT_DIR}/presets/${FASTVM_PRESET}.preset"
        if [[ -f "$preset_file" ]]; then
            log_info "Applying preset: ${FASTVM_PRESET}"
            set -a; source "$preset_file"; set +a  # shellcheck disable=SC1090
            log_success "Preset '${FASTVM_PRESET}' applied"
        else
            log_warn "Preset file not found: $preset_file"
        fi
    fi

    # Export every FASTVM_* variable for docker-compose.
    for var in $(compgen -v FASTVM_ 2>/dev/null || true); do
        declare -x "$var"
    done

    echo ""
    echo -e "  ${BOLD}Configuration summary${NC}"
    echo -e "  ${DIM}────────────────────────────────────────${NC}"
    printf  "  %-30s %s\n" "Container:"      "${FASTVM_NAME:-FastVM}"
    printf  "  %-30s %s\n" "Desktop:"        "${FASTVM_DE:-XFCE4}"
    printf  "  %-30s %s\n" "Preset:"         "${FASTVM_PRESET:-none}"
    printf  "  %-30s %s\n" "VNC port:"       "${FASTVM_PORT:-3000}"
    printf  "  %-30s %s\n" "Dashboard port:" "${FASTVM_DASHBOARD_PORT:-3001}"
    printf  "  %-30s %s\n" "CPU limit:"      "${FASTVM_CPU_LIMIT:-unlimited}"
    printf  "  %-30s %s\n" "Memory limit:"   "${FASTVM_MEMORY_LIMIT:-unlimited}"
    printf  "  %-30s %s\n" "Audio:"          "${FASTVM_AUDIO_ENABLED:-true}"
    printf  "  %-30s %s\n" "Clipboard sync:" "${FASTVM_CLIPBOARD_ENABLED:-true}"
    printf  "  %-30s %s\n" "Screen recording:" "${FASTVM_RECORDING_ENABLED:-true}"
    printf  "  %-30s %s\n" "Backups:"        "${FASTVM_BACKUP_ENABLED:-true} (${FASTVM_BACKUP_AUTO_SCHEDULE:-daily})"
    printf  "  %-30s %s\n" "Autoscaling:"    "${FASTVM_AUTOSCALE_ENABLED:-false}"
    echo ""
}

# =============================================================================
# Directories
# =============================================================================
prepare_directories() {
    log_step "Preparing directories"

    mkdir -p "${SCRIPT_DIR}/data"
    mkdir -p "${SCRIPT_DIR}/logs"
    mkdir -p "${SCRIPT_DIR}/backups"
    mkdir -p "${SCRIPT_DIR}/recordings"

    chmod 755 "${SCRIPT_DIR}/data" "${SCRIPT_DIR}/logs" \
              "${SCRIPT_DIR}/backups" "${SCRIPT_DIR}/recordings"

    log_success "Directories ready"
}

# =============================================================================
# Build
# =============================================================================
build_image() {
    log_step "Building FastVM Docker image"
    log_info "This may take a few minutes on first build…"

    BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    export BUILD_DATE
    export VERSION="${VERSION}"

    if ! $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" build --parallel; then
        log_error "Docker build failed"
        exit 1
    fi
    log_success "Image built"
}

# =============================================================================
# Start
# =============================================================================
start_fastvm() {
    log_step "Starting FastVM"
    $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" down 2>/dev/null || true

    if ! $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" up -d; then
        log_error "Failed to start FastVM"
        exit 1
    fi
    log_success "Container started"
}

# =============================================================================
# Health wait
# =============================================================================
wait_for_health() {
    log_step "Waiting for FastVM to be ready"

    local max=30 attempt=0
    local container="${FASTVM_NAME:-FastVM}"

    while (( attempt < max )); do
        attempt=$(( attempt + 1 ))

        local container_id
        container_id=$(docker ps -q -f "name=$container" 2>/dev/null)
        if [[ -z "$container_id" ]]; then
            echo -n "."; sleep 2; continue
        fi

        local health
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")

        if [[ "$health" == "healthy" ]]; then
            echo ""; log_success "FastVM is healthy"; return 0
        elif [[ "$health" == "unhealthy" ]]; then
            echo ""
            log_error "Container is unhealthy — check: docker logs $container"
            return 1
        fi
        echo -n "."; sleep 2
    done

    echo ""; log_warn "Health check timed out — container may still be starting"
}

# =============================================================================
# Status
# =============================================================================
show_status() {
    local port="${FASTVM_PORT:-3000}"
    local dport="${FASTVM_DASHBOARD_PORT:-3001}"

    echo ""
    echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}${BOLD}  │            FastVM is ready                          │${NC}"
    echo -e "${CYAN}${BOLD}  └─────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${BOLD}Access${NC}"
    echo    "    Desktop (KasmVNC)   →  http://localhost:${port}"
    echo    "    Dashboard           →  http://localhost:${dport}"
    echo -e "    Dashboard token     →  ${DIM}cat data/dashboard.token${NC}"
    echo ""
    echo -e "  ${BOLD}Management${NC}"
    echo    "    Logs      ${DOCKER_COMPOSE} logs -f"
    echo    "    Stop      ${DOCKER_COMPOSE} stop"
    echo    "    Snapshot  ./backup-manager.sh create"
    echo    "    Restore   ./backup-manager.sh restore <archive>"
    echo ""
    echo -e "  ${BOLD}Files${NC}"
    echo    "    Config    config.env"
    echo    "    Data      ./data/"
    echo    "    Backups   ./backups/"
    echo    "    Logs      ./logs/"
    echo    "    Recordings ./recordings/"
    echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
    show_banner
    check_prerequisites
    load_configuration
    prepare_directories
    build_image
    start_fastvm
    wait_for_health
    show_status
    log_success "Installation complete!"
}

main "$@"
