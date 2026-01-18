# Built-in vs External Apple Keyboard Distinction

**Date**: 2026-01-18  
**User Setup**: 
- Built-in laptop keyboard (Apple) - **SHOULD NOT be intercepted**
- Wired Apple keyboard A1243 via USB - **SHOULD be intercepted**
- USB Logitech keyboard - **Probably not intercepted** (unless selected)

**Problem**: Need to distinguish built-in Apple keyboard from external Apple keyboard (same vendor, different physical devices)

---

## How KeyRelay Solves This

### Key Distinction: `locationID`

**Built-in Keyboard**:
- `locationID == 0` (or very specific built-in pattern)
- `transportType = .builtin`
- `transport` string contains "built" or "spi"

**External Apple Keyboard (USB)**:
- `locationID != 0` (has a location, meaning it's external)
- `transportType = .usb`
- `transport` string contains "usb"

### Physical Device ID Calculation

```swift
let physicalDeviceID = "\(vendorID)-\(productID)-\(locationID >> 8)"
```

**Result**:
- Built-in: `locationID = 0` → `physicalDeviceId = "1452-XXX-0"`
- External USB: `locationID = someValue` → `physicalDeviceId = "1452-XXX-someValue>>8"`

**These are DIFFERENT!** So built-in and external Apple keyboards will have different `physicalDeviceId` values and won't be grouped together.

---

## KeyRelay Logic (from KeyboardDeviceService.swift)

```swift
// Determine transport type
if vendorID == 1452 { // Apple devices
    if locationID == 0 || transport.contains("built") {
        transportType = .builtin
        // This is the built-in keyboard
    } else {
        transportType = .usb
        // This is external Apple keyboard (like A1243)
    }
}
```

### Detection Flow

1. **Scan Devices**:
   - Built-in: `locationID = 0`, `transportType = .builtin`
   - A1243 USB: `locationID != 0`, `transportType = .usb`
   - Logitech USB: `locationID != 0`, `transportType = .usb`, `vendorID != 1452`

2. **User Types on A1243**:
   - HID callback gets event from A1243
   - Calculates `physicalDeviceId` from event's `locationID`
   - Matches with scanned device that has same `physicalDeviceId`
   - Finds A1243 (NOT built-in, because different `locationID`)

3. **Interception**:
   - Matches events by `physicalDeviceId`
   - A1243 events match A1243's `physicalDeviceId`
   - Built-in events have different `physicalDeviceId`, so they pass through to macOS

---

## Critical Implementation Details

### 1. LocationID Check
```swift
// Built-in detection
if locationID == 0 || transport.contains("built") {
    transportType = .builtin
}
```

### 2. Physical Device ID Must Include LocationID
```swift
// This ensures built-in (locationID=0) and external (locationID!=0) are different
let physicalDeviceID = "\(vendorID)-\(productID)-\(locationID >> 8)"
```

### 3. Transport Type Detection
```swift
// Check transport string first
if transport.contains("usb") {
    transportType = .usb  // External
} else if transport.contains("built") || transport.contains("spi") {
    transportType = .builtin  // Built-in
} else if vendorID == 1452 && locationID == 0 {
    transportType = .builtin  // Apple built-in fallback
} else {
    transportType = .usb  // External (has locationID)
}
```

---

## What This Means for Your Setup

### Expected Device List:
1. **MacBook Pro Keyboard** (Built-in)
   - `vendorID = 1452` (Apple)
   - `productID = ?` (varies by model)
   - `locationID = 0`
   - `transportType = .builtin`
   - `physicalDeviceId = "1452-XXX-0"`

2. **Apple Wired Keyboard A1243** (USB)
   - `vendorID = 1452` (Apple)
   - `productID = ?` (A1243 specific)
   - `locationID != 0` (external USB location)
   - `transportType = .usb`
   - `physicalDeviceId = "1452-XXX-locationID>>8"` (different from built-in!)

3. **Logitech Keyboard** (USB)
   - `vendorID != 1452` (Logitech)
   - `productID = ?` (Logitech specific)
   - `locationID != 0` (external USB location)
   - `transportType = .usb`
   - `physicalDeviceId = "logitechVendor-XXX-locationID>>8"`

### Detection Result:
- User types on A1243 → Detects A1243 (external USB)
- Built-in keyboard continues working normally (different `physicalDeviceId`)
- Logitech keyboard continues working normally (different `physicalDeviceId`)

---

## Implementation Checklist

When porting device detection, ensure:

- [x] `locationID == 0` check for built-in detection
- [x] `transport` string check for "built" or "spi"
- [x] `physicalDeviceId` includes `locationID >> 8` (ensures built-in and external are different)
- [x] Transport type logic correctly identifies `.builtin` vs `.usb`
- [x] Physical device matching uses `physicalDeviceId` (not just vendor/product)
- [x] Logging shows `locationID` for debugging

---

## Testing Plan

1. **Scan Devices**: Verify built-in and A1243 are listed separately
2. **Type on A1243**: Verify detection identifies A1243 (not built-in)
3. **Type on Built-in**: Verify detection identifies built-in (if needed for testing)
4. **Interception**: Verify A1243 is intercepted, built-in passes through
5. **Logitech**: Verify Logitech is separate device (if selected, intercepts; if not, passes through)

---

## Notes

- The `locationID` is the critical differentiator
- `physicalDeviceId` calculation must include `locationID >> 8` to ensure separation
- Transport type helps with UI display but `locationID` is what matters for matching
- KeyRelay has explicit logging: "This prevents MacBook Pro keyboard from interfering with Apple Wired Keyboard capture"
