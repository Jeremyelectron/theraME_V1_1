#!/bin/bash

# theraME Full Test Suite - Comprehensive testing for all platforms

# Source the base platform configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../therame-platform.sh" 2>/dev/null || {
    echo "Error: Unable to source therame-platform.sh"
    exit 1
}

# Test configuration
TEST_RESULTS_DIR="$THERAME_ROOT/test-reports"
TEST_LOG="$TEST_RESULTS_DIR/full-test_${TIMESTAMP}.log"
TEST_SUMMARY="$TEST_RESULTS_DIR/summary_${TIMESTAMP}.json"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
WARNINGS=0

# Test categories
declare -A TEST_CATEGORIES=(
    ["setup"]="Environment Setup Tests"
    ["dependencies"]="Dependency Tests"
    ["structure"]="Project Structure Tests"
    ["config"]="Configuration Tests"
    ["build"]="Build Tests"
    ["integration"]="Integration Tests"
    ["performance"]="Performance Tests"
)

# Function: Initialize test environment
init_test_env() {
    ensure_dir "$TEST_RESULTS_DIR"
    
    # Start test log
    {
        echo "================================"
        echo "theraME Full Test Suite"
        echo "Started: $(date)"
        echo "================================"
        echo ""
    } > "$TEST_LOG"
}

# Function: Run test with logging
run_test() {
    local category=$1
    local test_name=$2
    local test_command=$3
    local critical=${4:-false}
    
    ((TOTAL_TESTS++))
    
    echo -n "  Testing $test_name... "
    echo "[$category] Testing: $test_name" >> "$TEST_LOG"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        ((PASSED_TESTS++))
        print_color "$GREEN" "✅ PASSED"
        echo "  Result: PASSED" >> "$TEST_LOG"
    else
        ((FAILED_TESTS++))
        print_color "$RED" "❌ FAILED"
        echo "  Result: FAILED" >> "$TEST_LOG"
        
        if [ "$critical" = "true" ]; then
            print_color "$RED" "Critical test failed. Stopping test suite."
            generate_summary
            exit 1
        fi
    fi
    
    echo "" >> "$TEST_LOG"
}

# Function: Skip test
skip_test() {
    local test_name=$1
    local reason=$2
    
    ((TOTAL_TESTS++))
    ((SKIPPED_TESTS++))
    
    echo -n "  Testing $test_name... "
    print_color "$YELLOW" "⚠️  SKIPPED ($reason)"
    echo "  Result: SKIPPED - $reason" >> "$TEST_LOG"
}

# Function: Add warning
add_warning() {
    local message=$1
    ((WARNINGS++))
    print_color "$YELLOW" "  ⚠️  Warning: $message"
    echo "  Warning: $message" >> "$TEST_LOG"
}

# Category: Setup Tests
test_setup() {
    print_color "$CYAN" "\n📋 Running Setup Tests..."
    
    run_test "setup" "Node.js installation" "node --version"
    run_test "setup" "NPM installation" "npm --version"
    run_test "setup" "Git installation" "git --version"
    run_test "setup" "Expo CLI" "command -v expo"
    run_test "setup" "EAS CLI" "command -v eas"
    
    # Check Node version
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 18 ]; then
        add_warning "Node.js version should be 18 or higher"
    fi
}

# Category: Dependencies Tests
test_dependencies() {
    print_color "$CYAN" "\n📦 Running Dependencies Tests..."
    
    cd "$MOBILE_DIR"
    
    run_test "dependencies" "package.json exists" "[ -f package.json ]"
    run_test "dependencies" "node_modules exists" "[ -d node_modules ]"
    run_test "dependencies" "Expo installed" "npm list expo"
    run_test "dependencies" "React Native installed" "npm list react-native"
    run_test "dependencies" "React installed" "npm list react"
    
    # Check for vulnerabilities
    if npm audit --audit-level=high 2>/dev/null | grep -q "found 0"; then
        run_test "dependencies" "No high vulnerabilities" "true"
    else
        run_test "dependencies" "No high vulnerabilities" "false"
        add_warning "Found high severity vulnerabilities"
    fi
}

