# Device Detection Logic Analysis

**Date**: 2026-01-18  
**Purpose**: Understand how KeyRelay detects keyboards and handles multiple interfaces

---

## User Intent ✅ **MAKES PERFECT SENSE**

The user wants:
1. **User types in a window** → App detects which keyboard hardware was used
2. **App detects the hardware AND all its interfaces** (USB, Bluetooth, etc.)
3. **App selects that hardware AND all interfaces** for interception
4. **App intercepts keystrokes from ALL interfaces** of that keyboard
5. **App blocks ALL interfaces from macOS host** (so host doesn't get keystrokes)
6. **Other keyboards continue working normally** on macOS host

**This makes perfect sense!** Some keyboards can connect via multiple interfaces (e.g., USB + Bluetooth), and we need to intercept ALL of them to prevent any keystrokes from reaching macOS.

---

## How KeyRelay Does It

### 1. Physical Device ID Concept

KeyRelay uses a **physicalDeviceId** to group interfaces:

```swift
// Physical Device ID format: "vendorID-productID-locationID>>8"
let physicalDeviceID = "\(vendorID)-\(productID)-\(locationID >> 8)"
```

**Key insight**: The `>> 8` (right shift by 8 bits) removes the interface-specific bits from locationID. This means:
- Same physical keyboard connected via USB and Bluetooth will have **same physicalDeviceId**
- Different interfaces of same hardware are grouped together

### 2. Device Detection Flow

**Step 1: Scan for All Devices** (`KeyboardDeviceService`)
- Uses IOKit HID Manager to enumerate all keyboard devices
- Creates `KeyboardDevice` objects with:
  - `id`: Unique per interface (vendorId:productId:locationId)
  - `physicalDeviceId`: Groups interfaces of same hardware
  - `transportType`: USB, Bluetooth, Built-in, Unknown
  - `vendorId`, `productId`, `locationId`

**Step 2: User Types on Keyboard** (`AutomaticKeyboardDetector`)
- Listens for HID input events via IOHIDManager callback
- When key is pressed:
  - Gets device info (vendorId, productId, locationId)
  - Creates deviceId: `"vendorId:productId:locationId"`
  - Creates physicalDeviceId: `"vendorId-productId-locationId>>8"`
  - Tracks detected device IDs

**Step 3: Correlate with Available Devices**
- Matches detected device IDs with scanned devices
- Groups by `physicalDeviceId` to find ALL interfaces
- Returns list of devices (all interfaces for that physical hardware)

**Step 4: Select All Interfaces**
- When user confirms, selects the detected device
- During interception, matches by `physicalDeviceId` (not just `id`)
- This means ALL interfaces are intercepted

### 3. Interception Logic

In `KeystrokeCaptureService.handleKeyEvent()`:

```swift
// Get physical device ID from the event
let actualPhysicalDeviceID = "\(vendorID)-\(productID)-\(locationID >> 8)"

// Match by physical device ID (not just device ID)
let isPhysicalDeviceMatch = selectedDevice.physicalDeviceId != nil && 
    actualPhysicalDeviceID == selectedDevice.physicalDeviceId

if isPhysicalDeviceMatch {
    // Intercept this keystroke (block from macOS, relay to Parallels)
} else {
    // Let this keystroke through to macOS (from other keyboards)
}
```

**Result**: All interfaces of the selected physical device are intercepted, but other keyboards work normally.

---

## What Needs to Be Ported

### 1. KeyboardDevice Model ✅ **NEEDED**
- Data structure with `physicalDeviceId` for grouping interfaces
- `transportType` enum (USB, Bluetooth, Built-in, Unknown)
- Device identification fields

### 2. KeyboardDeviceService ✅ **NEEDED**
- IOKit HID Manager setup
- Device scanning logic
- Creating KeyboardDevice from IOHIDDevice
- Physical device ID calculation
- Transport type detection

### 3. AutomaticKeyboardDetector ✅ **NEEDED**
- HID input callback setup
- Listening for key presses
- Device identification from HID events
- Physical device ID calculation
- Correlation with available devices
- Grouping by physical device ID

### 4. Integration with Capture Service ✅ **NEEDED**
- Physical device ID matching in event handler
- Intercepting all interfaces of selected device
- Allowing other keyboards through

---

## Current Status in OverPass

### What We Have:
- ✅ Basic UI for keyboard detection screen
- ✅ Mock detection (temporary button)
- ✅ AppState to store keyboard info

### What We Need:
- ❌ KeyboardDevice model
- ❌ KeyboardDeviceService (device scanning)
- ❌ AutomaticKeyboardDetector (detection by key press)
- ❌ Physical device ID logic
- ❌ Interface grouping logic
- ❌ Integration with capture/interception

---

## Implementation Plan

### Phase 1: Device Model
1. Port `KeyboardDevice.swift` (data model)
2. Add to OverPass project

### Phase 2: Device Scanning
1. Port `KeyboardDeviceService.swift` (IOKit scanning)
2. Test device enumeration
3. Verify physical device ID calculation

### Phase 3: Detection by Key Press
1. Port `AutomaticKeyboardDetector.swift`
2. Integrate with KeyboardDetectionScreenView
3. Test detection when user types

### Phase 4: Interface Grouping
1. Verify physical device ID grouping works
2. Test with keyboard that has multiple interfaces
3. Ensure all interfaces are detected

### Phase 5: Integration
1. Connect detection to AppState
2. Update ConfirmationScreen to show all interfaces
3. Prepare for capture service integration

---

## Key Files to Port

1. **KeyboardDevice.swift** - Data model (simple, clean)
2. **KeyboardDeviceService.swift** - IOKit scanning (complex, needs careful porting)
3. **AutomaticKeyboardDetector.swift** - Detection logic (complex, needs careful porting)

---

## Notes

- Physical device ID is the key concept for grouping interfaces
- The `>> 8` bit shift is critical for grouping
- Detection happens via HID input callback, not CGEvent
- All interfaces of selected device must be intercepted
- Other keyboards must continue working normally

---

## Questions for User

1. Do you have a keyboard with multiple interfaces (USB + Bluetooth) to test with?
2. Should we port all three files at once, or one at a time for testing?
