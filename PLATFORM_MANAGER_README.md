# theraME Platform Manager

## Overview
The theraME Platform Manager is a comprehensive automation tool for managing your Expo/React Native application across multiple platforms (iOS, Android, and Web).

## Features

### 🚀 Core Features
- **Multi-platform Build Management**: Build for iOS, Android, and Web from a single interface
- **Version Synchronization**: Keep versions consistent across all platforms
- **Automated Backups**: Create timestamped backups before critical operations
- **EAS Integration**: Full integration with Expo Application Services
- **Git Integration**: Commit and push changes directly from the manager
- **Status Monitoring**: Real-time status of your project and builds

## Installation

### Prerequisites
- Node.js (v18 or higher)
- Git
- Expo CLI
- EAS CLI

### Setup
1. Install required tools:
```bash
npm install -g expo-cli eas-cli
```

2. Login to EAS:
```bash
eas login
```

## Usage

### Windows PowerShell (Recommended)
```powershell
# Run the PowerShell version
.\platform-manager.ps1

# Or with specific commands
.\platform-manager.ps1 status
.\platform-manager.ps1 build android preview
.\platform-manager.ps1 sync 1.1.0
```

### Windows Batch File
```cmd
# Double-click platform-manager.bat or run:
platform-manager.bat
```

### Git Bash / WSL
```bash
# Run the bash version
bash platform-manager.sh

# Or with specific commands
bash platform-manager.sh status
bash platform-manager.sh build android preview
bash platform-manager.sh sync 1.1.0
```

## Commands

### Interactive Menu
Run without arguments to access the interactive menu:
```bash
.\platform-manager.ps1
```

### Direct Commands

#### Show Status
```bash
.\platform-manager.ps1 status
```
Displays:
- Current version information
- Git branch and changes
- EAS login status
- Last backup information

#### Create Backup
```bash
.\platform-manager.ps1 backup [all|mobile|web]
```
Creates a timestamped backup with git bundle.

#### Sync Versions
```bash
.\platform-manager.ps1 sync [version]
```
Synchronizes version across all configuration files.

#### Build Platform
```bash
.\platform-manager.ps1 build [platform] [profile]

# Examples:
.\platform-manager.ps1 build android development
.\platform-manager.ps1 build ios preview
.\platform-manager.ps1 build all production
```

#### Test Platform
```bash
.\platform-manager.ps1 test [platform]

# Examples:
.\platform-manager.ps1 test android
.\platform-manager.ps1 test web
.\platform-manager.ps1 test all
```

## Configuration

### Version Matrix (version-matrix.json)
Tracks versions and build numbers across platforms:
```json
{
  "versions": {
    "core": "1.0.0",
    "platforms": {
      "ios": {
        "version": "1.0.0",
        "buildNumber": "1"
      },
      "android": {
        "version": "1.0.0",
        "versionCode": 1
      },
      "web": {
        "version": "1.0.0-web"
      }
    }
  }
}
```

### Directory Structure
```
theramev11/
├── platform-manager.ps1      # PowerShell version
├── platform-manager.sh        # Bash version
├── platform-manager.bat       # Windows batch launcher
├── version-matrix.json        # Version tracking
├── app.json                  # Expo configuration
├── eas.json                  # EAS build configuration
├── package.json              # Node.js dependencies
└── logs/                     # Platform manager logs
```

## Build Profiles

### Development
- Internal distribution
- Development client
- Debug features enabled

### Preview
- Internal distribution
- Standalone APK/IPA
- Testing features

### Production
- Store distribution
- Optimized build
- Production APIs

## Backup Strategy

Backups are created automatically before:
- Version updates
- Platform deployments
- Major configuration changes

Backup location: `C:\Users\jerem\source\repos\Jeremyelectron\`

Each backup includes:
- Complete project snapshot
- Git bundle with history
- Compressed archive (.zip or .tar.gz)

## Troubleshooting

### Common Issues

#### "EAS not logged in"
```bash
eas login
```

#### "Missing prerequisites"
The manager will attempt to install missing tools automatically.

#### "Build failed"
Check:
1. EAS login status: `eas whoami`
2. Git status: `git status`
3. Build configuration: `eas.json`

### Logs
Platform manager logs are stored in: `theramev11/logs/`

## Advanced Usage

### Automated CI/CD
```powershell
# Automated version bump and build
.\platform-manager.ps1 sync 1.2.0
.\platform-manager.ps1 build all production
```

### Batch Operations
```powershell
# Full release cycle
.\platform-manager.ps1 backup all
.\platform-manager.ps1 sync 2.0.0
.\platform-manager.ps1 build all production
```

## Support

For issues or questions:
- GitHub: https://github.com/Jeremyelectron/theraME_V1_1
- EAS Dashboard: https://expo.dev/accounts/jeremyelectron/projects/theramev11

## License
Copyright (c) 2024 theraME. All rights reserved.