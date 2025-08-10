#!/bin/bash

# theraME Debug Suite - Enhanced debugging tools for all platforms

# Source the base platform configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../therame-platform.sh" 2>/dev/null || {
    # Fallback if therame-platform.sh doesn't exist
    THERAME_ROOT="C:/theramev11"
    MOBILE_DIR="$THERAME_ROOT"
    WEB_DIR="$THERAME_ROOT/web-build"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
    
    print_color() {
        local color=$1
        local message=$2
        echo -e "${color}${message}${NC}"
    }
    
    print_header() {
        echo ""
        print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"
        print_color "$CYAN" "║                   theraME Debug Suite                      ║"
        print_color "$CYAN" "║                      Version 1.1.0                         ║"
        print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
        echo ""
    }
}

# Function: Debug menu
show_debug_menu() {
    echo ""
    print_color "$CYAN" "Debug Options:"
    echo "  1) Check System Info"
    echo "  2) Analyze Dependencies"
    echo "  3) Metro Bundler Debug"
    echo "  4) Clear All Caches"
    echo "  5) Network Diagnostics"
    echo "  6) Check Port Usage"
    echo "  7) Analyze Bundle Size"
    echo "  8) Check Memory Usage"
    echo "  9) View Error Logs"
    echo "  10) Fix Common Issues"
    echo "  0) Exit"
    echo ""
}

# Function: System info
check_system_info() {
    print_color "$CYAN" "System Information"
    print_color "$CYAN" "=================="
    
    echo "Node Version: $(node --version)"
    echo "NPM Version: $(npm --version)"
    echo "Expo Version: $(npx expo --version 2>/dev/null || echo 'Not installed')"
    echo "EAS Version: $(eas --version 2>/dev/null || echo 'Not installed')"
    echo ""
    
    # Check disk space
    print_color "$YELLOW" "Disk Space:"
    df -h "$THERAME_ROOT" | tail -1
    echo ""
    
    # Check memory
    print_color "$YELLOW" "Memory Usage:"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        # Windows alternative
        wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /value 2>/dev/null | grep -E "Free|Total"
    fi
}

# Function: Analyze dependencies
analyze_dependencies() {
    print_color "$CYAN" "Dependency Analysis"
    print_color "$CYAN" "==================="
    
    cd "$MOBILE_DIR"
    
    # Check for duplicate dependencies
    print_color "$YELLOW" "Checking for duplicates..."
    npm ls --depth=0 2>&1 | grep -E "deduped|UNMET" || echo "No duplicates found"
    echo ""
    
    # Check peer dependencies
    print_color "$YELLOW" "Checking peer dependencies..."
    npm ls 2>&1 | grep "peer dep missing" || echo "All peer dependencies satisfied"
    echo ""
    
    # Size analysis
    print_color "$YELLOW" "Package sizes:"
    npx npm-check --skip-unused 2>/dev/null || npm ls --depth=0
}

# Function: Metro bundler debug
debug_metro() {
    print_color "$CYAN" "Metro Bundler Debug"
    print_color "$CYAN" "==================="
    
    cd "$MOBILE_DIR"
    
    # Clear metro cache
    print_color "$YELLOW" "Clearing Metro cache..."
    npx expo start --clear
    
    # Check for metro config issues
    if [ -f "metro.config.js" ]; then
        print_color "$GREEN" "✅ Metro config exists"
    else
        print_color "$YELLOW" "⚠️  No metro config, using defaults"
    fi
    
    # Reset cache
    print_color "$YELLOW" "Resetting cache..."
    npx react-native start --reset-cache
}

