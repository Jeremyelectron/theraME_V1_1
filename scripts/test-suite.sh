#!/bin/bash

# theraME Test Suite - Complete testing for all platforms

# Source the base platform configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../therame-platform.sh" 2>/dev/null || {
    # Fallback if therame-platform.sh doesn't exist
    THERAME_ROOT="C:/theramev11"
    MOBILE_DIR="$THERAME_ROOT"
    WEB_DIR="$THERAME_ROOT/web-build"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    
    print_color() {
        local color=$1
        local message=$2
        echo -e "${color}${message}${NC}"
    }
    
    print_header() {
        echo ""
        print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"
        print_color "$CYAN" "║                   theraME Test Suite                       ║"
        print_color "$CYAN" "║                      Version 1.1.0                         ║"
        print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
        echo ""
    }
}

# Test results storage
TEST_RESULTS=()
TEST_PASSED=0
TEST_FAILED=0
TEST_WARNINGS=0

# Function: Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function: Print header
print_header() {
    echo ""
    print_color "$CYAN" "╔════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                   theraME Test Suite                       ║"
    print_color "$CYAN" "║                      Version 1.0.0                         ║"
    print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function: Check prerequisites
check_prerequisites() {
    print_color "$YELLOW" "Checking prerequisites..."
    
    local tools=("node" "npm" "expo" "eas")
    for tool in "${tools[@]}"; do
        if command -v $tool >/dev/null 2>&1; then
            print_color "$GREEN" "  ✅ $tool is installed"
        else
            print_color "$RED" "  ❌ $tool is not installed"
            TEST_WARNINGS=$((TEST_WARNINGS + 1))
        fi
    done
}

# Function: Run test and record result
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_color "$YELLOW" "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        TEST_RESULTS+=("✅ $test_name: PASSED")
        ((TEST_PASSED++))
        print_color "$GREEN" "  ✅ $test_name passed"
    else
        TEST_RESULTS+=("❌ $test_name: FAILED")
        ((TEST_FAILED++))
        print_color "$RED" "  ❌ $test_name failed"
    fi
}

# Function: Test Expo Doctor
test_expo_doctor() {
    cd "$MOBILE_DIR"
    npx expo-doctor
}

# Function: Test dependencies
test_dependencies() {
    cd "$MOBILE_DIR"
    
    # Check for vulnerabilities
    npm audit --audit-level=high 2>/dev/null
    local audit_result=$?
    
    # Check for critical dependencies
    local critical_deps=("expo" "react-native" "react" "expo-router")
    for dep in "${critical_deps[@]}"; do
        if ! npm list "$dep" >/dev/null 2>&1; then
            return 1
        fi
    done
    
    return $audit_result
}

# Function: Test TypeScript compilation
test_typescript() {
    cd "$MOBILE_DIR"
    if [ -f "tsconfig.json" ]; then
        npx tsc --noEmit
    else
        return 0  # Skip if no TypeScript
    fi
}

# Function: Test assets
test_assets() {
    local required_assets=(
        "$MOBILE_DIR/assets/images/icon.png"
        "$MOBILE_DIR/assets/images/splash-icon.png"
        "$MOBILE_DIR/assets/images/adaptive-icon.png"
        "$MOBILE_DIR/assets/images/favicon.png"
    )
    
    local missing=0
    for asset in "${required_assets[@]}"; do
        if [ ! -f "$asset" ]; then
            print_color "$YELLOW" "    ⚠️  Missing asset: $(basename $asset)"
            missing=$((missing + 1))
        fi
    done
    
    [ $missing -eq 0 ] && return 0 || return 1
}

# Function: Test routing
test_routing() {
    local app_dir="$MOBILE_DIR/app"
    
    if [ ! -d "$app_dir" ]; then
        print_color "$RED" "    App directory not found for Expo Router"
        return 1
    fi
    
    local required_routes=(
        "_layout.tsx"
        "(tabs)/_layout.tsx"
        "(tabs)/index.tsx"
        "(tabs)/explore.tsx"
    )
    
    local missing=0
    for route in "${required_routes[@]}"; do
        if [ ! -f "$app_dir/$route" ]; then
            print_color "$YELLOW" "    ⚠️  Missing route: $route"
            missing=$((missing + 1))
        fi
    done
    
    [ $missing -eq 0 ] && return 0 || return 1
}

