# OverPass - AI Handoff Documentation

**Last Updated:** 2026-01-18  
**Current Version:** 1.2.2  
**Status:** Core functionality complete - capture, blocking, and relay working

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Old Repository Analysis (KeyRelay)](#old-repository-analysis-keyrelay)
3. [What Was Ported from KeyRelay](#what-was-ported-from-keyrelay)
4. [What Was Built New](#what-was-built-new)
5. [Technical Architecture](#technical-architecture)
6. [Known Issues & Fragile Functionality](#known-issues--fragile-functionality)
7. [Performance Considerations](#performance-considerations)
8. [Xcode Discoveries & Gotchas](#xcode-discoveries--gotchas)
9. [GitHub Setup & Workflow](#github-setup--workflow)
10. [Build & Deployment Script](#build--deployment-script)
11. [Logging System](#logging-system)
12. [Future Improvements & Recommendations](#future-improvements--recommendations)

---

## Project Overview

**OverPass** is a macOS application that intercepts keyboard input from a designated external keyboard and relays those keystrokes to a Parallels Desktop Windows 11 guest OS, while blocking the input from reaching the macOS host. The built-in keyboard continues to function normally on macOS.

### Core Requirements
- Detect and select a second keyboard by key press (not pre-selection)
- Capture and block keystrokes from the selected keyboard
- Relay captured keystrokes to Parallels VM (optional - can be capture-only)
- Support long key presses (WASD, arrows, space, delete, backspace) without treating as errors
- Configurable safety timer (default 5 minutes) to prevent getting stuck
- Comprehensive logging system
- Version tracking (MAJOR.MINOR.PATCH format)

### User Context
- User is a product owner/agile coach with QA experience, not a developer
- Prefers small, incremental changes with frequent builds/deployments
- Heavy reliance on logging for debugging
- Wants minimal Xcode interaction (prefers automation)

---

## Old Repository Analysis (KeyRelay)

**Repository:** https://github.com/jadederea/KeyRelay  
**Status:** Messy codebase, but had working functionality

### What Was Good in KeyRelay

1. **Device Detection Logic**
   - Used `physicalDeviceId` to group multiple interfaces of the same physical keyboard
   - Distinguished built-in keyboards from external Apple keyboards using `locationID`
   - Automatic detection by key press (not pre-selection)

2. **HID Usage Code to macOS Key Code Mapping**
   - Comprehensive mapping in `KeyCodeMapper` or similar
   - Handled edge cases like rollover events (0xFFFFFFFF)
   - Correct mapping for all standard keys

3. **Parallels Integration**
   - Used `prlctl` command-line tool (NOT Apple Events - that didn't work)
   - Discovered QWERTY scan code requirement (critical insight)
   - Scan codes follow QWERTY layout, NOT macOS key code layout

4. **Key State Tracking**
   - Handled long key presses correctly
   - Avoided duplicate key events
   - Performance optimizations for relay queue

5. **Security & Permissions**
   - Proper entitlement configuration
   - Input Monitoring and Accessibility permissions
   - USB and Bluetooth device access

### What Was Bad/Messy in KeyRelay

1. **Code Organization**
   - Mixed concerns, unclear separation
   - Duplicate code paths
   - Inconsistent naming conventions

2. **UI Issues**
   - Visual Studio Code + GitHub Copilot kept messing up the UI
   - User had to create Figma designs to get proper UI

3. **Xcode Project Corruption**
   - Project file got corrupted and couldn't be restored
   - This led to the decision to start fresh with OverPass

4. **Incomplete Features**
   - Device detection by key press was in progress but not fully complete
   - Some functionality was partially implemented

---

## What Was Ported from KeyRelay

### 1. Device Detection System

**Files:**
- `KeyboardDevice.swift` - Data model for keyboard devices
- `KeyboardDeviceService.swift` - IOKit HID Manager for device discovery
- `AutomaticKeyboardDetector.swift` - Automatic detection by key press

**Key Logic:**
- Uses `physicalDeviceId` to group multiple interfaces (e.g., a keyboard with both USB and Bluetooth interfaces)
- Distinguishes built-in vs external keyboards using `locationID` and transport type
- Automatically stops detection after 3 keystrokes
- Correlates detected devices with available devices using exact ID or physical device ID matching

**Improvements Made:**
- Removed vendor/product ID fallback matching (too permissive, caused false positives)
- Added explicit device selection UI when multiple devices detected
- Better logging and error handling

### 2. Keyboard Capture & Blocking

**File:** `KeyboardCaptureService.swift`

**Hybrid Approach:**
- **HID Monitoring**: Uses `IOHIDManager` to capture events from the specific target device
- **System-Wide Blocking**: Uses `CGEvent.tapCreate` to block events from reaching macOS

**Key Features:**
- Tracks pressed keys in `pressedKeys: Set<Int>` to allow key repeats for held keys
- Uses `previousHIDState: [Int: Bool]` to detect key down/up transitions from HID state reports
- Event correlation with time windows to prevent blocking built-in keyboard
- Filters out rollover events (0xFFFFFFFF) that cause duplicate key presses

**Blocking Logic:**
- For key down: Blocks if key is in `pressedKeys` AND has recent HID event (within 10 seconds)
- For key up: Blocks if key is in `pressedKeys` AND has recent HID key up event (within 200ms)
- Uses generous time windows (10 seconds) for held keys to prevent "stuck key" sounds

### 3. HID Usage Code Mapping

**Function:** `usageToKeyCode(_ usage: UInt32) throws -> Int`

**Key Points:**
- Maps HID usage codes (0x04-0x1D for A-Z) to macOS key codes
- macOS key codes are NOT sequential (e.g., A=0, B=11, C=8, D=2)
- Handles special keys, numbers, arrows, function keys
- Error handling for unmapped or invalid usage codes
- Explicitly filters 0xFFFFFFFF rollover events

### 4. Parallels Relay Integration

**Function:** `sendKeyToParallelsVM(vm:keyCode:isKeyDown:)`

**Critical Discovery from KeyRelay:**
- Parallels expects **QWERTY scan codes**, NOT macOS key codes
- Scan codes follow physical QWERTY keyboard layout
- Example: W key on macOS is keyCode 13, but scan code is 17 (QWERTY position)

**Function:** `convertToScanCode(_ keyCode: Int) -> Int`

**Recent Fix (v1.2.2):**
- Was incorrectly treating input as HID usage codes instead of macOS key codes
- Fixed mappings:
  - W (keyCode 13) → scan code 17 (was incorrectly 36/J)
  - Space (keyCode 49) → scan code 57 (was incorrectly 43/backslash)
  - Arrow keys were already correct

**Command Format:**
```bash
prlctl send-key-event <VM_UUID> --scancode <scan_code> --event <press|release>
```

**Performance:**
- Uses serial dispatch queue (`relayQueue`) to prevent race conditions
- Commands typically take 140-170ms to execute
- Logs all relay attempts with success/failure status

### 5. Security & Permissions

**File:** `OverPass.entitlements`

**Entitlements:**
- `com.apple.security.app-sandbox: false` - Required for HID access
- `com.apple.security.device.usb: true`
- `com.apple.security.device.bluetooth: true`
- `com.apple.security.device.input-monitoring: true`
- `com.apple.security.device.accessibility: true`

**Permission Manager:**
- Checks and requests Accessibility permission
- Checks and requests Input Monitoring permission
- Logs permission status changes
- Note: Input Monitoring permission changes require app restart

---

## What Was Built New

### 1. SwiftUI UI (from Figma Design)

**Files:**
- `PermissionsScreenView.swift` - Initial permission request screen
- `KeyboardDetectionScreenView.swift` - Automatic keyboard detection with selection UI
- `ConfirmationScreenView.swift` - (Currently skipped in navigation flow)
- `ControlPanelView.swift` - Main control panel with capture/relay toggle

**Color Scheme:**
- "Sapphire nightfall whisper" palette
- Dark theme with blue accents
- Defined in `AppColors.swift` extension

**Navigation:**
- Uses `AppState.swift` singleton for navigation state
- Screen-based navigation (not step-based)
- Back button on control panel stops capture before navigating

### 2. Version Management

**File:** `version.txt` in project root
- Format: `MAJOR.MINOR.PATCH` (e.g., `1.2.2`)
- Single line, no whitespace (e.g., `1.2.2` not `1.2.2 ` or ` 1.2.2`)
- MAJOR: First deployment or major milestones (e.g., 1.0.0 for first release, 2.0.0 for major rewrite)
- MINOR: Feature completions (e.g., 1.1.0 for device detection, 1.2.0 for relay functionality)
- PATCH: Each test build/deployment (e.g., 1.2.1, 1.2.2, 1.2.3 for bug fixes)

**Version Increment Rules:**
- **MAJOR** increments when:
  - First deployment to users
  - Major architectural changes
  - Breaking changes to functionality
  - Major milestone completion
  
- **MINOR** increments when:
  - A complete feature is finished and working
  - Example: Device detection complete → 1.1.0
  - Example: Relay functionality complete → 1.2.0
  
- **PATCH** increments when:
  - Each build/deployment for testing
  - Bug fixes
  - Small improvements
  - Example: Fix scan code mapping → 1.2.2

**Version Update Process:**
1. Build script reads `version.txt` (with whitespace trimming)
2. Automatically increments PATCH version
3. Updates `version.txt` with new version
4. Updates `Info.plist` `CFBundleShortVersionString` and `CFBundleVersion`
5. Copies `version.txt` into app bundle at `Contents/Resources/version.txt`
6. App name includes version: `OverPass-v<version>.app` (prevents macOS permission caching)

**Display Locations:**
- **UI:** Top center of main window (all screens)
- **Logs:** Every log entry includes version: `[1.2.2] [INFO] ...`
- **App Name:** Desktop deployment includes version in filename
- **Info.plist:** Both `CFBundleShortVersionString` and `CFBundleVersion` fields

**Version File Format:**
```
1.2.2
```
(No trailing newline, no spaces, just the version number)

**Important Notes:**
- Version is automatically incremented by build script - never manually edit during development
- Version must match across all locations (version.txt, Info.plist, UI, logs)
- App name versioning prevents macOS from caching permissions incorrectly
- Version history is tracked in this documentation file

### 3. Logging System

**File:** `Logger.swift`

**Features:**
- In-memory log storage (no file I/O)
- Log levels: `.debug`, `.info`, `.warning`, `.error`
- Includes version number, timestamp, file, line number
- "Copy Debug Logs" button copies formatted logs to clipboard
- "Copy Keystrokes" button copies keystroke history to clipboard
- Logs app open/close events for permission change tracking

**Log Format:**
```
[YYYY-MM-DD HH:MM:SS.mmm] [VERSION] [LEVEL] [File.swift:Line] message
```

### 4. Safety Timer

**Implementation:**
- Configurable duration (default 5 minutes, adjustable in seconds)
- Automatically stops capture/relay when timer expires
- Prevents user from getting stuck if all keyboard input is accidentally blocked
- Displayed in Control Panel with countdown

### 5. Build & Deployment Script

**File:** `build_and_deploy.sh` in project root

**Process:**
1. Reads current version from `version.txt`
2. Increments PATCH version
3. Updates `version.txt`
4. Builds app with Xcode
5. Captures build logs to `~/Desktop/xCode Build Logs/`
6. Updates `Info.plist` with new version
7. Re-signs app after modifications
8. Copies version file into app bundle
9. Deploys to Desktop as `OverPass-v<version>.app`
10. Removes extended attributes (`xattr -cr`)
11. Re-signs deployed app
12. Cleans old versions (keeps last 3)

**Code Signing:**
- First attempts automatic signing
- Falls back to ad-hoc signing if development team not configured
- Re-signs after any bundle modifications
- Uses `rsync` instead of `cp` to preserve code signatures

---

## Technical Architecture

### Key Services

1. **PermissionManager** (Singleton)
   - Checks/requests macOS permissions
   - Observable for UI updates

2. **KeyboardDeviceService** (Singleton)
   - Discovers connected keyboards via IOKit
   - Groups interfaces by physical device ID

3. **AutomaticKeyboardDetector** (Instance per detection)
   - Listens for key presses
   - Correlates with available devices
   - Auto-stops after 3 keystrokes

4. **KeyboardCaptureService** (Singleton)
   - Manages capture/blocking/relay
   - Tracks key state
   - Handles Parallels VM communication

5. **Logger** (Singleton)
   - Centralized logging
   - Clipboard export

### Data Flow

1. **Detection:**
   - User clicks "Start Detection"
   - `AutomaticKeyboardDetector` sets up HID manager
   - User types on target keyboard
   - Detector correlates HID events with device list
   - UI shows detected device(s) for confirmation

2. **Capture:**
   - User confirms device and starts capture
   - `KeyboardCaptureService` sets up:
     - HID monitoring for target device
     - CGEvent tap for system-wide blocking
   - HID events captured and displayed in UI
   - CGEvent tap blocks matching events from macOS

3. **Relay (if enabled):**
   - Each HID key down/up event triggers `sendKeyToParallelsVM`
   - macOS key code converted to QWERTY scan code
   - `prlctl` command executed on serial queue
   - Success/failure logged

---

## Known Issues & Fragile Functionality

### 1. Code Signing Issues

**Problem:**
- App sometimes shows "damaged or incomplete" error after deployment
- Extended attributes can corrupt code signature
- macOS Gatekeeper can be finicky

**Current Solution:**
- Aggressive `xattr -cr` removal
- Re-signing after all modifications
- Using `rsync` instead of `cp`
- Manual Terminal command provided for user if needed:
  ```bash
  xattr -cr ~/Desktop/OverPass-v1.X.X.app && codesign --force --deep --sign "Apple Development" ~/Desktop/OverPass-v1.X.X.app
  ```

**Fragility:**
- Code signing is fragile and can break with any bundle modification
- May need to adjust signing approach if issues persist

### 2. Device Detection Correlation

**Potential Issue:**
- Currently uses exact ID or physical device ID matching only
- Removed vendor/product ID fallback (was too permissive)
- May miss devices if physical device ID is not available

**Fragility:**
- If a keyboard doesn't report physical device ID correctly, detection may fail
- Multiple interfaces of same device should be handled, but edge cases may exist

### 3. Event Blocking Correlation

**Optimization (2026-01) - Performance & Reliability:**
- Replaced O(n) array iteration with O(1) dictionary lookup (`lastHIDKeyDownTime`, `lastHIDKeyUpTime`)
- Event tap callback runs for EVERY system key event - was bottleneck causing lag and missed keys under load
- Widened initial correlation window to 80ms (from 30ms) for better load tolerance
- Key up now trusts `pressedKeys` only (fixes race when CGEvent arrives before HID callback - keys reaching host)
- Added periodic cleanup (every 5s) to prevent stale state accumulation and degradation over time
- Relay queue: now uses OperationQueue with 2 concurrent operations (was serial) to reduce "lag then burst"

### 4. HID State Report Handling

**Complexity:**
- HID keyboards send state reports, not individual key events
- Must compare current vs previous state to detect transitions
- Rollover events (0xFFFFFFFF) must be filtered

**Fragility:**
- If HID state reports change format or timing, detection may break
- Some keyboards may report state differently

### 5. Parallels VM Detection

**Current Implementation:**
- Parses `prlctl list --all` output
- Assumes specific output format
- May break if Parallels updates output format

**Fragility:**
- Relies on `prlctl` command-line tool being available
- Output parsing is string-based and may be fragile

### 6. Scan Code Mapping

**Recent Fix:**
- Fixed incorrect mappings for W and Space keys (v1.2.2)
- Mapping is now correct but was wrong initially

**Fragility:**
- Scan code mapping is manual and error-prone
- If new keys are added, mapping must be verified
- QWERTY layout assumption may not hold for all keyboards

---

## Performance Considerations

### 1. Relay Queue Serialization

**Current:** Serial dispatch queue for `prlctl` commands  
**Impact:** Prevents race conditions but may cause slight delays  
**Typical Latency:** 140-170ms per command  
**Consideration:** May need optimization if many rapid key presses

### 2. Event Correlation Time Windows

**Current:**
- 10 seconds for held keys (very generous)
- 200ms for key up events
- 50ms for initial key down correlation

**Impact:**
- Large time windows prevent false positives but may retain events longer than needed
- Memory usage for `recentHIDEvents` array (cleaned up every 10 seconds)

### 3. HID Event Processing

**Current:** Processes all HID events from target device  
**Impact:** Should be minimal, but high-frequency keyboards may cause issues  
**Consideration:** May need throttling if performance issues arise

### 4. UI Updates

**Current:** All captured events added to UI array  
**Impact:** Large arrays may slow UI scrolling  
**Current Limit:** 1000 events (`maxHistorySize`)  
**Consideration:** May need pagination or lazy loading for very long sessions

---

## Xcode Discoveries & Gotchas

### 1. File Recognition Issues

**Problem:**
- Xcode sometimes doesn't recognize newly added Swift files
- Even when correctly added to `project.pbxproj`

**Solution:**
- Manually verify "Target Membership" in File Inspector
- Sometimes need to clean build folder or reopen project
- Programmatically adding to `project.pbxproj` helps but not always sufficient

### 2. Code Signing Configuration

**Discovery:**
- Automatic signing requires development team to be set in Xcode
- Can fall back to ad-hoc signing, but user should configure team
- Created `CODE_SIGNING_SETUP.md` guide for user

**Gotcha:**
- Signing must happen AFTER all bundle modifications
- Any modification to `Info.plist` or bundle contents invalidates signature

### 3. Deployment Target

**Current:** macOS 12.0  
**Limitation:**
- Some SwiftUI features require macOS 13.0+ (e.g., `defaultSize`, `onKeyPress`)
- Had to remove these features to maintain compatibility

### 4. Build Script Integration

**Discovery:**
- Build script must handle both automatic and ad-hoc signing
- Must capture build output for logging
- Must handle errors gracefully

### 5. Project File Structure

**Discovery:**
- `project.pbxproj` is complex and error-prone to edit manually
- UUIDs must be unique
- File references must match actual file paths

---

## GitHub Setup & Workflow

### Repository

**URL:** Private repository (user made it private after initial creation)  
**Status:** Connected and accessible

### Workflow

1. **Code Changes:**
   - Make changes in Cursor/IDE
   - Test locally
   - Build and deploy

2. **Version Management:**
   - Version incremented automatically by build script
   - Version number in `version.txt` and `Info.plist`

3. **Commits:**
   - User requests commits when ready
   - All code checked in, including build scripts and documentation

### Files to Track

- All Swift source files
- `project.pbxproj` (Xcode project file)
- `build_and_deploy.sh` (build script)
- `version.txt` (version number)
- Documentation files (`.md` files)
- `OverPass.entitlements`

### Files to Ignore (`.gitignore`)

- Xcode user data (`xcuserdata/`)
- Build artifacts (`DerivedData/`)
- macOS system files (`.DS_Store`)
- Build logs directory
- Deployed apps on Desktop

---

## Build & Deployment Script

### File: `build_and_deploy.sh`

### Process Flow

1. **Version Management:**
   ```bash
   CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
   # Increment PATCH version
   # Update version.txt
   ```

2. **Build:**
   ```bash
   xcodebuild -project OverPass.xcodeproj \
              -scheme OverPass \
              -configuration Release \
              -derivedDataPath "$DERIVED_DATA" \
              build
   ```

3. **Log Capture:**
   - Creates `~/Desktop/xCode Build Logs/` directory
   - Saves build output to timestamped log file
   - Captures warnings and errors

4. **Code Signing:**
   - Attempts automatic signing first
   - Falls back to ad-hoc if team not configured
   - Re-signs after any bundle modification

5. **Version Update:**
   - Updates `Info.plist` with new version
   - Copies `version.txt` into app bundle
   - Re-signs after each modification

6. **Deployment:**
   - Uses `rsync -a --delete` to copy app bundle
   - Removes extended attributes (`xattr -cr`)
   - Re-signs deployed app
   - Names app with version: `OverPass-v<version>.app`

7. **Cleanup:**
   - Keeps last 3 versions on Desktop
   - Removes older versions

### Key Features

- Robust error handling
- Version parsing with whitespace handling
- Build log capture for debugging
- Multiple re-signing steps to maintain signature validity
- Extended attribute removal to prevent corruption

### Known Issues

- Signature verification sometimes fails (warning, not error)
- May need manual re-signing in some cases
- Build logs can be large for complex builds

---

## Logging System

### Architecture

**Singleton Pattern:** `Logger.shared`  
**Storage:** In-memory array of log entries  
**Format:** Structured with version, timestamp, level, file, line, message

### Log Levels

- **`.debug`**: Detailed information for debugging (key events, state changes)
- **`.info`**: General information (app lifecycle, user actions)
- **`.warning`**: Potential issues (signature verification failures)
- **`.error`**: Errors that need attention (permission failures, command failures)

### Key Logging Points

1. **App Lifecycle:**
   - App initialization
   - App termination
   - App reopen (for permission change tracking)

2. **Permissions:**
   - Permission checks
   - Permission requests
   - Permission status changes

3. **Device Detection:**
   - Detection start/stop
   - Key press events
   - Device correlation results

4. **Capture/Blocking:**
   - Capture start/stop
   - HID events captured
   - Events blocked
   - Key state changes

5. **Relay:**
   - Relay attempts
   - Scan code conversions
   - Command execution (success/failure)
   - Timing information

### Export Functions

1. **Copy Debug Logs:**
   - Formats all log entries
   - Copies to system clipboard
   - Shows temporary confirmation message in UI

2. **Copy Keystrokes:**
   - Formats captured keystroke history
   - Includes timestamps and event types
   - Copies to system clipboard

### Best Practices

- Log all user actions
- Log all state transitions
- Include context (device names, key codes, scan codes)
- Use appropriate log levels
- Include timing information for performance-critical operations

---

## Future Improvements & Recommendations

### 1. Code Quality

**Current State:**
- Some code marked for removal (see `CODE_CLEANUP_GUIDE.md`)
- Commented-out code from porting process
- Some duplicate or unused code paths

**Recommendations:**
- Review and remove commented-out code
- Clean up unused functions
- Improve code organization and separation of concerns
- Add unit tests for critical functions (scan code mapping, key code conversion)

### 2. Error Handling

**Current State:**
- Basic error handling in place
- Some functions may throw errors that aren't fully handled

**Recommendations:**
- Add comprehensive error handling
- User-friendly error messages
- Recovery strategies for common failures
- Better handling of Parallels VM connection failures

### 3. Performance Optimization

**Potential Improvements:**
- Optimize relay queue (may need async/await instead of serial queue)
- Reduce event correlation time windows if possible
- Implement event throttling for high-frequency keyboards
- Lazy loading for keystroke history UI

### 4. User Experience

**Potential Improvements:**
- Better visual feedback for capture/relay status
- Keyboard shortcuts for common actions
- Preferences/settings persistence
- Better error messages and recovery guidance

### 5. Testing

**Current State:**
- Manual testing only
- No automated tests

**Recommendations:**
- Add unit tests for key functions
- Integration tests for device detection
- UI tests for critical user flows
- Performance tests for relay functionality

### 6. Documentation

**Current State:**
- This handoff document
- `PROJECT_CONTEXT.md` (may have been deleted)
- `CODE_CLEANUP_GUIDE.md`
- `CODE_SIGNING_SETUP.md`
- `FIRST_LAUNCH_INSTRUCTIONS.md`

**Recommendations:**
- Keep documentation up to date
- Add code comments for complex logic
- Document API contracts and assumptions
- User-facing documentation for common issues

### 7. Robustness

**Areas to Strengthen:**
- Handle edge cases in device detection
- Better handling of keyboard disconnection during capture
- Graceful degradation if Parallels is not available
- Better handling of permission changes during runtime

### 8. Features

**Potential Additions:**
- Support for multiple VMs (currently single target)
- Keyboard shortcuts for quick actions
- Preset configurations
- Statistics/analytics for captured keystrokes
- Export keystroke history to file (in addition to clipboard)

---

## Critical Code Locations

### Key Files

1. **`KeyboardCaptureService.swift`**
   - Core capture/blocking/relay logic
   - Scan code conversion (recently fixed)
   - HID usage code to macOS key code mapping

2. **`AutomaticKeyboardDetector.swift`**
   - Device detection by key press
   - Device correlation logic

3. **`KeyboardDeviceService.swift`**
   - Device discovery via IOKit
   - Physical device ID grouping

4. **`build_and_deploy.sh`**
   - Build and deployment automation
   - Version management
   - Code signing

5. **`Logger.swift`**
   - Centralized logging system
   - Clipboard export

### Critical Functions

1. **`convertToScanCode(_ keyCode: Int) -> Int`**
   - Maps macOS key codes to QWERTY scan codes
   - **Recently fixed** (v1.2.2) - was incorrectly treating input as HID codes

2. **`usageToKeyCode(_ usage: UInt32) throws -> Int`**
   - Maps HID usage codes to macOS key codes
   - Critical for correct key detection

3. **`hasDirectHIDCorrelation(keyCode:isKeyDown:eventTimestamp:) -> Bool`**
   - Determines if CGEvent should be blocked
   - Complex timing-based correlation logic

4. **`handleHIDInput(value:device:)`**
   - Processes HID events from target device
   - Detects key down/up transitions
   - Triggers relay if enabled

---

## Important Notes for Future AI

### 1. User Preferences

- **Small, incremental changes** - Break tasks into small pieces
- **Frequent builds/deployments** - Test often
- **Heavy logging** - Log everything, suggest log improvements
- **Minimal Xcode interaction** - Automate as much as possible
- **Clean code** - Comment out unused code, flag for removal

### 2. Development Process

- Version increments automatically with each build
- Always test capture, blocking, and relay after changes
- Check logs for any issues
- User will provide feedback based on testing

### 3. Common Issues

- **Code signing failures:** Try manual re-signing command
- **Device detection issues:** Check physical device ID grouping
- **Relay not working:** Verify scan code mappings
- **Built-in keyboard blocked:** Check event correlation time windows
- **Stuck key sounds:** Verify blocking logic for key repeats

### 4. Testing Checklist

After any changes, verify:
- [ ] App builds and deploys successfully
- [ ] Permissions are requested correctly
- [ ] Device detection works (try with multiple keyboards)
- [ ] Capture blocks target keyboard from macOS
- [ ] Built-in keyboard still works on macOS
- [ ] Relay sends correct keys to VM (test W, A, S, D, Space, arrows)
- [ ] Long key presses work (no stuck key sounds)
- [ ] Safety timer works
- [ ] Logs are comprehensive and helpful

---

## Version History

- **1.0.0** - Initial setup, permissions, basic UI
- **1.1.0** - Device detection complete
- **1.1.1 - 1.1.25** - Capture/blocking implementation and bug fixes
- **1.2.0** - Relay functionality added
- **1.2.1** - Device detection improvements (stricter correlation, selection UI)
- **1.2.2** - Fixed scan code mappings (W, Space, arrows)

---

## Contact & Context

If you're a new AI picking up this project:

1. **Read this document first** - It contains critical context
2. **Check the logs** - User relies heavily on logging for debugging
3. **Test incrementally** - Small changes, frequent builds
4. **Ask questions** - User is helpful and provides good feedback
5. **Document changes** - Update this file if you discover new issues or make significant changes

**Remember:** The user is not a developer. Make things simple, automated, and well-logged.

---

**End of Documentation**
