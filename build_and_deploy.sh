#!/bin/bash

# OverPass Build and Deploy Script
# Automatically increments version, builds app, and deploys to Desktop
# Usage: ./build_and_deploy.sh

# Don't use set -e because we want to handle errors manually

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/version.txt"
PROJECT_DIR="$SCRIPT_DIR"
DESKTOP_DIR="$HOME/Desktop"
BUILD_LOGS_DIR="$DESKTOP_DIR/xCode Build Logs"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== OverPass Build and Deploy Script ===${NC}"

# Read current version
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo -e "${BLUE}Current version: ${CURRENT_VERSION}${NC}"

# Increment patch version
# Parse version string safely using parameter expansion instead of here-document
VERSION_PARTS=($(echo "$CURRENT_VERSION" | tr '.' ' '))
MAJOR=${VERSION_PARTS[0]:-1}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# Ensure we have valid numbers (default to 1.0.0 if parsing fails)
if [ -z "$MAJOR" ] || [ "$MAJOR" = "" ]; then
    MAJOR=1
fi
if [ -z "$MINOR" ] || [ "$MINOR" = "" ]; then
    MINOR=0
fi
if [ -z "$PATCH" ] || [ "$PATCH" = "" ]; then
    PATCH=0
fi

NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo -e "${BLUE}New version: ${NEW_VERSION}${NC}"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"
echo -e "${GREEN}✓ Version file updated${NC}"

# Build the app using xcodebuild
echo -e "${BLUE}Building OverPass...${NC}"

# Check if Xcode project exists
if [ ! -d "$PROJECT_DIR/OverPass.xcodeproj" ]; then
    echo -e "${YELLOW}Warning: Xcode project not found. You may need to create it in Xcode first.${NC}"
    echo -e "${YELLOW}For now, we'll prepare the structure.${NC}"
    
    # Create basic Xcode project structure if needed
    mkdir -p "$PROJECT_DIR/OverPass.xcodeproj"
    
    echo -e "${YELLOW}Please open the project in Xcode to complete setup.${NC}"
    exit 1
fi

# Build configuration
SCHEME="OverPass"
CONFIGURATION="Release"
ARCHIVE_PATH="$PROJECT_DIR/build/OverPass.xcarchive"
ARCHIVE_APP_PATH="$ARCHIVE_PATH/Products/Applications/OverPass.app"
BUILD_DIR="$PROJECT_DIR/build"
VERSIONED_APP_NAME="OverPass-v${NEW_VERSION}.app"

# Clean previous build
echo -e "${BLUE}Cleaning previous build...${NC}"
xcodebuild clean -project "$PROJECT_DIR/OverPass.xcodeproj" -scheme "$SCHEME" -configuration "$CONFIGURATION" CODE_SIGN_IDENTITY="-" 2>&1 | grep -v "^$" || true

# Build the app and capture output
echo -e "${BLUE}Building app...${NC}"
BUILD_LOG=$(mktemp)
BUILD_EXIT_CODE=0

# Use regular build with code signing (required for macOS permissions)
# Try automatic signing first, fall back to ad-hoc if needed
echo -e "${BLUE}Attempting build with automatic code signing...${NC}"
set +o pipefail  # Don't fail on pipe errors, we'll check exit code manually
xcodebuild build \
    -project "$PROJECT_DIR/OverPass.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    CODE_SIGN_STYLE=Automatic \
    ENABLE_HARDENED_RUNTIME=YES 2>&1 | tee "$BUILD_LOG"
BUILD_EXIT_CODE=${PIPESTATUS[0]}
set -o pipefail  # Restore pipefail behavior