# Function: Clear all caches
clear_all_caches() {
    print_color "$CYAN" "Clearing All Caches"
    print_color "$CYAN" "==================="
    
    cd "$MOBILE_DIR"
    
    # NPM cache
    print_color "$YELLOW" "Clearing NPM cache..."
    npm cache clean --force
    
    # Metro cache
    print_color "$YELLOW" "Clearing Metro cache..."
    rm -rf "$TMPDIR/metro-*" 2>/dev/null
    rm -rf "$TEMP/metro-*" 2>/dev/null
    
    # Expo cache
    print_color "$YELLOW" "Clearing Expo cache..."
    rm -rf ~/.expo 2>/dev/null
    
    # Watchman cache (if installed)
    if command -v watchman >/dev/null 2>&1; then
        print_color "$YELLOW" "Clearing Watchman cache..."
        watchman watch-del-all
    fi
    
    # Node modules
    read -p "Clear node_modules? (y/n): " clear_nm
    if [ "$clear_nm" = "y" ]; then
        print_color "$YELLOW" "Removing node_modules..."
        rm -rf node_modules
        print_color "$YELLOW" "Reinstalling dependencies..."
        npm install
    fi
    
    print_color "$GREEN" "✅ All caches cleared"
}

# Function: Network diagnostics
network_diagnostics() {
    print_color "$CYAN" "Network Diagnostics"
    print_color "$CYAN" "==================="
    
    # Check localhost
    print_color "$YELLOW" "Testing localhost..."
    ping -c 1 localhost >/dev/null 2>&1 && echo "✅ Localhost accessible" || echo "❌ Localhost not accessible"
    
    # Check common ports
    print_color "$YELLOW" "Checking common ports..."
    local ports=(8081 19000 19001 3000)
    for port in "${ports[@]}"; do
        if netstat -an | grep -q ":$port "; then
            print_color "$YELLOW" "  Port $port: IN USE"
        else
            print_color "$GREEN" "  Port $port: Available"
        fi
    done
    
    # Check internet connectivity
    print_color "$YELLOW" "Testing internet connection..."
    ping -c 1 google.com >/dev/null 2>&1 && echo "✅ Internet connected" || echo "❌ No internet connection"
    
    # Get IP addresses
    print_color "$YELLOW" "Network interfaces:"
    if command -v ip >/dev/null 2>&1; then
        ip addr show | grep "inet " | grep -v "127.0.0.1"
    else
        ipconfig | grep -A 2 "IPv4"
    fi
}

# Function: Check port usage
check_port_usage() {
    print_color "$CYAN" "Port Usage Check"
    print_color "$CYAN" "================"
    
    local ports=(8081 19000 19001 3000 8080 5000)
    
    for port in "${ports[@]}"; do
        print_color "$YELLOW" "Checking port $port..."
        
        if command -v lsof >/dev/null 2>&1; then
            lsof -i :$port 2>/dev/null || echo "  Port $port is free"
        else
            netstat -an | grep ":$port " || echo "  Port $port is free"
        fi
    done
}

