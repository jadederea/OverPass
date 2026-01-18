# First Launch Instructions

## If You See "App May Be Damaged" Error

This is normal for development builds. macOS Gatekeeper blocks development-signed apps. Here are several ways to fix it:

### Method 1: Remove Quarantine Attribute (Easiest)

Open Terminal and run:
```bash
xattr -cr ~/Desktop/OverPass-v1.0.37.app
```

Then try opening the app normally (double-click).

### Method 2: Right-Click Open

1. **Right-click** on the app in Finder
2. Select **"Open"** (not double-click)
3. If macOS shows a warning dialog, click **"Open"** in the dialog

### Method 3: System Settings (if available)

1. Go to **System Settings > Privacy & Security**
2. Scroll down to **Security** section
3. Look for a message about the app being blocked
4. Click **"Open Anyway"** if it appears

### Method 4: Terminal Command (Always Works)

If the above don't work, open Terminal and run:
```bash
sudo xattr -rd com.apple.quarantine ~/Desktop/OverPass-v1.0.37.app
```

Then open the app normally.

**Note:** Replace `OverPass-v1.0.37.app` with the actual version number of the app you're trying to open.

After the first launch, the app will open normally with a double-click.

---

## App Termination

The app is now configured to properly terminate when you click the close button:
- The app will exit completely (PID will end)
- It will not stay in the dock/activity bar
- All processes will be cleaned up

If you notice the app still staying active, please report it with logs.
