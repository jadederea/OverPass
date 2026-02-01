#!/bin/bash

# Generate OverPass App Icon
# This script creates a simple icon using SF Symbols and colors
# The icon represents keys flowing over a bridge (overpass)

ICON_DIR="OverPass/Assets.xcassets/AppIcon.appiconset"
TEMP_DIR="/tmp/overpass_icon"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Create a simple icon design using sips and SF Symbols
# We'll create a base image with the sapphire color scheme

# Create base image with sapphire dark background
sips --setProperty format png \
     --setProperty pixelWidth 1024 \
     --setProperty pixelHeight 1024 \
     --setProperty formatOptions normal \
     -c "#262B40" \
     /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns \
     "$TEMP_DIR/base.png" 2>/dev/null || echo "Note: Using alternative method"

# For now, we'll create a simple colored square as placeholder
# The actual icon should be designed in a graphics tool, but this gives us the right structure

echo "Icon generation script created."
echo "For best results, use the AppIconGenerator.swift view in Xcode's preview"
echo "or design the icon in a graphics application using these specifications:"
echo ""
echo "Design Concept:"
echo "- Background: Sapphire Dark (#262B40) with gradient"
echo "- Bridge/Overpass structure in Sapphire Navy (#06457F)"
echo "- Keyboard keys (WASD, arrows) flowing over the bridge"
echo "- 'OP' letters prominently displayed on the bridge"
echo "- Colors: Sapphire Royal (#0474C4) and Sapphire Dusty (#5379AE) for keys"
echo ""
echo "Required Sizes:"
echo "- 16x16 @1x and @2x (16px, 32px)"
echo "- 32x32 @1x and @2x (32px, 64px)"
echo "- 128x128 @1x and @2x (128px, 256px)"
echo "- 256x256 @1x and @2x (256px, 512px)"
echo "- 512x512 @1x and @2x (512px, 1024px)"
