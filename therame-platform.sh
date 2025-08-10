#!/bin/bash

# theraME Platform - Base configuration and shared functions
# This file is sourced by other theraME scripts

# Base Configuration
export THERAME_ROOT="${THERAME_ROOT:-C:/theramev11}"
export MOBILE_DIR="${MOBILE_DIR:-$THERAME_ROOT}"
export WEB_DIR="${WEB_DIR:-$THERAME_ROOT/web-build}"
export SHARED_DIR="${SHARED_DIR:-$THERAME_ROOT/packages/shared}"
export BACKUP_ROOT="${BACKUP_ROOT:-C:/Users/jerem/source/repos/Jeremyelectron}"
export VERSION_FILE="${VERSION_FILE:-$THERAME_ROOT/version-matrix.json}"
export TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d_%H%M%S)}"

# API Configuration
export API_URL="${API_URL:-http://localhost:3000}"
export API_KEY="${API_KEY:-}"

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Logging configuration
export LOG_DIR="$THERAME_ROOT/logs"
export LOG_FILE="$LOG_DIR/therame_${TIMESTAMP}.log"
mkdir -p "$LOG_DIR"

# Function: Print colored output with logging
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Function: Print header
print_header() {
    echo ""
    print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                  theraME Platform System                   ║"
    print_color "$CYAN" "║                      Version 1.1.0                         ║"
    print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function: Check prerequisites
check_prerequisites() {
    local silent=${1:-false}
    
    [ "$silent" = "false" ] && print_color "$YELLOW" "Checking prerequisites..."
    
    local missing_tools=()
    local warnings=()
    
    # Check required tools
    command -v node >/dev/null 2>&1 || missing_tools+=("node")
    command -v npm >/dev/null 2>&1 || missing_tools+=("npm")
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    
    # Check optional tools
    command -v expo >/dev/null 2>&1 || warnings+=("expo-cli")
    command -v eas >/dev/null 2>&1 || warnings+=("eas-cli")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        [ "$silent" = "false" ] && print_color "$RED" "❌ Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    if [ ${#warnings[@]} -gt 0 ] && [ "$silent" = "false" ]; then
        print_color "$YELLOW" "⚠️  Missing optional tools: ${warnings[*]}"
    fi
    
    [ "$silent" = "false" ] && print_color "$GREEN" "✅ Prerequisites check complete"
    return 0
}

# Function: Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Get current version from app.json
get_current_version() {
    if [ -f "$MOBILE_DIR/app.json" ]; then
        jq -r '.expo.version' "$MOBILE_DIR/app.json" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Function: Get project name
get_project_name() {
    if [ -f "$MOBILE_DIR/app.json" ]; then
        jq -r '.expo.name' "$MOBILE_DIR/app.json" 2>/dev/null || echo "theraME"
    else
        echo "theraME"
    fi
}

# Function: Check if port is in use
is_port_in_use() {
    local port=$1
    if command_exists lsof; then
        lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1
    elif command_exists netstat; then
        netstat -an | grep -q ":$port.*LISTEN"
    else
        return 1
    fi
}

# Function: Kill process on port
kill_port() {
    local port=$1
    if command_exists lsof; then
        local pid=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null)
        [ -n "$pid" ] && kill -9 $pid
    fi
}

# Function: Wait for port to be available
wait_for_port() {
    local port=$1
    local timeout=${2:-30}
    local elapsed=0
    
    while is_port_in_use $port && [ $elapsed -lt $timeout ]; do
        sleep 1
        ((elapsed++))
    done
    
    [ $elapsed -lt $timeout ]
}

# Function: Check network connectivity
check_network() {
    if ping -c 1 google.com >/dev/null 2>&1; then
        return 0
    else
        print_color "$RED" "❌ No internet connection"
        return 1
    fi
}

# Function: Get IP address
get_ip_address() {
    if command_exists ip; then
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1
    elif command_exists ifconfig; then
        ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1
    else
        echo "localhost"
    fi
}

# Function: Ensure directory exists
ensure_dir() {
    local dir=$1
    [ ! -d "$dir" ] && mkdir -p "$dir"
}

# Function: Backup file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.${TIMESTAMP}"
        print_color "$GREEN" "✅ Backed up: $file"
    fi
}

# Function: Check git status
check_git_status() {
    cd "$THERAME_ROOT"
    if [ -d ".git" ]; then
        local branch=$(git branch --show-current)
        local changes=$(git status --porcelain | wc -l)
        echo "Branch: $branch, Changes: $changes"
    else
        echo "Not a git repository"
    fi
}

# Function: Safe JSON update
update_json() {
    local file=$1
    local key=$2
    local value=$3
    
    if [ -f "$file" ]; then
        backup_file "$file"
        jq "$key = $value" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# Function: Check EAS login status
check_eas_login() {
    if command_exists eas; then
        eas whoami >/dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# Function: Get platform from user
get_platform_choice() {
    echo "Select platform:"
    echo "  1) iOS"
    echo "  2) Android"
    echo "  3) Web"
    echo "  4) All"
    read -p "Choice: " choice
    
    case $choice in
        1) echo "ios" ;;
        2) echo "android" ;;
        3) echo "web" ;;
        4) echo "all" ;;
        *) echo "all" ;;
    esac
}

# Function: Get environment from user
get_environment_choice() {
    echo "Select environment:"
    echo "  1) Development"
    echo "  2) Preview/Staging"
    echo "  3) Production"
    read -p "Choice: " choice
    
    case $choice in
        1) echo "development" ;;
        2) echo "preview" ;;
        3) echo "production" ;;
        *) echo "development" ;;
    esac
}

# Function: Confirm action
confirm_action() {
    local message=${1:-"Continue?"}
    read -p "$message (y/n): " confirm
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]
}

# Function: Show spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function: Run with spinner
run_with_spinner() {
    local command=$1
    local message=${2:-"Processing..."}
    
    print_color "$YELLOW" "$message"
    eval "$command" &
    show_spinner $!
    wait $!
    local result=$?
    
    if [ $result -eq 0 ]; then
        print_color "$GREEN" "✅ Success"
    else
        print_color "$RED" "❌ Failed"
    fi
    
    return $result
}

# Export all functions
export -f print_color
export -f print_header
export -f check_prerequisites
export -f command_exists
export -f get_current_version
export -f get_project_name
export -f is_port_in_use
export -f kill_port
export -f wait_for_port
export -f check_network
export -f get_ip_address
export -f ensure_dir
export -f backup_file
export -f check_git_status
export -f update_json
export -f check_eas_login
export -f get_platform_choice
export -f get_environment_choice
export -f confirm_action
export -f show_spinner
export -f run_with_spinner

# Initialize
ensure_dir "$LOG_DIR"