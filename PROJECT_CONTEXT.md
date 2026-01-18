# OverPass Project Context & Progress Tracking

**Last Updated**: 2026-01-18  
**Current Version**: 1.0.28  
**Project Status**: UI Complete - Ready for Backend Functionality Port

---

## Working Agreement & Guardrails

### How We Work Together
- **User Role**: Product Owner / Agile Coach with QA experience, not a developer
- **Xcode Experience**: Limited - prefer agent handles Xcode tasks when possible
- **Development Approach**: 
  - Small, incremental changes
  - Frequent builds and deployments for testing
  - Heavy reliance on logging for debugging
  - Break down large features into testable pieces
  - Allow rollback if something goes wrong

### Communication Preferences
- Ask questions if context is needed
- Automate as much as possible
- Keep things simple but correct
- Provide clear guidance when Xcode interaction is required

---

## Project Intent

### Business Problem
- macOS host with Parallels Desktop running Windows 11 guest OS
- Game in Windows 11 requires arrow keys/WASD to be held down for continuous character movement
- Need to use a second keyboard connected to Mac
- Intercept keys from second keyboard ONLY
- Relay intercepted keys to Parallels guest OS (even when not in focus)
- Block second keyboard from sending keys to macOS host
- Allow all other input devices (main keyboard) to work normally on macOS host

### Key Requirements
1. **Permissions**: 
   - Accessibility permission (intercept keyboard input)
   - Input Monitoring permission (capture and relay keystrokes)
   - UI should show permission status
   - Log when app closes/opens (Input Monitoring requires restart)

2. **Keyboard Detection**:
   - Detect keyboard by key press (not pre-selection)
   - Handle keyboards with multiple interfaces (some detected twice)
   - Identify keyboard and its interface(s)

3. **Key Relay**:
   - Intercept keys from second keyboard
   - Block keys from reaching macOS host
   - Relay to Parallels guest OS (background, not in focus)
   - Support long key presses (not errors/duplicates)
   - Handle performance/lag issues (previously fixed in old codebase)

4. **Safeguards**:
   - Configurable timer (default 5 minutes, configurable in seconds)
   - Auto-stop capturing/relaying when timer expires
   - Prevents being stuck if all keyboard input is blocked

5. **Versioning**:
   - Format: MAJOR.MINOR.PATCH (e.g., 1.0.28)
   - MAJOR: First deployment or major milestones
   - MINOR: Feature completions
   - PATCH: Each test build/deployment
   - Version displayed top center in UI
   - Version in all log entries
   - Version in app name for deployments (avoid permission caching)

6. **Logging**:
   - Comprehensive logging throughout
   - "Copy Debug Logs" button in UI (copies to clipboard)
   - Version number in all log entries
   - Log app close/open events
   - Temporary confirmation message "Logs copied to clipboard" appears next to button

---

## Completed Tasks ✅

### Foundation Setup
- [x] Created OverPass Xcode project in Cursor
- [x] Set up basic app structure (OverPassApp, ContentView, Logger, AppVersion)
- [x] Created build_and_deploy.sh script
  - Auto-increments patch version
  - Builds app
  - Deploys to Desktop with versioned name (OverPass-v1.0.X.app)
  - Captures and displays build warnings/errors
  - Saves build logs to Desktop/xCode Build Logs/ with timestamps
  - Updates version in Info.plist
  - Keeps last 3 versions on Desktop
  - Handles code signing (automatic with fallback to ad-hoc)
  - Re-signs app after Info.plist and version.txt modifications
- [x] Version management system (AppVersion.swift, version.txt)
- [x] Logging system (Logger.swift) with version tracking
- [x] Version display in UI (top center)
- [x] Copy Debug Logs button in UI (copies to clipboard, shows temporary confirmation)
- [x] App window maximization on launch
- [x] Info.plist configured with permission descriptions
- [x] OverPass.entitlements configured:
  - App sandbox disabled
  - USB device access
  - Input Monitoring permission
  - Accessibility permission
  - Hardened runtime enabled
