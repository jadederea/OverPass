# Code Cleanup Guide

**Purpose**: Track code that has been commented out for eventual removal after porting functionality from KeyRelay.

## Marking Convention

When code is found to be unnecessary after comparison with KeyRelay, use this pattern:

```swift
// MARK: - REMOVE AFTER PORTING
// TODO: Remove this - not needed based on KeyRelay analysis
// Reason: [Brief explanation]
/*
[commented out code]
*/
```

## Cleanup Process

1. **During Porting**: Comment out unused code with clear markers
2. **After Porting Complete**: Review all marked code
3. **Final Cleanup**: Remove all commented code marked for removal
4. **Verification**: Test to ensure nothing breaks

## Current Status

- No code marked for removal yet
- Will update as we port functionality from KeyRelay

---

## Marked for Removal

### None yet - will be added during porting process
