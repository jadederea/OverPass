# OverPass

A macOS application for relaying keyboard input from a second keyboard to a Parallels guest OS (Windows 11).

## Features

- Intercepts and blocks keystrokes from a designated second keyboard
- Relays keystrokes to Parallels guest OS (even when not active)
- Supports long key presses for gaming (movement, jumping)
- Filters by device/interface to only capture the second keyboard
- Allows all other keyboards to work normally on macOS host
- Timer safeguard to auto-stop capturing/relaying
- Comprehensive logging system with version tracking
- Auto-deploy to Desktop with versioned app names

## Requirements

- macOS 12.0 or later
- Xcode 15.0 or later
- Swift 5.0 or later
- Parallels Desktop with Windows 11 guest OS

## Permissions

The app requires two macOS permissions:
1. **Accessibility** - To intercept keyboard input from the second keyboard
2. **Input Monitoring** - To capture and relay keystrokes to Parallels

These permissions must be granted in System Settings > Privacy & Security.

## Versioning

Version format: `MAJOR.MINOR.PATCH` (e.g., 1.0.0)

- **MAJOR (1)**: First major version for primary needs
- **MINOR (0.#)**: Increments when completing a major milestone/feature
- **PATCH (0.0.#)**: Increments for each test deployment to Desktop

## Building and Deploying

### Automatic Build and Deploy

Run the build script to automatically:
1. Increment the patch version
2. Build the app
3. Deploy to Desktop with versioned name (e.g., `OverPass-v1.0.1.app`)

```bash
cd /Users/mswansegar/OverPass
./build_and_deploy.sh
```

### Manual Build in Xcode

1. Open `OverPass.xcodeproj` in Xcode
2. Select the "OverPass" scheme
3. Build (⌘B) or Run (⌘R)

## Project Structure

```
OverPass/
├── OverPass/
│   ├── OverPassApp.swift      # Main app entry point
│   ├── ContentView.swift      # Main UI view
│   ├── AppVersion.swift       # Version management
│   ├── Logger.swift           # Logging system
│   ├── Info.plist             # App configuration and permissions
│   ├── OverPass.entitlements  # App entitlements
│   └── Assets.xcassets        # App icons and assets
├── OverPass.xcodeproj/        # Xcode project file
├── version.txt                # Current version (managed by build script)
├── build_and_deploy.sh        # Auto-build and deploy script
└── README.md                  # This file
```

## Logging

The app includes a comprehensive logging system:
- All logs include version number
- Logs are stored in memory (last 10,000 entries)
- Download debug logs via the "Download Debug Logs" button in the UI
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL

## Development Standards

- **Incremental Development**: Small, testable changes with frequent builds
- **Frequent Git Commits**: Commit after each verified change
- **Comprehensive Logging**: All operations logged with version tracking
- **Performance Focus**: Code optimized for performance
- **Informative Documentation**: Code comments, commit messages, and logs are detailed for AI agents and developers

## Notes

- The app always opens in maximized window mode
- Version number is displayed in the UI top center
- Version number is included in all log entries
- App name includes version number to avoid macOS permission caching issues