- [x] Code signing set to Automatic (with development team configured)
- [x] Build logs saved to Desktop/xCode Build Logs folder

### Permissions System
- [x] PermissionManager.swift created
  - Checks Accessibility permission (AXIsProcessTrustedWithOptions)
  - Checks Input Monitoring permission (CGEvent.tapCreate test)
  - Requests permissions with System Settings integration
  - ObservableObject for UI updates
- [x] Permission status displayed in UI
- [x] Permission requests on app launch
- [x] Permission status logging

### UI Implementation (Figma Design Conversion)
- [x] **AppState.swift** - Navigation and state management
  - Manages screen flow (permissions → detection → confirmation → control panel)
  - Stores detected keyboard information
- [x] **PermissionsScreenView.swift** - Initial permissions screen
  - Dark theme matching Figma design
  - Instructions for granting permissions
  - "Open System Settings" and "I've Granted Access" buttons
  - Copy Debug Logs button
- [x] **KeyboardDetectionScreenView.swift** - Keyboard detection screen
  - Purple-themed detection UI
  - Permission status display
  - Temporary "Simulate Detection" button (will be replaced with real detection)
  - Keystroke display area
- [x] **ConfirmationScreenView.swift** - Keyboard confirmation screen
  - Green-themed confirmation UI
  - Displays detected keyboard info (name, vendor ID, product ID, interfaces)
  - "Detect Again" and "Confirm" buttons
- [x] **ControlPanelView.swift** - Main control panel
  - Two-column layout (controls on left, keystroke history on right)
  - Capture toggle switch with active/inactive status
  - Safety timer with presets (10s, 30s, 1m, 5m, 15m, 30m, 1h)
  - Manual timer input (minutes/seconds)
  - Device info card showing keyboard details
  - Parallels VM settings card
  - Keystroke history panel with event details
  - Settings, Change Keyboard, and Copy Logs buttons
  - **Layout optimizations**:
    - Left column fixed at 450px width
    - Right column expands to fill remaining space
    - Controls centered in left column
    - Compact spacing and padding
    - Safety Timer and Device Info side-by-side
    - Action buttons in horizontal row

### UI Refinements
- [x] Changed "Download Debug Logs" to "Copy Debug Logs" (copies to clipboard)
- [x] Removed popup alert, added temporary "Logs copied to clipboard" message
- [x] Message disappears after 2 seconds
- [x] Compact layout to reduce scrolling
- [x] Centered controls in left column
- [x] Wider keystroke history column for more data

### Build Script Status
- [x] Warnings/errors are captured and displayed
- [x] Build logs saved to timestamped files in Desktop/xCode Build Logs/
- [x] Automatic fallback to ad-hoc signing when development team not set
- [x] Version parsing fixed (now correctly shows 1.0.X format)
- [x] Script successfully builds and deploys app to Desktop
- [x] Code signing with development team configured
- [x] Re-signing after bundle modifications

---

## In Progress / Needs Verification 🔄

### UI Testing
- [x] All screens implemented and navigable
- [x] Permission status displays correctly
- [x] Copy Debug Logs functionality works
- [ ] Test full UI flow end-to-end
- [ ] Verify all buttons and interactions work

### Backend Functionality (To Be Ported)
- [ ] Keyboard detection by key press (currently simulated)
- [ ] Multiple interface handling
- [ ] Key interception and blocking
- [ ] Parallels connection/commands
- [ ] Key relay to Parallels guest OS
- [ ] Performance optimizations
- [ ] Timer safeguard implementation
- [ ] Real keystroke capture and history

---

## Next Steps (Priority Order)

### Phase 1: GitHub Setup ✅ (Current)
1. **Create GitHub repository for OverPass**
   - Initialize git repo
   - Create GitHub repo
   - Push current codebase
   - Update PROJECT_CONTEXT.md