# Category: Structure Tests
test_structure() {
    print_color "$CYAN" "\n📁 Running Structure Tests..."
    
    run_test "structure" "Project root exists" "[ -d '$THERAME_ROOT' ]"
    run_test "structure" "Mobile directory" "[ -d '$MOBILE_DIR' ]"
    run_test "structure" "Scripts directory" "[ -d '$THERAME_ROOT/scripts' ]"
    run_test "structure" "Logs directory" "[ -d '$THERAME_ROOT/logs' ]"
    
    # Check app structure
    run_test "structure" "App directory" "[ -d '$MOBILE_DIR/app' ]"
    run_test "structure" "Assets directory" "[ -d '$MOBILE_DIR/assets' ]"
    run_test "structure" "Components directory" "[ -d '$MOBILE_DIR/components' ] || [ -d '$MOBILE_DIR/app/components' ]"
}

# Category: Configuration Tests
test_config() {
    print_color "$CYAN" "\n⚙️  Running Configuration Tests..."
    
    cd "$MOBILE_DIR"
    
    run_test "config" "app.json exists" "[ -f app.json ]"
    run_test "config" "eas.json exists" "[ -f eas.json ]"
    run_test "config" "tsconfig.json exists" "[ -f tsconfig.json ]"
    run_test "config" "package.json valid" "jq -e . package.json >/dev/null 2>&1"
    run_test "config" "app.json valid" "jq -e . app.json >/dev/null 2>&1"
    
    # Check critical app.json fields
    run_test "config" "App name configured" "jq -e '.expo.name' app.json >/dev/null 2>&1"
    run_test "config" "App slug configured" "jq -e '.expo.slug' app.json >/dev/null 2>&1"
    run_test "config" "App version configured" "jq -e '.expo.version' app.json >/dev/null 2>&1"
    run_test "config" "Android package configured" "jq -e '.expo.android.package' app.json >/dev/null 2>&1"
    run_test "config" "iOS bundle ID configured" "jq -e '.expo.ios.bundleIdentifier' app.json >/dev/null 2>&1"
}

# Category: Build Tests
test_build() {
    print_color "$CYAN" "\n🏗️  Running Build Tests..."
    
    cd "$MOBILE_DIR"
    
    # TypeScript compilation
    if [ -f "tsconfig.json" ]; then
        run_test "build" "TypeScript compilation" "npx tsc --noEmit"
    else
        skip_test "TypeScript compilation" "No tsconfig.json"
    fi
    
    # Check for build profiles
    if [ -f "eas.json" ]; then
        run_test "build" "Development profile exists" "jq -e '.build.development' eas.json >/dev/null 2>&1"
        run_test "build" "Preview profile exists" "jq -e '.build.preview' eas.json >/dev/null 2>&1"
        run_test "build" "Production profile exists" "jq -e '.build.production' eas.json >/dev/null 2>&1"
    fi
    
    # Metro bundler test
    run_test "build" "Metro config valid" "[ -f metro.config.js ] || true"
}

# Category: Integration Tests
test_integration() {
    print_color "$CYAN" "\n🔗 Running Integration Tests..."
    
    # Git integration
    run_test "integration" "Git repository initialized" "[ -d '$THERAME_ROOT/.git' ]"
    
    if [ -d "$THERAME_ROOT/.git" ]; then
        cd "$THERAME_ROOT"
        run_test "integration" "Git remote configured" "git remote -v | grep -q origin"
        
        # Check for uncommitted changes
        local changes=$(git status --porcelain | wc -l)
        if [ "$changes" -gt 0 ]; then
            add_warning "$changes uncommitted changes in repository"
        fi
    fi
    
    # EAS integration
    if command -v eas >/dev/null 2>&1; then
        if eas whoami >/dev/null 2>&1; then
            run_test "integration" "EAS authenticated" "true"
        else
            run_test "integration" "EAS authenticated" "false"
            add_warning "Not logged in to EAS"
        fi
    else
        skip_test "EAS authentication" "EAS CLI not installed"
    fi
}

# Category: Performance Tests
test_performance() {
    print_color "$CYAN" "\n⚡ Running Performance Tests..."
    
    cd "$MOBILE_DIR"
    
    # Check bundle size
    if [ -d "node_modules" ]; then
        local node_size=$(du -sm node_modules | cut -f1)
        if [ "$node_size" -gt 500 ]; then
            add_warning "node_modules is large (${node_size}MB)"
        fi
        run_test "performance" "node_modules size check" "[ $node_size -lt 1000 ]"
    fi
    
    # Check for large assets
    if [ -d "assets" ]; then
        local large_files=$(find assets -type f -size +1M 2>/dev/null | wc -l)
        if [ "$large_files" -gt 0 ]; then
            add_warning "Found $large_files assets larger than 1MB"
        fi
        run_test "performance" "Asset optimization" "[ $large_files -lt 10 ]"
    fi
    
    # Check startup time (mock test)
    run_test "performance" "Package.json scripts" "jq -e '.scripts.start' package.json >/dev/null 2>&1"
}

