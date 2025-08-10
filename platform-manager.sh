#!/bin/bash

# theraME Platform Manager - Main Script
# Complete platform management for web, iOS, and Android with Expo EAS

# Configuration
export THERAME_ROOT="C:/theramev11"
export BACKUP_ROOT="C:/Users/jerem/source/repos/Jeremyelectron"
export WEB_DIR="$THERAME_ROOT/packages/web"
export MOBILE_DIR="$THERAME_ROOT"
export SHARED_DIR="$THERAME_ROOT/packages/shared"
export VERSION_FILE="$THERAME_ROOT/version-matrix.json"
export TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="$THERAME_ROOT/logs/platform_${TIMESTAMP}.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Function: Print colored output
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
    print_color "$CYAN" "║                  theraME Platform Manager                  ║"
    print_color "$CYAN" "║                      Version 1.1.0                         ║"
    print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function: Check prerequisites
check_prerequisites() {
    print_color "$YELLOW" "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    command -v node >/dev/null 2>&1 || missing_tools+=("node")
    command -v npm >/dev/null 2>&1 || missing_tools+=("npm")
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v expo >/dev/null 2>&1 || missing_tools+=("expo")
    command -v eas >/dev/null 2>&1 || missing_tools+=("eas")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_color "$RED" "❌ Missing required tools: ${missing_tools[*]}"
        print_color "$YELLOW" "Installing missing tools..."
        
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "expo")
                    npm install -g expo-cli
                    ;;
                "eas")
                    npm install -g eas-cli
                    ;;
                *)
                    print_color "$RED" "Please install $tool manually"
                    ;;
            esac
        done
    else
        print_color "$GREEN" "✅ All prerequisites installed"
    fi
}

# Function: Create backup
create_backup() {
    local platform=${1:-all}
    local backup_dir="$BACKUP_ROOT/therame_backup_${platform}_${TIMESTAMP}"
    
    print_color "$YELLOW" "📦 Creating backup for: $platform"
    mkdir -p "$backup_dir"
    
    case $platform in
        "web")
            [ -d "$WEB_DIR" ] && cp -r "$WEB_DIR" "$backup_dir/web"
            ;;
        "mobile"|"ios"|"android")
            cp -r "$MOBILE_DIR" "$backup_dir/mobile"
            ;;
        "all")
            cp -r "$THERAME_ROOT" "$backup_dir/therame_full"
            [ -f "$VERSION_FILE" ] && cp "$VERSION_FILE" "$backup_dir/version-matrix.json"
            ;;
    esac
    
    # Create git bundle for version history
    cd "$THERAME_ROOT"
    git bundle create "$backup_dir/therame_${platform}.bundle" --all
    
    # Create compressed archive
    tar -czf "$backup_dir.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"
    
    print_color "$GREEN" "✅ Backup created: $backup_dir.tar.gz"
    echo "$backup_dir" > "$THERAME_ROOT/.last_backup"
}

# Function: Show platform status
show_status() {
    print_header
    print_color "$CYAN" "Platform Status Report"
    print_color "$CYAN" "======================"
    
    # Read version matrix
    if [ -f "$VERSION_FILE" ]; then
        local core_version=$(jq -r '.versions.core' "$VERSION_FILE")
        local web_version=$(jq -r '.versions.platforms.web.version' "$VERSION_FILE")
        local ios_version=$(jq -r '.versions.platforms.ios.version' "$VERSION_FILE")
        local ios_build=$(jq -r '.versions.platforms.ios.buildNumber' "$VERSION_FILE")
        local android_version=$(jq -r '.versions.platforms.android.version' "$VERSION_FILE")
        local android_code=$(jq -r '.versions.platforms.android.versionCode' "$VERSION_FILE")
        
        echo ""
        print_color "$GREEN" "Core Version: $core_version"
        echo ""
        print_color "$YELLOW" "Platform Versions:"
        echo "  📱 iOS:     $ios_version (Build: $ios_build)"
        echo "  🤖 Android: $android_version (Code: $android_code)"
        echo "  🌐 Web:     $web_version"
    else
        print_color "$YELLOW" "Version matrix not found, reading from app.json..."
        if [ -f "$MOBILE_DIR/app.json" ]; then
            local app_version=$(jq -r '.expo.version' "$MOBILE_DIR/app.json")
            print_color "$GREEN" "App Version: $app_version"
        fi
    fi
    
    # Check directory status
    echo ""
    print_color "$YELLOW" "Directory Status:"
    [ -d "$WEB_DIR" ] && echo "  ✅ Web directory exists" || echo "  ⚠️  Web directory not configured"
    [ -d "$MOBILE_DIR" ] && echo "  ✅ Mobile directory exists" || echo "  ❌ Mobile directory missing"
    [ -d "$SHARED_DIR" ] && echo "  ✅ Shared directory exists" || echo "  ⚠️  Shared directory not configured"
    
    # Check git status
    echo ""
    print_color "$YELLOW" "Git Status:"
    cd "$THERAME_ROOT"
    local git_branch=$(git branch --show-current)
    local git_status=$(git status --porcelain | wc -l)
    echo "  📌 Current branch: $git_branch"
    echo "  📝 Uncommitted changes: $git_status files"
    
    # Check EAS status
    echo ""
    print_color "$YELLOW" "EAS Status:"
    eas whoami 2>/dev/null && echo "  ✅ Logged in to EAS" || echo "  ❌ Not logged in to EAS"
    
    # Check last backup
    if [ -f "$THERAME_ROOT/.last_backup" ]; then
        local last_backup=$(cat "$THERAME_ROOT/.last_backup")
        echo ""
        print_color "$YELLOW" "Last Backup:"
        echo "  📦 $last_backup"
    fi
}

# Function: Sync versions across platforms
sync_versions() {
    local new_version=${1:-}
    
    if [ -z "$new_version" ]; then
        # Get current version from app.json
        local current_version=$(jq -r '.expo.version' "$MOBILE_DIR/app.json")
        read -p "Enter new version (current: $current_version): " new_version
    fi
    
    print_color "$YELLOW" "🔄 Syncing version $new_version across all platforms..."
    
    # Create backup first
    create_backup "all"
    
    # Create or update version matrix
    if [ ! -f "$VERSION_FILE" ]; then
        echo '{
  "versions": {
    "core": "'$new_version'",
    "platforms": {
      "web": {
        "version": "'$new_version'-web"
      },
      "ios": {
        "version": "'$new_version'",
        "buildNumber": "1"
      },
      "android": {
        "version": "'$new_version'",
        "versionCode": 1
      }
    }
  },
  "lastUpdated": "'$(date -Iseconds)'"
}' > "$VERSION_FILE"
    else
        jq ".versions.core = \"$new_version\" | 
            .versions.platforms.web.version = \"${new_version}-web\" |
            .versions.platforms.ios.version = \"$new_version\" |
            .versions.platforms.android.version = \"$new_version\" |
            .lastUpdated = \"$(date -Iseconds)\"" \
            "$VERSION_FILE" > "$VERSION_FILE.tmp" && mv "$VERSION_FILE.tmp" "$VERSION_FILE"
    fi
    
    # Update mobile app.json
    if [ -f "$MOBILE_DIR/app.json" ]; then
        jq ".expo.version = \"$new_version\"" \
            "$MOBILE_DIR/app.json" > "$MOBILE_DIR/app.json.tmp" && \
        mv "$MOBILE_DIR/app.json.tmp" "$MOBILE_DIR/app.json"
    fi
    
    # Update package.json in mobile
    if [ -f "$MOBILE_DIR/package.json" ]; then
        jq ".version = \"$new_version\"" "$MOBILE_DIR/package.json" > "$MOBILE_DIR/package.json.tmp" && \
        mv "$MOBILE_DIR/package.json.tmp" "$MOBILE_DIR/package.json"
    fi
    
    print_color "$GREEN" "✅ Version sync completed for $new_version"
}

# Function: Build platform
build_platform() {
    local platform=${1:-all}
    local profile=${2:-development}
    
    print_color "$YELLOW" "🏗️ Building $platform for $profile..."
    
    case $platform in
        "web")
            cd "$MOBILE_DIR"
            npx expo export:web
            ;;
        "ios")
            cd "$MOBILE_DIR"
            eas build --platform ios --profile "$profile"
            ;;
        "android")
            cd "$MOBILE_DIR"
            eas build --platform android --profile "$profile"
            ;;
        "all")
            build_platform "web" "$profile"
            build_platform "ios" "$profile"
            build_platform "android" "$profile"
            ;;
        *)
            print_color "$RED" "❌ Unknown platform: $platform"
            exit 1
            ;;
    esac
    
    print_color "$GREEN" "✅ Build initiated for $platform"
}

# Function: Test platform
test_platform() {
    local platform=${1:-all}
    
    print_color "$YELLOW" "🧪 Testing $platform..."
    
    cd "$MOBILE_DIR"
    
    case $platform in
        "web")
            npx expo start --web
            ;;
        "ios")
            npx expo start --ios
            ;;
        "android")
            npx expo start --android
            ;;
        "all")
            npx expo start
            ;;
        *)
            print_color "$RED" "❌ Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Function: Deploy platform
deploy_platform() {
    local platform=${1:-web}
    local environment=${2:-staging}
    
    print_color "$YELLOW" "🚀 Deploying $platform to $environment..."
    
    # Create backup before deployment
    create_backup "$platform"
    
    case $platform in
        "web")
            cd "$MOBILE_DIR"
            npx expo export:web
            print_color "$GREEN" "Web build exported to web-build/"
            ;;
        "ios")
            cd "$MOBILE_DIR"
            eas submit --platform ios --profile "$environment"
            ;;
        "android")
            cd "$MOBILE_DIR"
            eas submit --platform android --profile "$environment"
            ;;
        *)
            print_color "$RED" "❌ Unknown platform: $platform"
            exit 1
            ;;
    esac
    
    print_color "$GREEN" "✅ Deployment initiated for $platform"
}

# Main menu
show_menu() {
    print_header
    echo "Select an option:"
    echo ""
    echo "  1) Show Status"
    echo "  2) Create Backup"
    echo "  3) Sync Versions"
    echo "  4) Build Platform"
    echo "  5) Test Platform"
    echo "  6) Deploy Platform"
    echo "  7) Check Prerequisites"
    echo "  8) Git Operations"
    echo "  9) EAS Login"
    echo "  0) Exit"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) show_status ;;
        2) 
            read -p "Platform to backup (all/web/mobile): " platform
            create_backup "$platform"
            ;;
        3) 
            read -p "Enter new version (or press enter to be prompted): " version
            sync_versions "$version"
            ;;
        4)
            read -p "Platform to build (all/web/ios/android): " platform
            read -p "Build profile (development/preview/production): " profile
            build_platform "$platform" "$profile"
            ;;
        5)
            read -p "Platform to test (all/web/ios/android): " platform
            test_platform "$platform"
            ;;
        6)
            read -p "Platform to deploy (web/ios/android): " platform
            read -p "Environment (staging/production): " environment
            deploy_platform "$platform" "$environment"
            ;;
        7)
            check_prerequisites
            ;;
        8)
            cd "$THERAME_ROOT"
            git status
            read -p "Commit and push? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                git add -A
                read -p "Commit message: " msg
                git commit -m "$msg"
                git push
            fi
            ;;
        9)
            eas login
            ;;
        0)
            print_color "$GREEN" "Goodbye!"
            exit 0
            ;;
        *)
            print_color "$RED" "Invalid choice"
            ;;
    esac
}

# Parse command line arguments
case "${1:-menu}" in
    "status")
        show_status
        ;;
    "backup")
        create_backup "${2:-all}"
        ;;
    "sync")
        sync_versions "$2"
        ;;
    "build")
        build_platform "${2:-all}" "${3:-development}"
        ;;
    "deploy")
        deploy_platform "${2:-web}" "${3:-staging}"
        ;;
    "test")
        test_platform "${2:-all}"
        ;;
    "menu"|*)
        while true; do
            show_menu
            echo ""
            read -p "Press enter to continue..."
        done
        ;;
esac