# If automatic signing failed, try ad-hoc signing (works without development team)
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "${YELLOW}Automatic signing failed. Trying ad-hoc signing (for testing)...${NC}"
    # Create new temp file for ad-hoc build
    ADHOC_BUILD_LOG=$(mktemp)
    set +o pipefail
    xcodebuild build \
        -project "$PROJECT_DIR/OverPass.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE=Manual \
        ENABLE_HARDENED_RUNTIME=YES 2>&1 | tee "$ADHOC_BUILD_LOG"
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    set -o pipefail
    # Replace BUILD_LOG with ad-hoc build log for analysis
    mv "$ADHOC_BUILD_LOG" "$BUILD_LOG"
fi

# Find app in DerivedData (standard Xcode build location)
# Look for Release build first, then Debug, then any Products directory
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "OverPass.app" -path "*/Build/Products/Release/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    # Try Debug build
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "OverPass.app" -path "*/Build/Products/Debug/*" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    # Try any Products directory
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "OverPass.app" -path "*/Build/Products/*" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    # Try alternative build directory
    APP_PATH=$(find "$BUILD_DIR" -name "OverPass.app" -type d 2>/dev/null | head -1)
fi

# Create build logs directory if it doesn't exist
mkdir -p "$BUILD_LOGS_DIR"

# Generate timestamp for log filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILENAME="OverPass_Build_${NEW_VERSION}_${TIMESTAMP}.log"
LOG_FILEPATH="$BUILD_LOGS_DIR/$LOG_FILENAME"

# Analyze build output for warnings and errors
# Filter out simulator-related errors and Xcode internal warnings
WARNINGS=$(grep -i "warning:" "$BUILD_LOG" | grep -v "SimServiceContext\|SimDiskImageManager\|CoreSimulator\|iOSSimulator\|IDESimulator\|DVTAssertions\|DVTFilePathFSEvents\|DVTDeveloperPaths" | grep -v "^$" || true)
ERRORS=$(grep -i "error:" "$BUILD_LOG" | grep -v "SimServiceContext\|SimDiskImageManager\|CoreSimulator\|iOSSimulator\|IDESimulator\|DVTAssertions\|DVTFilePathFSEvents\|DVTDeveloperPaths\|Connection invalid\|Connection refused" | grep -i "BUILD FAILED\|ARCHIVE FAILED\|error:" | grep -v "^$" || true)

# Save full build log to file
echo "=== OverPass Build Log ===" > "$LOG_FILEPATH"
echo "Version: $NEW_VERSION" >> "$LOG_FILEPATH"
echo "Timestamp: $(date)" >> "$LOG_FILEPATH"
echo "Build Configuration: $CONFIGURATION" >> "$LOG_FILEPATH"
echo "Scheme: $SCHEME" >> "$LOG_FILEPATH"
echo "" >> "$LOG_FILEPATH"
echo "=== Full Build Output ===" >> "$LOG_FILEPATH"
cat "$BUILD_LOG" >> "$LOG_FILEPATH"

# Save warnings separately if any
if [ -n "$WARNINGS" ]; then
    echo "" >> "$LOG_FILEPATH"
    echo "=== BUILD WARNINGS ===" >> "$LOG_FILEPATH"
    echo "$WARNINGS" >> "$LOG_FILEPATH"
    echo "=== END WARNINGS ===" >> "$LOG_FILEPATH"
fi

# Save errors separately if any
if [ -n "$ERRORS" ]; then
    echo "" >> "$LOG_FILEPATH"
    echo "=== BUILD ERRORS ===" >> "$LOG_FILEPATH"
    echo "$ERRORS" >> "$LOG_FILEPATH"
    echo "=== END ERRORS ===" >> "$LOG_FILEPATH"
fi

echo -e "${GREEN}✓ Build log saved to: $LOG_FILEPATH${NC}"

# Display warnings if any
if [ -n "$WARNINGS" ]; then
    echo ""
    echo -e "${YELLOW}=== BUILD WARNINGS ===${NC}"
    echo "$WARNINGS" | while IFS= read -r line; do
        echo -e "${YELLOW}$line${NC}"
    done
    echo -e "${YELLOW}=== END WARNINGS ===${NC}"
    echo ""
