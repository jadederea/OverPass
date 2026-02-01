#!/bin/bash

# Create simple OverPass icon using macOS built-in tools
# This creates a basic icon that can be refined later

ICON_DIR="OverPass/Assets.xcassets/AppIcon.appiconset"
TEMP_DIR="/tmp/overpass_icon_temp"
mkdir -p "$TEMP_DIR"
mkdir -p "$ICON_DIR"

echo "Creating OverPass app icon..."

# Create a 1024x1024 base image with sapphire dark background
# Using sips to create colored square
sips --setProperty format png \
     --setProperty pixelWidth 1024 \
     --setProperty pixelHeight 1024 \
     -c "#262B40" \
     /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns \
     "$TEMP_DIR/base_1024.png" 2>/dev/null

# If that doesn't work, create using a different method
if [ ! -f "$TEMP_DIR/base_1024.png" ]; then
    # Create using Python (if available) or provide instructions
    python3 << 'PYTHON_SCRIPT'
from Quartz import CGImageDestinationCreateWithURL, kCGImageTypePNG
from Quartz import CGColorSpaceCreateDeviceRGB, CGBitmapContextCreate
from Foundation import NSURL
import os

# This is a placeholder - actual implementation would use Core Graphics
print("Note: Full icon generation requires PIL or manual creation")
print("Please use AppIconGenerator.swift in Xcode Preview instead")
PYTHON_SCRIPT
fi

# Generate all required sizes from base (if base exists)
if [ -f "$TEMP_DIR/base_1024.png" ]; then
    echo "Generating icon sizes..."
    sips -z 16 16 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_16x16.png" 2>/dev/null
    sips -z 32 32 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_16x16@2x.png" 2>/dev/null
    sips -z 32 32 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_32x32.png" 2>/dev/null
    sips -z 64 64 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_32x32@2x.png" 2>/dev/null
    sips -z 128 128 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_128x128.png" 2>/dev/null
    sips -z 256 256 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_128x128@2x.png" 2>/dev/null
    sips -z 256 256 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_256x256.png" 2>/dev/null
    sips -z 512 512 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_256x256@2x.png" 2>/dev/null
    sips -z 512 512 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_512x512.png" 2>/dev/null
    sips -z 1024 1024 "$TEMP_DIR/base_1024.png" --out "$ICON_DIR/icon_512x512@2x.png" 2>/dev/null
    echo "✓ Basic icon files created"
else
    echo ""
    echo "⚠ Could not create icon automatically"
    echo ""
    echo "RECOMMENDED METHOD:"
    echo "1. Open AppIconGenerator.swift in Xcode"
    echo "2. Use Preview (⌘+Option+P)"
    echo "3. Screenshot the preview at 1024x1024"
    echo "4. Save as PNG and run this script again with the file"
    echo ""
    echo "Or install PIL and use: python3 create_icon.py"
fi

# Cleanup
rm -rf "$TEMP_DIR"
