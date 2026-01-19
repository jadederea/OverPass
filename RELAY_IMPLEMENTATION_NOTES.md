# Relay Implementation Notes

## Key Discovery: QWERTY Layout for Scan Codes

**CRITICAL DISCOVERY FROM KEYRELAY:**
When relaying keystrokes to Parallels/Windows via `prlctl`, the scan codes must follow **QWERTY layout**, NOT macOS key code layout.

### Why This Matters

1. **macOS key codes** are based on physical key positions on Apple keyboards (NOT QWERTY)
2. **Windows scan codes** are based on QWERTY layout
3. When converting from macOS key codes → Windows scan codes for Parallels, you MUST map based on QWERTY layout

### Example from KeyRelay

The `convertToScanCode()` function in KeyRelay maps:
- macOS key code 0 (A) → Windows scan code 30 (A in QWERTY)
- macOS key code 12 (Q) → Windows scan code 16 (Q in QWERTY)
- macOS key code 1 (S) → Windows scan code 31 (S in QWERTY)

**Key Insight:** The comment in KeyRelay says:
> "CORRECTED: Based on actual terminal testing - scan codes follow QWERTY layout!"

### Implementation Notes

When implementing relay functionality:
1. Use `convertToScanCode()` to convert macOS key codes to Windows scan codes
2. The scan codes must follow QWERTY layout, not macOS layout
3. Use `formatScanCodeForVM()` to format scan codes for `prlctl` command
4. Send both "press" and "release" events to Parallels for proper key handling

### KeyRelay Implementation Location

- File: `KeystrokeCaptureService.swift`
- Function: `convertToScanCode(_ keyCode: Int) -> Int` (line ~375)
- Function: `formatScanCodeForVM(_ scanCode: Int) -> String` (line ~500+)
- Function: `sendKeyToParallelsVM(vm: ParallelsVM, keyCode: Int, isKeyDown: Bool)` (line ~211)

### prlctl Command Format

```bash
/usr/local/bin/prlctl send-key-event <VM_UUID> --scancode <SCAN_CODE> --event <press|release>
```

Where:
- `SCAN_CODE` is the Windows scan code (QWERTY-based)
- `--event press` for key down
- `--event release` for key up