fi

# Check build exit code first
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Build failed with exit code: $BUILD_EXIT_CODE${NC}"
    
    # Display errors if any
    if [ -n "$ERRORS" ]; then
        echo ""
        echo -e "${RED}=== BUILD ERRORS ===${NC}"
        echo "$ERRORS" | while IFS= read -r line; do
            echo -e "${RED}$line${NC}"
        done
        echo -e "${RED}=== END ERRORS ===${NC}"
        echo ""
    fi
    
    # Check if app was actually built despite exit code
    if [ ! -d "$APP_PATH" ]; then
        rm -f "$BUILD_LOG"
        exit 1
    else
        echo -e "${YELLOW}Build reported errors but app was created. Continuing...${NC}"
    fi
fi

# Display errors if any (but don't exit if app was built)
if [ -n "$ERRORS" ] && [ ! -d "$APP_PATH" ]; then
    echo ""
    echo -e "${RED}=== BUILD ERRORS ===${NC}"
    echo "$ERRORS" | while IFS= read -r line; do
        echo -e "${RED}$line${NC}"
    done
    echo -e "${RED}=== END ERRORS ===${NC}"
    echo ""
    rm -f "$BUILD_LOG"
    exit 1
fi

# Report build status
if [ -n "$WARNINGS" ]; then
    echo -e "${YELLOW}✓ Build successful with warnings${NC}"
else
    echo -e "${GREEN}✓ Build successful (no warnings)${NC}"
fi

# Clean up build log
rm -f "$BUILD_LOG"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Could not find built app at expected location.${NC}"
    echo -e "${YELLOW}Please build manually in Xcode first to ensure project is configured correctly.${NC}"
    rm -f "$BUILD_LOG"
    exit 1
fi

# Update version in Info.plist inside the app bundle
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$APP_PATH/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_PATCH" "$APP_PATH/Contents/Info.plist"
    echo -e "${GREEN}✓ Version updated in app bundle${NC}"
    
    # Re-sign the app after modifying Info.plist (signature gets invalidated by plist changes)
    # Get the signing identity from the app's existing signature, or use Apple Development
    echo -e "${BLUE}Re-signing app after version update...${NC}"
    SIGNING_IDENTITY=$(codesign -dvv "$APP_PATH" 2>&1 | grep "Authority" | head -1 | sed 's/.*Authority=\([^)]*\).*/\1/' || echo "Apple Development")
    if [ -z "$SIGNING_IDENTITY" ] || [ "$SIGNING_IDENTITY" = "" ]; then
        SIGNING_IDENTITY="Apple Development"
    fi
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_PATH" 2>&1 | grep -v "replacing existing signature" || true
    echo -e "${GREEN}✓ App re-signed${NC}"
fi

# Copy version.txt to app bundle
mkdir -p "$APP_PATH/Contents/Resources"
cp "$VERSION_FILE" "$APP_PATH/Contents/Resources/version.txt"
echo -e "${GREEN}✓ Version file copied to app bundle${NC}"

# Get signing identity for final signing
SIGNING_IDENTITY=$(codesign -dvv "$APP_PATH" 2>&1 | grep "Authority" | head -1 | sed 's/.*Authority=\([^)]*\).*/\1/' || echo "")
if [ -z "$SIGNING_IDENTITY" ] || [ "$SIGNING_IDENTITY" = "" ]; then
    # Try to find any available signing identity
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo "Apple Development")
fi

# Re-sign the app after adding version.txt (signature gets invalidated by adding files)
echo -e "${BLUE}Re-signing app after adding version file...${NC}"
codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_PATH" 2>&1 | grep -v "replacing existing signature" || true
echo -e "${GREEN}✓ App re-signed${NC}"

# Verify signature is valid before copying
if codesign --verify --verbose "$APP_PATH" 2>&1 | grep -q "valid on disk"; then
    echo -e "${GREEN}✓ App signature verified before deployment${NC}"
else
    echo -e "${YELLOW}⚠ Warning: App signature verification failed before deployment${NC}"
fi

# Remove old versioned apps from Desktop (optional - keep last 3)
echo -e "${BLUE}Cleaning old versions from Desktop (keeping last 3)...${NC}"
ls -t "$DESKTOP_DIR"/OverPass-v*.app 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true

# Copy to Desktop with versioned name
# Use rsync to avoid resource forks and preserve structure
echo -e "${BLUE}Deploying to Desktop as ${VERSIONED_APP_NAME}...${NC}"
rm -rf "$DESKTOP_DIR/$VERSIONED_APP_NAME"

# Copy app bundle - use cp -R with proper flags to preserve structure
# rsync was causing issues with executable, so use cp instead
cp -R "$APP_PATH" "$DESKTOP_DIR/$VERSIONED_APP_NAME"

# Verify executable was copied
if [ ! -f "$DESKTOP_DIR/$VERSIONED_APP_NAME/Contents/MacOS/OverPass" ]; then
    echo -e "${RED}ERROR: Executable not found in copied app!${NC}"
    echo -e "${YELLOW}Source app path: $APP_PATH${NC}"
    echo -e "${YELLOW}Checking source app...${NC}"
    ls -la "$APP_PATH/Contents/MacOS/" || echo "Source MacOS directory not found"
    exit 1
fi

# Remove any .DS_Store files first
find "$DESKTOP_DIR/$VERSIONED_APP_NAME" -name ".DS_Store" -delete 2>/dev/null || true

DEPLOYED_APP="$DESKTOP_DIR/$VERSIONED_APP_NAME"

# Re-sign the deployed app BEFORE removing attributes (signature can be invalidated by xattr removal)
echo -e "${BLUE}Re-signing deployed app...${NC}"
codesign --force --deep --sign "$SIGNING_IDENTITY" "$DEPLOYED_APP" 2>&1 | grep -v "replacing existing signature" || true

# NOW remove extended attributes AFTER signing (this prevents "damaged" error)
# Remove all extended attributes that might interfere with Gatekeeper
xattr -cr "$DEPLOYED_APP" 2>/dev/null || true

# Remove quarantine attribute specifically (this is what causes "damaged" error)
xattr -d com.apple.quarantine "$DEPLOYED_APP" 2>/dev/null || true

# Remove provenance and other Finder attributes
xattr -d com.apple.provenance "$DEPLOYED_APP" 2>/dev/null || true
xattr -d com.apple.FinderInfo "$DEPLOYED_APP" 2>/dev/null || true

# Final verification
if codesign --verify --verbose "$DEPLOYED_APP" 2>&1 | grep -q "valid on disk"; then
    echo -e "${GREEN}✓ Signature verified on deployed app${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Signature verification failed${NC}"
    echo -e "${YELLOW}   Trying alternative signing method...${NC}"
    # Try signing without --deep flag
    codesign --force --sign "$SIGNING_IDENTITY" "$DEPLOYED_APP" 2>&1 | grep -v "replacing existing signature" || true
    if codesign --verify --verbose "$DEPLOYED_APP" 2>&1 | grep -q "valid on disk"; then
        echo -e "${GREEN}✓ Signature verified with alternative method${NC}"
    else
        echo -e "${YELLOW}⚠ App deployed but signature verification failed${NC}"
        echo -e "${YELLOW}   You may need to allow the app in System Settings > Privacy & Security${NC}"
    fi
fi

echo -e "${GREEN}✓ Deployed to: $DESKTOP_DIR/$VERSIONED_APP_NAME${NC}"
echo -e "${GREEN}=== Build and Deploy Complete ===${NC}"
echo -e "${BLUE}Version: ${NEW_VERSION}${NC}"
