# First Launch Instructions

## If You See "App May Be Damaged" Error

This is normal for development builds. macOS Gatekeeper blocks development-signed apps. Here's the easiest fix:

### Quick Fix (Recommended)

Open Terminal and run this command (replace `v1.0.44` with your actual version):
```bash
xattr -cr ~/Desktop/OverPass-v1.0.44.app && codesign --force --deep --sign "Apple Development" ~/Desktop/OverPass-v1.0.44.app
```

Then try opening the app normally (double-click).

### Alternative: Right-Click Open

1. **Right-click** on the app in Finder
2. Select **"Open"** (not double-click)
3. If macOS shows a warning dialog, click **"Open"** in the dialog

**Note:** Replace `v1.0.44` with the actual version number of the app you're trying to open.

After the first launch, the app will open normally with a double-click.

---

## App Termination

The app is now configured to properly terminate when you click the close button:
- The app will exit completely (PID will end)
- It will not stay in the dock/activity bar
- All processes will be cleaned up

If you notice the app still staying active, please report it with logs.

---

## App Termination

The app is now configured to properly terminate when you click the close button:
- The app will exit completely (PID will end)
- It will not stay in the dock/activity bar
- All processes will be cleaned up

If you notice the app still staying active, please report it with logs.