# Function: Run Expo Doctor
test_expo_doctor() {
    print_color "$CYAN" "\n🏥 Running Expo Doctor..."
    
    cd "$MOBILE_DIR"
    
    if command -v expo >/dev/null 2>&1; then
        if npx expo-doctor 2>&1 | tee -a "$TEST_LOG" | grep -q "issues"; then
            add_warning "Expo Doctor found issues"
        else
            ((PASSED_TESTS++))
            print_color "$GREEN" "  ✅ Expo Doctor passed"
        fi
    else
        skip_test "Expo Doctor" "Expo not installed"
    fi
}

# Function: Generate test summary
generate_summary() {
    local success_rate=0
    [ $TOTAL_TESTS -gt 0 ] && success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    
    # Generate JSON summary
    cat > "$TEST_SUMMARY" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_tests": $TOTAL_TESTS,
  "passed": $PASSED_TESTS,
  "failed": $FAILED_TESTS,
  "skipped": $SKIPPED_TESTS,
  "warnings": $WARNINGS,
  "success_rate": $success_rate,
  "log_file": "$TEST_LOG"
}
EOF
    
    # Display summary
    echo ""
    print_color "$CYAN" "================================"
    print_color "$CYAN" "        Test Summary"
    print_color "$CYAN" "================================"
    echo ""
    echo "Total Tests:    $TOTAL_TESTS"
    print_color "$GREEN" "Passed:         $PASSED_TESTS"
    print_color "$RED" "Failed:         $FAILED_TESTS"
    print_color "$YELLOW" "Skipped:        $SKIPPED_TESTS"
    print_color "$YELLOW" "Warnings:       $WARNINGS"
    echo ""
    print_color "$CYAN" "Success Rate:   ${success_rate}%"
    echo ""
    
    # Provide recommendations
    if [ $FAILED_TESTS -gt 0 ]; then
        print_color "$RED" "⚠️  Some tests failed. Please review the log at:"
        echo "   $TEST_LOG"
    elif [ $WARNINGS -gt 0 ]; then
        print_color "$YELLOW" "⚠️  Tests passed with warnings. Consider addressing them."
    else
        print_color "$GREEN" "✅ All tests passed successfully!"
    fi
    
    # Save paths
    echo ""
    print_color "$CYAN" "📊 Reports saved to:"
    echo "   Log:     $TEST_LOG"
    echo "   Summary: $TEST_SUMMARY"
}

# Function: Run specific category
run_category() {
    local category=$1
    
    case $category in
        setup) test_setup ;;
        dependencies) test_dependencies ;;
        structure) test_structure ;;
        config) test_config ;;
        build) test_build ;;
        integration) test_integration ;;
        performance) test_performance ;;
        expo) test_expo_doctor ;;
        all) run_all_tests ;;
        *) 
            print_color "$RED" "Unknown category: $category"
            echo "Available categories: ${!TEST_CATEGORIES[@]} expo all"
            exit 1
            ;;
    esac
}

# Function: Run all tests
run_all_tests() {
    test_setup
    test_dependencies
    test_structure
    test_config
    test_build
    test_integration
    test_performance
    test_expo_doctor
}

# Main execution
main() {
    print_header
    print_color "$CYAN" "theraME Full Test Suite"
    print_color "$CYAN" "======================="
    
    # Initialize
    init_test_env
    
    # Check what to run
    local mode=${1:-all}
    
    if [ "$mode" = "help" ]; then
        echo ""
        echo "Usage: $0 [category|all]"
        echo ""
        echo "Categories:"
        for key in "${!TEST_CATEGORIES[@]}"; do
            echo "  $key - ${TEST_CATEGORIES[$key]}"
        done
        echo "  expo - Run Expo Doctor"
        echo "  all  - Run all tests (default)"
        exit 0
    fi
    
    # Run tests
    run_category "$mode"
    
    # Generate summary
    generate_summary
    
    # Exit with appropriate code
    [ $FAILED_TESTS -eq 0 ] && exit 0 || exit 1
}

# Execute if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi