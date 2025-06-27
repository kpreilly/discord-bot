#!/bin/bash

# Discord Bot Setup Script for 2025 Docker Compose v2
# Usage: ./scripts/setup.sh [dev|test|prod]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose v2
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose v2 is not available. Please update to Docker Engine 24.0+"
        exit 1
    fi
    
    local compose_version=$(docker compose version --short)
    log_success "Docker Compose v2 detected: $compose_version"
}

# Setup environment
setup_environment() {
    log_info "Setting up $ENVIRONMENT environment..."
    
    # Create secrets directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/secrets/$ENVIRONMENT"
    
    # Check if secrets exist
    local secrets_dir="$PROJECT_ROOT/secrets/$ENVIRONMENT"
    local discord_token_file="$secrets_dir/discord_token.txt"
    
    if [[ ! -f "$discord_token_file" ]] || [[ "$(cat "$discord_token_file")" == *"PLACEHOLDER"* ]]; then
        log_warning "Discord token not configured for $ENVIRONMENT environment"
        log_info "Please update: $discord_token_file"
        
        if [[ "$ENVIRONMENT" == "dev" ]]; then
            log_info "For development, you can get a token from: https://discord.com/developers/applications"
        fi
    fi
}

# Build and start services
start_services() {
    log_info "Building and starting services for $ENVIRONMENT environment..."
    
    cd "$PROJECT_ROOT"
    
    # Set environment
    export COMPOSE_ENV="$ENVIRONMENT"
    
    # Build images
    log_info "Building Docker images..."
    docker compose -f compose.yml -f "compose.$ENVIRONMENT.yml" build
    
    # Start services
    log_info "Starting services..."
    docker compose -f compose.yml -f "compose.$ENVIRONMENT.yml" up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 10
    
    # Check service status
    docker compose ps
}

# Validate deployment
validate_deployment() {
    log_info "Validating deployment..."
    
    # Check if containers are running
    local running_containers=$(docker compose ps --services --filter "status=running" | wc -l)
    local total_containers=$(docker compose ps --services | wc -l)
    
    if [[ "$running_containers" -eq "$total_containers" ]]; then
        log_success "All containers are running ($running_containers/$total_containers)"
    else
        log_warning "Some containers are not running ($running_containers/$total_containers)"
        docker compose ps
    fi
    
    # Check logs for obvious errors
    log_info "Checking recent logs for errors..."
    docker compose logs --tail=20
}

# Show usage information
show_usage() {
    cat << EOF
Discord Bot Setup Script

Usage: $0 [ENVIRONMENT]

Environments:
  dev   - Development environment (default)
  test  - Testing environment
  prod  - Production environment

Examples:
  $0 dev   # Setup development environment
  $0 prod  # Setup production environment

Prerequisites:
  - Docker Engine 24.0+ with Compose v2
  - Discord Bot Token configured in secrets/

For more information, see docs/deployment.md
EOF
}

# Main execution
main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        log_info "Valid environments: dev, test, prod"
        exit 1
    fi
    
    log_info "Setting up Discord Bot - $ENVIRONMENT environment"
    
    check_prerequisites
    setup_environment
    start_services
    validate_deployment
    
    log_success "Discord Bot setup complete for $ENVIRONMENT environment!"
    log_info "View logs: docker compose logs -f"
    log_info "Stop services: docker compose down"
}

main "$@"