# Function: Test EAS configuration
test_eas_config() {
    if [ ! -f "$THERAME_ROOT/eas.json" ]; then
        print_color "$RED" "    eas.json not found"
        return 1
    fi
    
    # Check if EAS is configured properly
    cd "$MOBILE_DIR"
    if jq -e '.build.development' "$THERAME_ROOT/eas.json" >/dev/null && \
       jq -e '.build.preview' "$THERAME_ROOT/eas.json" >/dev/null && \
       jq -e '.build.production' "$THERAME_ROOT/eas.json" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function: Test app.json configuration
test_app_config() {
    if [ ! -f "$MOBILE_DIR/app.json" ]; then
        return 1
    fi
    
    # Check critical fields
    local has_name=$(jq -e '.expo.name' "$MOBILE_DIR/app.json" >/dev/null && echo 1 || echo 0)
    local has_slug=$(jq -e '.expo.slug' "$MOBILE_DIR/app.json" >/dev/null && echo 1 || echo 0)
    local has_version=$(jq -e '.expo.version' "$MOBILE_DIR/app.json" >/dev/null && echo 1 || echo 0)
    local has_android=$(jq -e '.expo.android.package' "$MOBILE_DIR/app.json" >/dev/null && echo 1 || echo 0)
    local has_ios=$(jq -e '.expo.ios.bundleIdentifier' "$MOBILE_DIR/app.json" >/dev/null && echo 1 || echo 0)
    
    if [ "$has_name" = "1" ] && [ "$has_slug" = "1" ] && [ "$has_version" = "1" ] && \
       [ "$has_android" = "1" ] && [ "$has_ios" = "1" ]; then
        return 0
    else
        return 1
    fi
}

# Function: Test Git status
test_git_status() {
    cd "$MOBILE_DIR"
    
    # Check if it's a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi
    
    # Check for uncommitted changes
    local changes=$(git status --porcelain | wc -l)
    if [ $changes -gt 0 ]; then
        print_color "$YELLOW" "    ⚠️  $changes uncommitted changes"
        TEST_WARNINGS=$((TEST_WARNINGS + 1))
    fi
    
    return 0
}

# Function: Test Metro bundler
test_metro() {
    cd "$MOBILE_DIR"
    
    # Check if metro config exists
    if [ -f "metro.config.js" ]; then
        # Try to run metro in check mode
        npx metro get-dependencies app/index.tsx 2>/dev/null
        return $?
    else
        # Create default metro config if missing
        echo "const { getDefaultConfig } = require('expo/metro-config');
module.exports = getDefaultConfig(__dirname);" > metro.config.js
        return 0
    fi
}

# Function: Test environment variables
test_env_vars() {
    local required_vars=()
    local missing=0
    
    # Check for .env file
    if [ -f "$MOBILE_DIR/.env" ]; then
        print_color "$GREEN" "    ✅ .env file exists"
    else
        print_color "$YELLOW" "    ⚠️  No .env file found"
        TEST_WARNINGS=$((TEST_WARNINGS + 1))
    fi
    
    # Check for .env.example
    if [ ! -f "$MOBILE_DIR/.env.example" ]; then
        # Create example env file
        echo "# Example environment variables
# Copy this file to .env and fill in your values

# API Configuration
API_URL=http://localhost:3000
API_KEY=your_api_key_here

# Feature Flags
ENABLE_DEBUG=false
ENABLE_ANALYTICS=false" > "$MOBILE_DIR/.env.example"
    fi
    
    return 0
}

# Function: Test package.json scripts
test_npm_scripts() {
    cd "$MOBILE_DIR"
    
    local required_scripts=("start" "android" "ios" "web")
    local missing=0
    
    for script in "${required_scripts[@]}"; do
        if ! jq -e ".scripts.$script" package.json >/dev/null 2>&1; then
            print_color "$YELLOW" "    ⚠️  Missing script: $script"
            missing=$((missing + 1))
        fi
    done
    
    [ $missing -eq 0 ] && return 0 || return 1
}

# Function: Generate test report
generate_test_report() {
    local report_file="$THERAME_ROOT/test-reports/report_${TIMESTAMP}.txt"
    mkdir -p "$(dirname "$report_file")"
    
    {
        echo "================================"
        echo "theraME Test Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        echo "Summary:"
        echo "  Total Tests: $((TEST_PASSED + TEST_FAILED))"
        echo "  Passed: $TEST_PASSED"
        echo "  Failed: $TEST_FAILED"
        echo "  Warnings: $TEST_WARNINGS"
        echo ""
        echo "Results:"
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
        echo ""
        echo "Recommendations:"
        if [ $TEST_FAILED -gt 0 ]; then
            echo "  - Fix failed tests before building"
        fi
        if [ $TEST_WARNINGS -gt 0 ]; then
            echo "  - Review warnings for potential issues"
        fi
        if [ $TEST_FAILED -eq 0 ] && [ $TEST_WARNINGS -eq 0 ]; then
            echo "  - All tests passed! Ready for build."
        fi
    } > "$report_file"
    
    print_color "$CYAN" "📊 Test report saved to: $report_file"
}

# Function: Quick test (essential tests only)
quick_test() {
    print_color "$CYAN" "Running Quick Tests..."
    run_test "App Configuration" test_app_config
    run_test "EAS Configuration" test_eas_config
    run_test "Dependencies" test_dependencies
    run_test "TypeScript" test_typescript
}

# Function: Full test suite
full_test() {
    print_color "$CYAN" "Running Full Test Suite..."
    run_test "Expo Doctor" test_expo_doctor
    run_test "App Configuration" test_app_config
    run_test "EAS Configuration" test_eas_config
    run_test "Dependencies" test_dependencies
    run_test "TypeScript" test_typescript
    run_test "Assets" test_assets
    run_test "Routing" test_routing
    run_test "Git Status" test_git_status
    run_test "Metro Bundler" test_metro
    run_test "Environment Variables" test_env_vars
    run_test "NPM Scripts" test_npm_scripts
}

# Main test execution
main() {
    print_header
    print_color "$CYAN" "Starting theraME Test Suite"
    print_color "$CYAN" "==========================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Determine test mode
    local mode=${1:-full}
    
    case $mode in
        quick)
            quick_test
            ;;
        full|*)
            full_test
            ;;
    esac
    
    # Generate report
    echo ""
    print_color "$CYAN" "Test Suite Complete"
    print_color "$CYAN" "==================="
    echo ""
    
    # Summary
    local total=$((TEST_PASSED + TEST_FAILED))
    local success_rate=0
    [ $total -gt 0 ] && success_rate=$((TEST_PASSED * 100 / total))
    
    print_color "$GREEN" "✅ Passed: $TEST_PASSED"
    print_color "$RED" "❌ Failed: $TEST_FAILED"
    print_color "$YELLOW" "⚠️  Warnings: $TEST_WARNINGS"
    echo ""
    print_color "$CYAN" "Success Rate: ${success_rate}%"
    
    generate_test_report
    
    # Exit with appropriate code
    [ $TEST_FAILED -eq 0 ] && exit 0 || exit 1
}

# Execute if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi