#!/bin/bash

# theraME Environment Setup - Complete environment configuration

# Source the base platform configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../therame-platform.sh" 2>/dev/null || {
    # Fallback if therame-platform.sh doesn't exist
    THERAME_ROOT="C:/theramev11"
    MOBILE_DIR="$THERAME_ROOT"
    WEB_DIR="$THERAME_ROOT/web-build"
    BACKUP_ROOT="C:/Users/jerem/source/repos/Jeremyelectron"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
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
        print_color "$CYAN" "║              theraME Environment Setup                     ║"
        print_color "$CYAN" "║                    Version 1.1.0                           ║"
        print_color "$CYAN" "╚════════════════════════════════════════════════════════════╝"
        echo ""
    }
    
    confirm_action() {
        local message=${1:-"Continue?"}
        read -p "$message (y/n): " confirm
        [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]
    }
}

# Function: Check and install Node.js
setup_node() {
    print_color "$YELLOW" "Checking Node.js..."
    
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        print_color "$GREEN" "✅ Node.js installed: $node_version"
        
        # Check if version is sufficient (v18+)
        local major_version=$(echo $node_version | cut -d. -f1 | sed 's/v//')
        if [ $major_version -lt 18 ]; then
            print_color "$YELLOW" "⚠️  Node.js version should be 18 or higher"
            print_color "$YELLOW" "   Please update Node.js: https://nodejs.org"
        fi
    else
        print_color "$RED" "❌ Node.js not installed"
        print_color "$YELLOW" "   Please install from: https://nodejs.org"
        return 1
    fi
}

# Function: Install global packages
install_global_packages() {
    print_color "$YELLOW" "Installing global packages..."
    
    local packages=("expo-cli" "eas-cli" "typescript" "npm-check-updates")
    
    for package in "${packages[@]}"; do
        print_color "$YELLOW" "Installing $package..."
        npm install -g $package
    done
    
    print_color "$GREEN" "✅ Global packages installed"
}

# Function: Setup project dependencies
setup_dependencies() {
    print_color "$YELLOW" "Setting up project dependencies..."
    
    cd "$MOBILE_DIR"
    
    # Clean install
    if [ -f "package-lock.json" ]; then
        print_color "$YELLOW" "Removing old lock file..."
        rm package-lock.json
    fi
    
    print_color "$YELLOW" "Installing dependencies..."
    npm install
    
    # Install additional dev dependencies
    print_color "$YELLOW" "Installing dev dependencies..."
    npm install --save-dev \
        @types/react \
        @types/react-native \
        prettier \
        eslint \
        @typescript-eslint/parser \
        @typescript-eslint/eslint-plugin
    
    print_color "$GREEN" "✅ Dependencies installed"
}

# Function: Setup environment files
setup_env_files() {
    print_color "$YELLOW" "Setting up environment files..."
    
    cd "$MOBILE_DIR"
    
    # Create .env.example if not exists
    if [ ! -f ".env.example" ]; then
        cat > .env.example << 'EOF'
# Environment Variables
# Copy this file to .env and configure your values

# API Configuration
API_URL=http://localhost:3000
API_KEY=your_api_key_here

# Expo Configuration
EXPO_PUBLIC_API_URL=http://localhost:3000

# Feature Flags
ENABLE_DEBUG=true
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false

# Third-party Services
SENTRY_DSN=
GOOGLE_MAPS_API_KEY=
FIREBASE_CONFIG=
EOF
        print_color "$GREEN" "✅ Created .env.example"
    fi
    
    # Create .env if not exists
    if [ ! -f ".env" ]; then
        cp .env.example .env
        print_color "$GREEN" "✅ Created .env from template"
        print_color "$YELLOW" "   Please configure your .env file"
    fi
    
    # Add .env to .gitignore
    if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
        print_color "$GREEN" "✅ Added .env to .gitignore"
    fi
}

# Function: Setup Git hooks
setup_git_hooks() {
    print_color "$YELLOW" "Setting up Git hooks..."
    
    cd "$MOBILE_DIR"
    
    # Create hooks directory
    mkdir -p .git/hooks
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for theraME

echo "Running pre-commit checks..."

# Run tests
npm test -- --watchAll=false

# Run linting
npm run lint

# Check TypeScript
npx tsc --noEmit

if [ $? -ne 0 ]; then
    echo "Pre-commit checks failed. Please fix errors before committing."
    exit 1
fi

echo "Pre-commit checks passed!"
EOF
    
    chmod +x .git/hooks/pre-commit
    print_color "$GREEN" "✅ Git hooks configured"
}

# Function: Setup VS Code settings
setup_vscode() {
    print_color "$YELLOW" "Setting up VS Code configuration..."
    
    cd "$MOBILE_DIR"
    mkdir -p .vscode
    
    # VS Code settings
    cat > .vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/.expo": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true,
    "**/dist": true,
    "**/build": true
  }
}
EOF
    
    # VS Code extensions recommendations
    cat > .vscode/extensions.json << 'EOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-tslint-plugin",
    "expo.vscode-expo-tools",
    "msjsdiag.vscode-react-native"
  ]
}
EOF
    
    print_color "$GREEN" "✅ VS Code configuration created"
}

# Function: Setup ESLint
setup_eslint() {
    print_color "$YELLOW" "Setting up ESLint..."
    
    cd "$MOBILE_DIR"
    
    # Create .eslintrc.js if not exists
    if [ ! -f ".eslintrc.js" ] && [ ! -f "eslint.config.js" ]; then
        cat > .eslintrc.js << 'EOF'
module.exports = {
  root: true,
  extends: [
    'expo',
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    'no-console': 'warn',
    '@typescript-eslint/no-unused-vars': 'warn',
    '@typescript-eslint/no-explicit-any': 'warn',
  },
};
EOF
        print_color "$GREEN" "✅ ESLint configuration created"
    fi
}

# Function: Setup Prettier
setup_prettier() {
    print_color "$YELLOW" "Setting up Prettier..."
    
    cd "$MOBILE_DIR"
    
    # Create .prettierrc if not exists
    if [ ! -f ".prettierrc" ] && [ ! -f ".prettierrc.json" ]; then
        cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "jsxBracketSameLine": false,
  "arrowParens": "always"
}
EOF
        print_color "$GREEN" "✅ Prettier configuration created"
    fi
    
    # Create .prettierignore
    cat > .prettierignore << 'EOF'
node_modules/
.expo/
dist/
build/
*.min.js
*.bundle.js
coverage/
EOF
}

# Function: Setup directory structure
setup_directories() {
    print_color "$YELLOW" "Setting up directory structure..."
    
    cd "$MOBILE_DIR"
    
    # Create necessary directories
    local dirs=(
        "src/components"
        "src/screens"
        "src/navigation"
        "src/services"
        "src/utils"
        "src/hooks"
        "src/context"
        "src/types"
        "assets/fonts"
        "assets/images"
        "assets/animations"
        "config"
        "tests"
        "docs"
        "scripts"
        "logs"
        "test-reports"
        "debug-reports"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        print_color "$GREEN" "  ✅ Created $dir"
    done
}

# Function: Initialize EAS
setup_eas() {
    print_color "$YELLOW" "Setting up EAS..."
    
    cd "$MOBILE_DIR"
    
    # Check if logged in
    if eas whoami >/dev/null 2>&1; then
        print_color "$GREEN" "✅ Already logged in to EAS"
        
        # Initialize if not already done
        if [ ! -f "eas.json" ]; then
            eas init --id $(uuidgen 2>/dev/null || echo "auto")
        fi
    else
        print_color "$YELLOW" "Please log in to EAS:"
        print_color "$YELLOW" "Run: eas login"
    fi
}

# Function: Verify setup
verify_setup() {
    print_color "$CYAN" "Verifying Setup"
    print_color "$CYAN" "==============="
    
    local issues=0
    
    # Check Node
    command -v node >/dev/null 2>&1 && echo "✅ Node.js" || { echo "❌ Node.js"; ((issues++)); }
    
    # Check NPM
    command -v npm >/dev/null 2>&1 && echo "✅ NPM" || { echo "❌ NPM"; ((issues++)); }
    
    # Check Expo
    command -v expo >/dev/null 2>&1 && echo "✅ Expo CLI" || { echo "❌ Expo CLI"; ((issues++)); }
    
    # Check EAS
    command -v eas >/dev/null 2>&1 && echo "✅ EAS CLI" || { echo "❌ EAS CLI"; ((issues++)); }
    
    # Check files
    [ -f "$MOBILE_DIR/package.json" ] && echo "✅ package.json" || { echo "❌ package.json"; ((issues++)); }
    [ -f "$MOBILE_DIR/app.json" ] && echo "✅ app.json" || { echo "❌ app.json"; ((issues++)); }
    [ -f "$MOBILE_DIR/eas.json" ] && echo "✅ eas.json" || { echo "❌ eas.json"; ((issues++)); }
    [ -d "$MOBILE_DIR/node_modules" ] && echo "✅ node_modules" || { echo "❌ node_modules"; ((issues++)); }
    
    echo ""
    if [ $issues -eq 0 ]; then
        print_color "$GREEN" "✅ Setup verification passed!"
    else
        print_color "$YELLOW" "⚠️  Found $issues issues. Please run setup again."
    fi
}

# Main setup flow
main() {
    print_header
    
    local mode=${1:-full}
    
    case $mode in
        quick)
            setup_node
            setup_dependencies
            verify_setup
            ;;
        full)
            setup_node
            install_global_packages
            setup_dependencies
            setup_env_files
            setup_directories
            setup_vscode
            setup_eslint
            setup_prettier
            setup_git_hooks
            setup_eas
            verify_setup
            ;;
        verify)
            verify_setup
            ;;
        *)
            print_color "$YELLOW" "Usage: $0 [quick|full|verify]"
            print_color "$YELLOW" "  quick  - Quick setup (dependencies only)"
            print_color "$YELLOW" "  full   - Full setup (all configurations)"
            print_color "$YELLOW" "  verify - Verify current setup"
            ;;
    esac
    
    echo ""
    print_color "$CYAN" "Setup Complete!"
    print_color "$CYAN" "Next steps:"
    echo "  1. Configure your .env file"
    echo "  2. Log in to EAS: eas login"
    echo "  3. Run tests: bash scripts/test-suite.sh"
    echo "  4. Start development: npm start"
}

# Execute
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi