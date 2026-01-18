# Code Signing Setup Guide

## Quick Answer

**You need to set up a development team in Xcode.** This is a one-time setup that will allow automatic code signing to work.

## Step-by-Step Instructions

### Option 1: Set Up Development Team in Xcode (Recommended)

1. **Open the project in Xcode:**
   - Double-click `OverPass.xcodeproj` in Finder, or
   - Open Xcode → File → Open → Select `OverPass.xcodeproj`

2. **Select the project:**
   - In the left sidebar (Project Navigator), click on the blue "OverPass" icon at the very top

3. **Select the target:**
   - In the main area, you'll see "PROJECT" and "TARGETS" sections
   - Under "TARGETS", click on "OverPass"

4. **Go to Signing & Capabilities:**
   - Click on the "Signing & Capabilities" tab at the top

5. **Set up signing:**
   - Check the box for **"Automatically manage signing"**
   - Under **"Team"**, click the dropdown
   - If you see your name/Apple ID, select it
   - If you see "Add an Account...", click it and sign in with your Apple ID

6. **Xcode will automatically:**
   - Create a development team for you (if you don't have one)
   - Set up code signing certificates
   - Configure the project

7. **Save:**
   - Xcode saves automatically, so you're done!

### Option 2: Sign In to Xcode First (If you don't see your Apple ID)

1. **Open Xcode Settings:**
   - Xcode → Settings (or Preferences on older versions)
   - Click the "Accounts" tab

2. **Add your Apple ID:**
   - Click the "+" button in the bottom left
   - Select "Apple ID"
   - Enter your Apple ID email and password
   - Click "Sign In"

3. **Xcode will create a team:**
   - After signing in, Xcode automatically creates a "Personal Team" for you
   - This team name will be something like "Your Name (Personal Team)"

4. **Then go back to Option 1, Step 5** to select this team in your project

## What This Does

- **Enables automatic code signing** - No more "requires a development team" errors
- **Creates signing certificates** - Xcode manages these automatically
- **Allows app to request permissions** - Required for Accessibility and Input Monitoring permissions
- **Works for testing** - Personal teams work fine for development and testing

## After Setup

Once you've set up the development team:
- The build script will use automatic signing (no more fallback to ad-hoc)
- You can build directly in Xcode without errors
- The app will be properly signed for macOS permissions

## Notes

- **Free**: Personal teams are free - no Apple Developer Program membership needed for testing
- **Automatic**: Xcode manages certificates automatically when "Automatically manage signing" is checked
- **One-time**: Once set up, you won't need to do this again unless you change Apple IDs

## Troubleshooting

**"No accounts with Apple IDs"**
- Make sure you've signed in to Xcode (Xcode → Settings → Accounts)

**"No teams available"**
- Sign in with your Apple ID in Xcode Settings first
- Xcode will create a personal team automatically

**"Failed to create provisioning profile"**
- Make sure "Automatically manage signing" is checked
- Try cleaning the build folder (Product → Clean Build Folder)

## Current Status

Right now, the build script automatically falls back to **ad-hoc signing** when no development team is set. This works for testing, but setting up a proper development team is recommended for:
- Better permission handling
- More reliable builds
- Production-ready apps
