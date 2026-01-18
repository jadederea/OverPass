//
//  OverPassApp.swift
//  OverPass
//
//  Main application entry point
//  Version: Managed by build script
//

import SwiftUI

@main
struct OverPassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            // Remove default menu items we don't need
        }
    }
}

// AppDelegate to handle window maximization and app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger.shared
    private let permissionManager = PermissionManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.log("Application did finish launching - Version: \(AppVersion.current)", level: .info)
        
        // Check permissions on launch
        permissionManager.checkPermissions()
        
        // Request permissions if not granted
        if !permissionManager.hasAccessibilityPermission {
            logger.log("Accessibility permission not granted, requesting...", level: .warning)
            permissionManager.requestAccessibilityPermission()
        }
        
        if !permissionManager.hasInputMonitoringPermission {
            logger.log("Input Monitoring permission not granted, requesting...", level: .warning)
            permissionManager.requestInputMonitoringPermission()
        }
        
        // Configure window behavior
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first,
               let screen = NSScreen.main {
                let visibleFrame = screen.visibleFrame
                window.setFrame(visibleFrame, display: true)
                window.setFrameAutosaveName("OverPassMainWindow")
                window.makeKeyAndOrderFront(nil)
                
                // Ensure app terminates when window is closed
                window.isReleasedWhenClosed = false
            }
            
            // Set app to terminate when last window closes
            NSApplication.shared.setActivationPolicy(.regular)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.log("Application will terminate - Version: \(AppVersion.current)", level: .info)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        logger.log("Application should handle reopen - hasVisibleWindows: \(flag)", level: .info)
        
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        // Re-check permissions when app reopens (Input Monitoring requires restart)
        permissionManager.checkPermissions()
        
        return true
    }
    
    // Ensure app terminates when last window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        logger.log("Last window closed - terminating application", level: .info)
        return true
    }
    
    // Handle window closing - ensure clean shutdown
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        logger.log("Application should terminate - cleaning up", level: .info)
        
        // Stop any active detection or capture services
        // (Will be implemented when we port capture service)
        
        return .terminateNow
    }
}
