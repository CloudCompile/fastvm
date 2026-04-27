#!/bin/bash
# FastVM Installation Script
# Optimized, faster version of BlobeVM with proper error handling

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"
VERSION="1.0.0"

# =============================================================================
# Color Codes for Output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "${CYAN}[STEP]${NC} $*"; }

# =============================================================================
# Error Handler
# =============================================================================
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
        log_error "Check the logs above for more information"
    fi
}
trap cleanup EXIT
trap 'log_error "Script failed at line $LINENO"' ERR

# =============================================================================
# Banner
# =============================================================================
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    FastVM Installer v1.0                     ║
║                                                              ║
║         Optimized Virtual Machine for Web Browsers           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

# =============================================================================
# Check Prerequisites
# =============================================================================
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        # Check if Docker daemon is running
        if ! docker info &> /dev/null; then
            log_error "Docker daemon is not running"
            log_info "Please start Docker and try again"
            exit 1
        fi
        log_success "Docker is installed and running"
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
        log_success "Docker Compose (v1) is installed"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
        log_success "Docker Compose (v2) is installed"
    else
        missing_deps+=("docker-compose")
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    else
        log_success "Git is installed"
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed, will install..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v brew &> /dev/null; then
            brew install jq
        else
            missing_deps+=("jq")
        fi
    else
        log_success "jq is installed"
    fi
    
    # Report missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again"
        exit 1
    fi
    
    export DOCKER_COMPOSE
}

# =============================================================================
# Load Configuration
# =============================================================================
load_configuration() {
    log_step "Loading configuration..."
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Source the config file
        set -a
        source "$CONFIG_FILE"
        set +a
        log_success "Configuration loaded from $CONFIG_FILE"
    else
        log_warn "Configuration file not found: $CONFIG_FILE"
        log_info "Using default configuration"
    fi
    
    # Export all FASTVM_* variables for docker-compose
    for var in $(compgen -v FASTVM_ 2>/dev/null || true); do
        export "$var"
    done
    
    # Show configuration summary
    echo ""
    echo "Configuration Summary:"
    echo "  - Container Name: ${FASTVM_NAME:-FastVM}"
    echo "  - Port: ${FASTVM_PORT:-3000}"
    echo "  - Desktop Environment: ${FASTVM_DE:-XFCE4}"
    echo "  - User ID: ${FASTVM_PUID:-1000}"
    echo "  - Group ID: ${FASTVM_PGID:-1000}"
    echo "  - Shared Memory: ${FASTVM_SHM_SIZE:-2gb}"
    echo "  - KVM Enabled: ${FASTVM_ENABLE_KVM:-false}"
    echo ""
}

# =============================================================================
# Prepare Directories
# =============================================================================
prepare_directories() {
    log_step "Preparing directories..."
    
    # Create data directory
    mkdir -p "${SCRIPT_DIR}/data"
    mkdir -p "${SCRIPT_DIR}/logs"
    
    # Set proper permissions
    chmod 755 "${SCRIPT_DIR}/data"
    chmod 755 "${SCRIPT_DIR}/logs"
    
    log_success "Directories created"
}

# =============================================================================
# Build Docker Image
# =============================================================================
build_image() {
    log_step "Building FastVM Docker image..."
    log_info "This may take a few minutes..."
    
    # Export build args
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export VERSION="${VERSION}"
    
    # Build with cache (NO --no-cache for speed!)
    if ! $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" build --parallel; then
        log_error "Docker build failed"
        exit 1
    fi
    
    log_success "Docker image built successfully"
}

# =============================================================================
# Start FastVM
# =============================================================================
start_fastvm() {
    log_step "Starting FastVM..."
    
    # Stop any existing container
    $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" down 2>/dev/null || true
    
    # Start with docker-compose
    if ! $DOCKER_COMPOSE -f "${SCRIPT_DIR}/docker-compose.yml" up -d; then
        log_error "Failed to start FastVM"
        exit 1
    fi
    
    log_success "FastVM started successfully"
}

# =============================================================================
# Wait for Health Check
# =============================================================================
wait_for_health() {
    log_step "Waiting for FastVM to be ready..."
    
    local max_attempts=30
    local attempt=0
    local container_name="${FASTVM_NAME:-FastVM}"
    
    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))
        
        # Check if container is running
        if ! docker ps -q -f "name=$container_name" | grep -q .; then
            log_warn "Container not running, waiting..."
            sleep 2
            continue
        fi
        
        # Check health status
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        
        if [[ "$health_status" == "healthy" ]]; then
            log_success "FastVM is healthy and ready!"
            return 0
        elif [[ "$health_status" == "unhealthy" ]]; then
            echo ""
            log_error "Container reported 'unhealthy' — check logs with: docker logs $container_name"
            return 1
        else
            echo -n "."
            sleep 2
        fi
    done
    
    echo ""
    log_warn "Health check timed out, but container may still be starting"
    return 0
}

# =============================================================================
# Show Status
# =============================================================================
show_status() {
    local port="${FASTVM_PORT:-3000}"
    local container_name="${FASTVM_NAME:-FastVM}"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    log_success "FastVM Installation Complete!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Access Information:"
    echo "  - Local URL:    http://localhost:$port"
    echo "  - Container:    $container_name"
    echo ""
    echo "Management Commands:"
    echo "  - View logs:    ${DOCKER_COMPOSE} logs -f"
    echo "  - Stop:         ${DOCKER_COMPOSE} stop"
    echo "  - Start:        ${DOCKER_COMPOSE} start"
    echo "  - Restart:      ${DOCKER_COMPOSE} restart"
    echo "  - Remove:       ${DOCKER_COMPOSE} down"
    echo ""
    echo "Configuration:"
    echo "  - Config file:  $CONFIG_FILE"
    echo "  - Data dir:     ${SCRIPT_DIR}/data"
    echo "  - Logs dir:     ${SCRIPT_DIR}/logs"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# =============================================================================
# Main Function
# =============================================================================
main() {
    show_banner
    
    log_info "FastVM Installer v${VERSION}"
    log_info "Starting installation process..."
    echo ""
    
    # Run installation steps
    check_prerequisites
    load_configuration
    prepare_directories
    build_image
    start_fastvm
    wait_for_health
    show_status
    
    log_success "Installation completed successfully!"
}

# Run main function
main "$@"
