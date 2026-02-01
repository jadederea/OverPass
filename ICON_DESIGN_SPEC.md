# OverPass App Icon Design Specification

## Design Concept

**Theme:** Keyboard keys flowing over a bridge (overpass) - representing the app's function of passing keystrokes from one keyboard to a VM.

**Visual Elements:**
1. **Bridge/Overpass Structure** - A stylized bridge in the center
2. **Keyboard Keys** - WASD keys and arrow keys flowing over the bridge
3. **"OP" Letters** - Prominently displayed on the bridge deck
4. **Color Scheme** - Sapphire nightfall whisper palette

## Color Palette

- **Background:** Sapphire Dark (#262B40) with gradient to Sapphire Slate (#2C444D)
- **Bridge:** Sapphire Navy (#06457F) with Sapphire Royal (#0474C4) accents
- **Keys:** Sapphire Royal (#0474C4) and Sapphire Dusty (#5379AE) alternating
- **Highlights:** Sapphire Light (#A8C4EC) for "OP" letters
- **Glow Effects:** Sapphire Royal with opacity for depth

## Design Layout

```
        W  A  S  D  (approaching)
              |
        [  O  P  ]  (on bridge - prominent)
              |
        ↑  ↓  ←  →  (flowing away)
```

## Technical Specifications

### Required Icon Sizes (macOS)

All sizes need both @1x and @2x versions:

- **16x16** → 16px (@1x), 32px (@2x)
- **32x32** → 32px (@1x), 64px (@2x)  
- **128x128** → 128px (@1x), 256px (@2x)
- **256x256** → 256px (@1x), 512px (@2x)
- **512x512** → 512px (@1x), 1024px (@2x)

### Design Guidelines

1. **Readability:** Icon should be recognizable at 16x16 size
2. **Contrast:** Use sufficient contrast for visibility on dark backgrounds
3. **Simplicity:** Keep design clean and uncluttered
4. **Brand Identity:** Should clearly represent "OverPass" concept

## Implementation Options

### Option 1: Use AppIconGenerator.swift
The `AppIconGenerator.swift` file contains a SwiftUI view that can be:
1. Previewed in Xcode
2. Screenshot at 1024x1024
3. Exported and resized to all required sizes

### Option 2: Design in Graphics Tool
Use Figma, Sketch, or similar tool with these specifications:
- Base canvas: 1024x1024px
- Export at all required sizes
- Use exact hex colors from AppColors.swift

### Option 3: SF Symbols + Custom Design
Combine SF Symbols (keyboard, arrow.up.right) with custom bridge design

## Quick Start

To generate the icon using the SwiftUI view:

1. Open `AppIconGenerator.swift` in Xcode
2. Use the Preview pane
3. Take a screenshot at 1024x1024
4. Use `sips` or image editor to create all required sizes
5. Place PNG files in `OverPass/Assets.xcassets/AppIcon.appiconset/`

## File Naming Convention

For AppIcon.appiconset, name files:
- `icon_16x16.png` (16px)
- `icon_16x16@2x.png` (32px)
- `icon_32x32.png` (32px)
- `icon_32x32@2x.png` (64px)
- `icon_128x128.png` (128px)
- `icon_128x128@2x.png` (256px)
- `icon_256x256.png` (256px)
- `icon_256x256@2x.png` (512px)
- `icon_512x512.png` (512px)
- `icon_512x512@2x.png` (1024px)

Then update `Contents.json` to reference these files.
