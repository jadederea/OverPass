# Security & Permissions Comparison: OverPass vs KeyRelay

**Date**: 2026-01-18  
**Purpose**: Compare security settings and permissions between OverPass and KeyRelay to ensure nothing is missing

---

## Entitlements Comparison

### OverPass Current Entitlements
```xml
- com.apple.security.app-sandbox: false ✓
- com.apple.security.device.usb: true ✓
- com.apple.security.device.input-monitoring: true ✓
- com.apple.security.device.accessibility: true ✓
- com.apple.security.cs.allow-jit: false
- com.apple.security.cs.allow-unsigned-executable-memory: false
- com.apple.security.cs.disable-library-validation: false
```

### KeyRelay Entitlements
```xml
- com.apple.security.app-sandbox: false ✓ (same)
- com.apple.security.files.user-selected.read-only: true (not in OverPass)
- com.apple.security.device.audio-input: false (not in OverPass, not needed)
- com.apple.security.automation.apple-events: true ⚠️ (MISSING in OverPass)
- com.apple.security.device.usb: true ✓ (same)
- com.apple.security.device.bluetooth: true ⚠️ (MISSING in OverPass)
- com.apple.security.device.input-monitoring: true ✓ (same)
- com.apple.security.personal-information.location: false (not in OverPass, not needed)
- com.apple.security.cs.allow-jit: true ⚠️ (OverPass has false)
- com.apple.security.cs.allow-unsigned-executable-memory: true ⚠️ (OverPass has false)
- com.apple.security.cs.disable-library-validation: true ⚠️ (OverPass has false)
```

---

## Missing Entitlements Analysis

### 1. Bluetooth Support ⚠️ **RECOMMENDED**
- **KeyRelay has**: `com.apple.security.device.bluetooth: true`
- **OverPass has**: Not present
- **Why needed**: KeyRelay supports Bluetooth keyboards (code shows `.bluetooth` transport type)
- **Impact**: If user has Bluetooth keyboard, we won't be able to detect/use it
- **Recommendation**: **ADD** - Users may use Bluetooth keyboards

### 2. Apple Events Automation ✅ **NOT NEEDED**
- **KeyRelay has**: `com.apple.security.automation.apple-events: true`
- **OverPass has**: Not present
- **Investigation Result**: KeyRelay uses `prlctl` command-line tool via Process/ProcessTask, NOT Apple Events
- **Impact**: None - Parallels integration doesn't use Apple Events
- **Recommendation**: **DO NOT ADD** - Not needed for functionality

### 3. Hardened Runtime Settings ⚠️ **NEEDS INVESTIGATION**
- **KeyRelay has**: All three set to `true` (allow-jit, allow-unsigned-executable-memory, disable-library-validation)
- **OverPass has**: All three set to `false` (more secure)
- **Why KeyRelay has them**: Might be needed for certain functionality (JIT compilation, dynamic libraries)
- **Impact**: Unknown - might break some functionality if needed
- **Recommendation**: **INVESTIGATE** - Only add if functionality requires it

---

## Permission Checking Comparison

### Accessibility Permission

**KeyRelay**:
```swift
hasAccessibilityPermission = AXIsProcessTrusted()  // Older API
```

**OverPass**:
```swift
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
let accessEnabled = AXIsTrustedWithOptions(options as CFDictionary)  // Newer API
```

**Status**: ✅ **OverPass is better** - Uses newer API with options

### Input Monitoring Permission

**KeyRelay**:
```swift
let eventTap = CGEvent.tapCreate(...)
guard let tap = eventTap else { return false }
CFMachPortInvalidate(tap)  // Explicit cleanup
return true
```

**OverPass**:
```swift
let eventTap = CGEvent.tapCreate(...)
guard let eventTap = eventTap else { return false }
CGEvent.tapEnable(tap: eventTap, enable: false)  // Just disable
// Note: eventTap is automatically memory managed in Swift
return true
```

**Status**: ⚠️ **Should improve** - KeyRelay uses `CFMachPortInvalidate()` for proper cleanup

---

## Info.plist Comparison

### OverPass Has (Good):
- `NSAppleEventsUsageDescription` - Explains Accessibility permission
- `NSSystemAdministrationUsageDescription` - Explains Input Monitoring permission

### KeyRelay Has:
- No permission descriptions in Info.plist (older approach)

**Status**: ✅ **OverPass is better** - Has proper permission descriptions

---

## Recommendations

### Immediate Actions (Before Porting Functionality)

1. **ADD Bluetooth Entitlement** ✅ **COMPLETED**
   - Users may have Bluetooth keyboards
   - KeyRelay code shows Bluetooth support is used
   - **Status**: Added to OverPass.entitlements

2. **Apple Events Entitlement** ✅ **NOT NEEDED - CONFIRMED**
   - KeyRelay uses `prlctl` command-line tool, not Apple Events
   - User confirmed: "apple events didn't work, we tried that. the prlctl command line is what got it all working"
   - **Status**: Will NOT add - confirmed not needed

3. **IMPROVE Event Tap Cleanup** ✅ **COMPLETED**
   - Use `CFMachPortInvalidate()` instead of just disabling
   - Better memory management
   - **Status**: Updated PermissionManager.swift to use CFMachPortInvalidate()

4. **INVESTIGATE Hardened Runtime Settings** ⚠️ **CHECK LATER**
   - Only add if functionality breaks
   - Keep secure defaults (false) unless needed
   - **Status**: Keeping secure defaults for now

---

## Next Steps

1. ✅ **COMPLETED** - Add Bluetooth entitlement
2. ✅ **COMPLETED** - Improve event tap cleanup in PermissionManager (use CFMachPortInvalidate)
3. ⚠️ Test with Bluetooth keyboard (if available) - **READY FOR TESTING**
4. ⚠️ Monitor for any runtime issues that might need hardened runtime settings
5. ✅ **CONFIRMED** - Apple Events entitlement - NOT NEEDED (user confirmed prlctl is what works)

## Status Summary

**Security & Permissions**: ✅ **COMPLETE**
- All required entitlements in place (USB, Bluetooth, Input Monitoring, Accessibility)
- Permission checking improved (proper cleanup)
- Apple Events confirmed not needed
- Hardened runtime settings kept secure (false) unless needed later

**Ready for**: Porting keyboard detection and relay functionality from KeyRelay

---

## Notes

- OverPass permission checking is generally better (newer APIs, better descriptions)
- KeyRelay has some entitlements we might need (Bluetooth, possibly Apple Events)
- Hardened runtime settings should be kept secure unless functionality requires them
- All changes should be tested incrementally