### Phase 2: Port Functionality from KeyRelay
2. **Analyze old KeyRelay repository**
   - Repository: https://github.com/jadederea/KeyRelay
   - Connect to KeyRelay GitHub repo
   - Analyze codebase
   - Identify working functionality:
     - Keyboard detection by key press
     - Multiple interface handling
     - Key interception and blocking
     - Parallels connection/commands
     - Key relay to Parallels guest OS
     - Performance optimizations
     - Timer safeguard implementation
   - Document what works and what's needed

3. **Port and clean up code**
   - Rewrite working code cleanly for OverPass
   - Integrate with new UI
   - Replace temporary "Simulate Detection" with real detection
   - Implement real keystroke capture
   - Ensure logging is comprehensive
   - Ensure version tracking in logs

### Phase 3: Integration & Testing
4. **Connect backend to UI**
   - Hook up keyboard detection to UI
   - Connect permission checks to UI indicators
   - Integrate timer controls
   - Connect start/stop functionality
   - Add app close/open logging
   - Test end-to-end functionality

---

## Technical Notes

### Known Issues from Previous Work
- Performance/lag issues were fixed in old codebase (need to port solution)
- Some keyboards detected twice due to multiple interfaces (work in progress)
- Input Monitoring permission requires app restart to take effect (expected behavior)

### Architecture Decisions
- Using SwiftUI for UI
- CGEvent/IOHIDManager for keyboard input (to be confirmed from old codebase)
- Parallels command interface (to be analyzed from old codebase)
- In-memory logging (10,000 entry limit)
- Version in app name prevents macOS permission caching issues
- Dark theme UI matching Figma design
- Two-column layout for control panel (450px left, flexible right)

### File Structure
```
OverPass/
├── OverPass/
│   ├── OverPassApp.swift          # Main app entry point
│   ├── ContentView.swift           # Main view with navigation
│   ├── AppState.swift              # Navigation and state management
│   ├── AppVersion.swift            # Version management
│   ├── Logger.swift                # Logging system
│   ├── PermissionManager.swift    # macOS permissions
│   ├── PermissionsScreenView.swift # Permissions screen
│   ├── KeyboardDetectionScreenView.swift # Detection screen
│   ├── ConfirmationScreenView.swift # Confirmation screen
│   ├── ControlPanelView.swift      # Main control panel
│   ├── Info.plist                  # App configuration
│   └── OverPass.entitlements       # App entitlements
├── build_and_deploy.sh            # Build and deployment script
├── version.txt                      # Current version
├── PROJECT_CONTEXT.md             # This file
└── README.md                       # Project readme
```

### Dependencies
- macOS 12.0+
- Xcode 15.0+
- Swift 5.0+
- Parallels Desktop with Windows 11 guest OS

### External Resources
- Old repository: https://github.com/jadederea/KeyRelay
- Figma design: MacOS Accessibility Checker App (converted to SwiftUI)

---

## Change Log

### 2026-01-18 - UI Complete, Ready for GitHub
- Converted entire Figma design to SwiftUI
- Implemented all 4 screens (Permissions, Detection, Confirmation, Control Panel)
- Added navigation system with AppState
- Optimized layout (centered controls, wider history column)
- Changed "Download Debug Logs" to "Copy Debug Logs" with clipboard functionality
- Added temporary confirmation message for log copy
- All UI components match Figma design with dark theme
- Ready to create GitHub repository and push code

### 2024-12-19 - Initial Context File Created
- Documented project intent and requirements
- Listed completed foundation work
- Identified next steps
- Created working agreement documentation
- Added build log saving to Desktop/xCode Build Logs/

---

## Recent Logs Analysis

From logs (Version 1.0.28):
- Logger initialized successfully
- Permissions checked: Accessibility: true, Input Monitoring: true
- App launched successfully
- Keyboard detection screen appeared (detection will be implemented)
- Copy Debug Logs functionality working

All systems operational. Ready for backend functionality port from KeyRelay.
