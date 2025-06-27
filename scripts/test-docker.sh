#!/bin/bash

# Docker Setup Validation Script
# Tests the Docker configuration without requiring real Discord tokens

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test Docker Compose syntax
test_compose_syntax() {
    log_info "Testing Compose file syntax..."
    
    cd "$PROJECT_ROOT"
    
    # Test base compose file
    if docker compose -f compose.yml config > /dev/null 2>&1; then
        log_success "Base compose.yml syntax is valid"
    else
        log_error "Base compose.yml has syntax errors"
        return 1
    fi
    
    # Test environment-specific files
    for env in dev test prod; do
        if docker compose -f compose.yml -f "compose.$env.yml" config > /dev/null 2>&1; then
            log_success "compose.$env.yml syntax is valid"
        else
            log_error "compose.$env.yml has syntax errors"
            return 1
        fi
    done
}

# Test Docker build
test_docker_build() {
    log_info "Testing Docker build..."
    
    cd "$PROJECT_ROOT"
    
    if docker build -t discord-bot-test . > /dev/null 2>&1; then
        log_success "Docker build completed successfully"
        
        # Clean up test image
        docker rmi discord-bot-test > /dev/null 2>&1 || true
    else
        log_error "Docker build failed"
        return 1
    fi
}

# Test secrets structure
test_secrets_structure() {
    log_info "Testing secrets directory structure..."
    
    local required_envs=("dev" "test")
    local required_secrets=("discord_token.txt" "database_url.txt" "db_password.txt")
    
    for env in "${required_envs[@]}"; do
        local secrets_dir="$PROJECT_ROOT/secrets/$env"
        
        if [[ -d "$secrets_dir" ]]; then
            log_success "Secrets directory exists: $env"
            
            for secret in "${required_secrets[@]}"; do
                if [[ -f "$secrets_dir/$secret" ]]; then
                    log_success "Secret file exists: $env/$secret"
                else
                    log_error "Missing secret file: $env/$secret"
                    return 1
                fi
            done
        else
            log_error "Missing secrets directory: $env"
            return 1
        fi
    done
}

# Test environment files
test_environment_files() {
    log_info "Testing environment configuration files..."
    
    local env_files=(".env.dev" ".env.test" ".env.prod")
    
    for env_file in "${env_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$env_file" ]]; then
            log_success "Environment file exists: $env_file"
            
            # Check for required variables
            if grep -q "COMPOSE_ENV=" "$PROJECT_ROOT/$env_file"; then
                log_success "COMPOSE_ENV configured in $env_file"
            else
                log_error "COMPOSE_ENV missing in $env_file"
                return 1
            fi
        else
            log_error "Missing environment file: $env_file"
            return 1
        fi
    done
}

# Test container security settings
test_security_settings() {
    log_info "Testing security configuration..."
    
    cd "$PROJECT_ROOT"
    
    # Check for security settings in compose configuration
    local config_output=$(docker compose -f compose.yml -f compose.dev.yml config)
    
    if echo "$config_output" | grep -q "read_only: true"; then
        log_success "Read-only filesystem configured"
    else
        log_error "Read-only filesystem not configured"
        return 1
    fi
    
    # Check if using distroless nonroot image in Dockerfile (inherently non-root)
    if grep -q "distroless.*nonroot" "$PROJECT_ROOT/Dockerfile" || \
       echo "$config_output" | grep -q "user: .*65532"; then
        log_success "Non-root user configured (distroless nonroot)"
    else
        log_error "Non-root user not configured"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting Docker configuration validation..."
    
    local test_functions=(
        "test_compose_syntax"
        "test_docker_build"
        "test_secrets_structure"
        "test_environment_files"
        "test_security_settings"
    )
    
    local failed_tests=0
    
    for test_func in "${test_functions[@]}"; do
        if ! $test_func; then
            ((failed_tests++))
        fi
    done
    
    echo
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All Docker configuration tests passed!"
        log_info "Ready for deployment. Run: ./scripts/setup.sh dev"
    else
        log_error "$failed_tests test(s) failed. Please fix the issues above."
        exit 1
    fi
}

main "$@"