# First Launch Instructions

## If You See "App May Be Damaged" Error

This is normal for development builds. macOS Gatekeeper blocks unsigned or development-signed apps by default.

### Solution:

1. **Right-click** on the app in Finder
2. Select **"Open"** (not double-click)
3. macOS will show a dialog saying the app is from an unidentified developer
4. Click **"Open"** in the dialog
5. The app will launch and be added to your allowed apps

**OR**

1. Go to **System Settings > Privacy & Security**
2. Scroll down to see if there's a message about the app being blocked
3. Click **"Open Anyway"** next to the OverPass app

After the first launch, the app will open normally with a double-click.

---

## App Termination

The app is now configured to properly terminate when you click the close button:
- The app will exit completely (PID will end)
- It will not stay in the dock/activity bar
- All processes will be cleaned up

If you notice the app still staying active, please report it with logs.
