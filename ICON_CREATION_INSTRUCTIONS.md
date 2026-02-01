# OverPass App Icon Creation Instructions

## Quick Method: Use SwiftUI Preview

The easiest way to create the icon is using the `AppIconGenerator.swift` file:

1. **Open Xcode** and open `AppIconGenerator.swift`
2. **Enable Preview** (⌘+Option+P or click the Preview button)
3. **Set Preview to 512x512** or 1024x1024 size
4. **Take a screenshot** of the preview (⌘+Shift+4, then Space, click the preview)
5. **Save the screenshot** as a PNG

## Icon Design

The icon features:
- **Bridge/Overpass** structure in the center (Sapphire Navy/Royal)
- **"OP" letters** prominently displayed on the bridge (Sapphire Light)
- **Keyboard keys** (WASD and arrows) flowing over the bridge
- **Sapphire color scheme** matching your app's theme

## Generate All Sizes

Once you have the 1024x1024 icon, use this command to generate all required sizes:

```bash
cd ~/OverPass
ICON_FILE="your_icon_1024x1024.png"
ICON_DIR="OverPass/Assets.xcassets/AppIcon.appiconset"

# Generate all sizes using sips
sips -z 16 16 "$ICON_FILE" --out "$ICON_DIR/icon_16x16.png"
sips -z 32 32 "$ICON_FILE" --out "$ICON_DIR/icon_16x16@2x.png"
sips -z 32 32 "$ICON_FILE" --out "$ICON_DIR/icon_32x32.png"
sips -z 64 64 "$ICON_FILE" --out "$ICON_DIR/icon_32x32@2x.png"
sips -z 128 128 "$ICON_FILE" --out "$ICON_DIR/icon_128x128.png"
sips -z 256 256 "$ICON_FILE" --out "$ICON_DIR/icon_128x128@2x.png"
sips -z 256 256 "$ICON_FILE" --out "$ICON_DIR/icon_256x256.png"
sips -z 512 512 "$ICON_FILE" --out "$ICON_DIR/icon_256x256@2x.png"
sips -z 512 512 "$ICON_FILE" --out "$ICON_DIR/icon_512x512.png"
sips -z 1024 1024 "$ICON_FILE" --out "$ICON_DIR/icon_512x512@2x.png"
```

## Alternative: Install PIL and Use Python Script

If you prefer the automated Python script:

```bash
pip3 install Pillow
python3 create_icon.py
```

This will generate all icon sizes automatically.

## Update Contents.json

After generating the icons, update `Contents.json` to reference the new files. The file structure should match the icon filenames.

## Design Colors Reference

- Background: #262B40 (Sapphire Dark)
- Bridge: #06457F (Sapphire Navy) with #0474C4 (Sapphire Royal) accents
- Keys: #0474C4 (Sapphire Royal) and #5379AE (Sapphire Dusty)
- OP Letters: #A8C4EC (Sapphire Light)