# Function: Analyze bundle size
analyze_bundle() {
    print_color "$CYAN" "Bundle Size Analysis"
    print_color "$CYAN" "===================="
    
    cd "$MOBILE_DIR"
    
    # Export for analysis
    print_color "$YELLOW" "Exporting bundle for analysis..."
    npx expo export --platform all --output-dir ./dist-analysis
    
    # Check sizes
    if [ -d "./dist-analysis" ]; then
        print_color "$YELLOW" "Bundle sizes:"
        du -sh ./dist-analysis/* 2>/dev/null | sort -h
        
        # Clean up
        rm -rf ./dist-analysis
    fi
    
    # Analyze with webpack bundle analyzer if available
    if [ -f "webpack.config.js" ]; then
        print_color "$YELLOW" "Running webpack bundle analyzer..."
        npx webpack-bundle-analyzer dist/stats.json -m static -r dist/report.html
    fi
}

# Function: Check memory usage
check_memory() {
    print_color "$CYAN" "Memory Usage Analysis"
    print_color "$CYAN" "====================="
    
    # Node process memory
    print_color "$YELLOW" "Node.js Memory Usage:"
    node -e "console.log(process.memoryUsage())"
    
    # System memory
    print_color "$YELLOW" "System Memory:"
    if command -v free >/dev/null 2>&1; then
        free -m
    else
        # Windows
        wmic computersystem get TotalPhysicalMemory /value
        wmic OS get FreePhysicalMemory /value
    fi
    
    # Check for memory leaks in package.json scripts
    print_color "$YELLOW" "Checking for potential memory leaks..."
    grep -r "node --max-old-space-size" . 2>/dev/null || echo "No memory limit overrides found"
}

# Function: View error logs
view_error_logs() {
    print_color "$CYAN" "Error Logs"
    print_color "$CYAN" "=========="
    
    # NPM logs
    local npm_log_dir="$HOME/.npm/_logs"
    if [ -d "$npm_log_dir" ]; then
        print_color "$YELLOW" "Recent NPM errors:"
        ls -lt "$npm_log_dir" | head -5
    fi
    
    # Metro logs
    print_color "$YELLOW" "Recent Metro errors:"
    find /tmp -name "metro-*.log" -type f 2>/dev/null | head -5
    
    # Application logs
    if [ -d "$THERAME_ROOT/logs" ]; then
        print_color "$YELLOW" "Application logs:"
        ls -lt "$THERAME_ROOT/logs" | head -5
    fi
}

# Function: Fix common issues
fix_common_issues() {
    print_color "$CYAN" "Fixing Common Issues"
    print_color "$CYAN" "===================="
    
    cd "$MOBILE_DIR"
    
    # Fix 1: Clear caches
    print_color "$YELLOW" "1. Clearing caches..."
    npm cache clean --force
    
    # Fix 2: Reinstall dependencies
    print_color "$YELLOW" "2. Fixing dependency issues..."
    rm -rf node_modules package-lock.json
    npm install
    
    # Fix 3: Reset Metro
    print_color "$YELLOW" "3. Resetting Metro bundler..."
    npx react-native start --reset-cache &
    sleep 5
    pkill -f "react-native start" 2>/dev/null
    
    # Fix 4: Fix permissions
    print_color "$YELLOW" "4. Fixing permissions..."
    chmod -R 755 android 2>/dev/null
    chmod -R 755 ios 2>/dev/null
    
    # Fix 5: Prebuild
    print_color "$YELLOW" "5. Running prebuild..."
    npx expo prebuild --clean
    
    print_color "$GREEN" "✅ Common issues fixed"
}

# Function: Generate debug report
generate_debug_report() {
    local report_file="$THERAME_ROOT/debug-reports/debug_${TIMESTAMP}.txt"
    mkdir -p "$(dirname "$report_file")"
    
    {
        echo "================================"
        echo "theraME Debug Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        
        echo "System Info:"
        node --version
        npm --version
        echo ""
        
        echo "Project Info:"
        cd "$MOBILE_DIR"
        jq -r '.expo.version' app.json 2>/dev/null || echo "Version not found"
        echo ""
        
        echo "Git Status:"
        git status --short
        echo ""
        
        echo "Recent Errors:"
        find "$HOME/.npm/_logs" -type f -name "*.log" -mtime -1 2>/dev/null | head -5
        
    } > "$report_file"
    
    print_color "$CYAN" "📊 Debug report saved to: $report_file"
}

# Function: Enhanced Metro debugging
debug_metro_enhanced() {
    print_color "$CYAN" "Metro Bundler Enhanced Debug"
    print_color "$CYAN" "============================"
    
    cd "$MOBILE_DIR"
    
    # Kill existing Metro instances
    print_color "$YELLOW" "Stopping existing Metro instances..."
    kill_port 8081 2>/dev/null
    
    # Clear all Metro caches
    print_color "$YELLOW" "Clearing Metro cache..."
    rm -rf "$TMPDIR/metro-*" 2>/dev/null
    rm -rf "$TEMP/metro-*" 2>/dev/null
    rm -rf "$HOME/.metro" 2>/dev/null
    
    # Create Metro config if missing
    if [ ! -f "metro.config.js" ]; then
        print_color "$YELLOW" "Creating Metro config..."
        cat > metro.config.js << 'EOF'
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Add debugging options
config.resolver.assetExts.push('db');
config.transformer.minifierConfig = {
  keep_fnames: true,
  mangle: {
    keep_fnames: true,
  }
};

module.exports = config;
EOF
    fi
    
    # Start Metro with verbose logging
    print_color "$YELLOW" "Starting Metro with verbose logging..."
    METRO_LOG_LEVEL=debug npx expo start --clear --dev-client &
    local metro_pid=$!
    
    sleep 5
    
    if ps -p $metro_pid > /dev/null; then
        print_color "$GREEN" "✅ Metro started successfully (PID: $metro_pid)"
        print_color "$CYAN" "Debug options:"
        echo "  Press 'j' - Open Chrome DevTools"
        echo "  Press 'm' - Toggle menu"
        echo "  Press 'r' - Reload app"
        echo "  Press 'd' - Open React DevTools"
        echo ""
        print_color "$YELLOW" "Metro is running at: http://localhost:8081"
        print_color "$YELLOW" "Bundler: http://localhost:8081/debugger-ui"
        
        read -p "Press enter to stop Metro..."
        kill $metro_pid 2>/dev/null
    else
        print_color "$RED" "❌ Failed to start Metro"
    fi
}

# Function: Debug platform-specific issues
debug_platform() {
    local platform=${1:-}
    
    if [ -z "$platform" ]; then
        platform=$(get_platform_choice)
    fi
    
    case $platform in
        ios)
            print_color "$CYAN" "iOS Debugging"
            print_color "$CYAN" "============="
            
            # Check Xcode
            if command -v xcodebuild >/dev/null 2>&1; then
                print_color "$GREEN" "✅ Xcode installed"
                xcodebuild -version
            else
                print_color "$RED" "❌ Xcode not found"
            fi
            
            # Check simulator
            if command -v xcrun >/dev/null 2>&1; then
                print_color "$YELLOW" "Available simulators:"
                xcrun simctl list devices available
            fi
            ;;
            
        android)
            print_color "$CYAN" "Android Debugging"
            print_color "$CYAN" "================="
            
            # Check Android SDK
            if [ -n "$ANDROID_HOME" ]; then
                print_color "$GREEN" "✅ ANDROID_HOME set: $ANDROID_HOME"
            else
                print_color "$RED" "❌ ANDROID_HOME not set"
            fi
            
            # Check ADB
            if command -v adb >/dev/null 2>&1; then
                print_color "$GREEN" "✅ ADB installed"
                adb devices
            else
                print_color "$RED" "❌ ADB not found"
            fi
            
            # Check emulators
            if command -v emulator >/dev/null 2>&1; then
                print_color "$YELLOW" "Available emulators:"
                emulator -list-avds
            fi
            ;;
            
        web)
            print_color "$CYAN" "Web Debugging"
            print_color "$CYAN" "============="
            
            # Check web build
            if [ -d "$WEB_DIR" ]; then
                print_color "$GREEN" "✅ Web build directory exists"
                du -sh "$WEB_DIR"
            else
                print_color "$YELLOW" "⚠️  No web build found"
            fi
            
            # Check webpack config
            if [ -f "$MOBILE_DIR/webpack.config.js" ]; then
                print_color "$GREEN" "✅ Webpack config exists"
            else
                print_color "$YELLOW" "⚠️  Using default webpack config"
            fi
            ;;
    esac
}

# Main execution
main() {
    print_header
    
    local mode=${1:-menu}
    
    case $mode in
        quick)
            check_system_info
            check_port_usage
            ;;
        full)
            check_system_info
            analyze_dependencies
            network_diagnostics
            check_port_usage
            check_memory
            generate_debug_report
            ;;
        fix)
            fix_common_issues
            ;;
        metro)
            debug_metro_enhanced
            ;;
        platform)
            debug_platform "$2"
            ;;
        menu|*)
            while true; do
                show_debug_menu
                read -p "Select option: " choice
                
                case $choice in
                    1) check_system_info ;;
                    2) analyze_dependencies ;;
                    3) debug_metro_enhanced ;;
                    4) clear_all_caches ;;
                    5) network_diagnostics ;;
                    6) check_port_usage ;;
                    7) analyze_bundle ;;
                    8) check_memory ;;
                    9) view_error_logs ;;
                    10) fix_common_issues ;;
                    0) exit 0 ;;
                    *) print_color "$RED" "Invalid option" ;;
                esac
                
                echo ""
                read -p "Press enter to continue..."
            done
            ;;
    esac
}

# Execute
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi