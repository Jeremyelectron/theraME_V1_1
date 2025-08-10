# theraME Platform Manager - PowerShell Version
# Complete platform management for web, iOS, and Android with Expo EAS

# Configuration
$THERAME_ROOT = "C:\theramev11"
$BACKUP_ROOT = "C:\Users\jerem\source\repos\Jeremyelectron"
$VERSION_FILE = "$THERAME_ROOT\version-matrix.json"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

# Colors
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

# Print header
function Show-Header {
    Write-Host ""
    Write-ColorOutput Cyan "╔════════════════════════════════════════════════════════════╗"
    Write-ColorOutput Cyan "║                  theraME Platform Manager                  ║"
    Write-ColorOutput Cyan "║                      Version 1.1.0                         ║"
    Write-ColorOutput Cyan "╚════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

# Check prerequisites
function Test-Prerequisites {
    Write-ColorOutput Yellow "Checking prerequisites..."
    
    $tools = @("node", "npm", "git", "expo", "eas")
    $missing = @()
    
    foreach ($tool in $tools) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-ColorOutput Red "❌ Missing required tools: $($missing -join ', ')"
        
        foreach ($tool in $missing) {
            switch ($tool) {
                "expo" {
                    Write-ColorOutput Yellow "Installing expo-cli..."
                    npm install -g expo-cli
                }
                "eas" {
                    Write-ColorOutput Yellow "Installing eas-cli..."
                    npm install -g eas-cli
                }
                default {
                    Write-ColorOutput Red "Please install $tool manually"
                }
            }
        }
    } else {
        Write-ColorOutput Green "✅ All prerequisites installed"
    }
}

# Create backup
function New-Backup {
    param([string]$Platform = "all")
    
    $backupDir = "$BACKUP_ROOT\therame_backup_${Platform}_${TIMESTAMP}"
    
    Write-ColorOutput Yellow "📦 Creating backup for: $Platform"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    
    switch ($Platform) {
        "mobile" {
            Copy-Item -Path $THERAME_ROOT -Destination "$backupDir\mobile" -Recurse -Force
        }
        "all" {
            Copy-Item -Path $THERAME_ROOT -Destination "$backupDir\therame_full" -Recurse -Force
            if (Test-Path $VERSION_FILE) {
                Copy-Item -Path $VERSION_FILE -Destination "$backupDir\version-matrix.json"
            }
        }
    }
    
    # Create git bundle
    Push-Location $THERAME_ROOT
    git bundle create "$backupDir\therame_${Platform}.bundle" --all
    Pop-Location
    
    # Create compressed archive
    Compress-Archive -Path $backupDir -DestinationPath "$backupDir.zip" -Force
    
    Write-ColorOutput Green "✅ Backup created: $backupDir.zip"
    "$backupDir" | Out-File "$THERAME_ROOT\.last_backup"
}

# Show status
function Show-Status {
    Show-Header
    Write-ColorOutput Cyan "Platform Status Report"
    Write-ColorOutput Cyan "======================"
    
    # Read version from app.json
    if (Test-Path "$THERAME_ROOT\app.json") {
        $appJson = Get-Content "$THERAME_ROOT\app.json" | ConvertFrom-Json
        $version = $appJson.expo.version
        Write-ColorOutput Green "App Version: $version"
    }
    
    # Check git status
    Write-Host ""
    Write-ColorOutput Yellow "Git Status:"
    Push-Location $THERAME_ROOT
    $branch = git branch --show-current
    $changes = (git status --porcelain | Measure-Object).Count
    Write-Host "  📌 Current branch: $branch"
    Write-Host "  📝 Uncommitted changes: $changes files"
    Pop-Location
    
    # Check EAS status
    Write-Host ""
    Write-ColorOutput Yellow "EAS Status:"
    $easUser = eas whoami 2>$null
    if ($easUser) {
        Write-Host "  ✅ Logged in as: $easUser"
    } else {
        Write-Host "  ❌ Not logged in to EAS"
    }
    
    # Check last backup
    if (Test-Path "$THERAME_ROOT\.last_backup") {
        $lastBackup = Get-Content "$THERAME_ROOT\.last_backup"
        Write-Host ""
        Write-ColorOutput Yellow "Last Backup:"
        Write-Host "  📦 $lastBackup"
    }
}

# Sync versions
function Sync-Versions {
    param([string]$NewVersion)
    
    if (!$NewVersion) {
        $appJson = Get-Content "$THERAME_ROOT\app.json" | ConvertFrom-Json
        $currentVersion = $appJson.expo.version
        $NewVersion = Read-Host "Enter new version (current: $currentVersion)"
    }
    
    Write-ColorOutput Yellow "🔄 Syncing version $NewVersion across all platforms..."
    
    # Backup first
    New-Backup -Platform "all"
    
    # Update app.json
    $appJson = Get-Content "$THERAME_ROOT\app.json" | ConvertFrom-Json
    $appJson.expo.version = $NewVersion
    $appJson | ConvertTo-Json -Depth 10 | Set-Content "$THERAME_ROOT\app.json"
    
    # Update package.json
    $packageJson = Get-Content "$THERAME_ROOT\package.json" | ConvertFrom-Json
    $packageJson.version = $NewVersion
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content "$THERAME_ROOT\package.json"
    
    # Update or create version matrix
    if (!(Test-Path $VERSION_FILE)) {
        $versionMatrix = @{
            versions = @{
                core = $NewVersion
                platforms = @{
                    web = @{ version = "$NewVersion-web" }
                    ios = @{ version = $NewVersion; buildNumber = "1" }
                    android = @{ version = $NewVersion; versionCode = 1 }
                }
            }
            lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        $versionMatrix | ConvertTo-Json -Depth 10 | Set-Content $VERSION_FILE
    } else {
        $versionMatrix = Get-Content $VERSION_FILE | ConvertFrom-Json
        $versionMatrix.versions.core = $NewVersion
        $versionMatrix.versions.platforms.web.version = "$NewVersion-web"
        $versionMatrix.versions.platforms.ios.version = $NewVersion
        $versionMatrix.versions.platforms.android.version = $NewVersion
        $versionMatrix.lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        $versionMatrix | ConvertTo-Json -Depth 10 | Set-Content $VERSION_FILE
    }
    
    Write-ColorOutput Green "✅ Version sync completed for $NewVersion"
}

# Build platform
function Build-Platform {
    param(
        [string]$Platform = "all",
        [string]$Profile = "development"
    )
    
    Write-ColorOutput Yellow "🏗️ Building $Platform for $Profile..."
    
    Push-Location $THERAME_ROOT
    
    switch ($Platform) {
        "web" {
            npx expo export:web
        }
        "ios" {
            eas build --platform ios --profile $Profile
        }
        "android" {
            eas build --platform android --profile $Profile
        }
        "all" {
            Build-Platform -Platform "web" -Profile $Profile
            Build-Platform -Platform "ios" -Profile $Profile
            Build-Platform -Platform "android" -Profile $Profile
        }
        default {
            Write-ColorOutput Red "❌ Unknown platform: $Platform"
        }
    }
    
    Pop-Location
    Write-ColorOutput Green "✅ Build initiated for $Platform"
}

# Test platform
function Test-Platform {
    param([string]$Platform = "all")
    
    Write-ColorOutput Yellow "🧪 Testing $Platform..."
    
    Push-Location $THERAME_ROOT
    
    switch ($Platform) {
        "web" { npx expo start --web }
        "ios" { npx expo start --ios }
        "android" { npx expo start --android }
        "all" { npx expo start }
        default { Write-ColorOutput Red "❌ Unknown platform: $Platform" }
    }
    
    Pop-Location
}

# Main menu
function Show-Menu {
    Show-Header
    Write-Host "Select an option:"
    Write-Host ""
    Write-Host "  1) Show Status"
    Write-Host "  2) Create Backup"
    Write-Host "  3) Sync Versions"
    Write-Host "  4) Build Platform"
    Write-Host "  5) Test Platform"
    Write-Host "  6) Check Prerequisites"
    Write-Host "  7) Git Commit & Push"
    Write-Host "  8) EAS Login"
    Write-Host "  0) Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" { Show-Status }
        "2" {
            $platform = Read-Host "Platform to backup (all/mobile)"
            New-Backup -Platform $platform
        }
        "3" {
            $version = Read-Host "Enter new version (or press enter for prompt)"
            Sync-Versions -NewVersion $version
        }
        "4" {
            $platform = Read-Host "Platform to build (all/web/ios/android)"
            $profile = Read-Host "Build profile (development/preview/production)"
            Build-Platform -Platform $platform -Profile $profile
        }
        "5" {
            $platform = Read-Host "Platform to test (all/web/ios/android)"
            Test-Platform -Platform $platform
        }
        "6" { Test-Prerequisites }
        "7" {
            Push-Location $THERAME_ROOT
            git status
            $confirm = Read-Host "Commit and push? (y/n)"
            if ($confirm -eq "y") {
                git add -A
                $msg = Read-Host "Commit message"
                git commit -m $msg
                git push
            }
            Pop-Location
        }
        "8" { eas login }
        "0" {
            Write-ColorOutput Green "Goodbye!"
            exit
        }
        default { Write-ColorOutput Red "Invalid choice" }
    }
}

# Main execution
if ($args.Count -gt 0) {
    switch ($args[0]) {
        "status" { Show-Status }
        "backup" { New-Backup -Platform $(if($args[1]) {$args[1]} else {"all"}) }
        "sync" { Sync-Versions -NewVersion $args[1] }
        "build" { Build-Platform -Platform $(if($args[1]) {$args[1]} else {"all"}) -Profile $(if($args[2]) {$args[2]} else {"development"}) }
        "test" { Test-Platform -Platform $(if($args[1]) {$args[1]} else {"all"}) }
        default { Show-Menu }
    }
} else {
    while ($true) {
        Show-Menu
        Write-Host ""
        Read-Host "Press enter to continue"
    }
}