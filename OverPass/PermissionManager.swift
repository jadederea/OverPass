//
//  PermissionManager.swift
//  OverPass
//
//  Manages macOS permissions (Accessibility and Input Monitoring)
//  Checks and requests permissions on app launch
//

import Foundation
import AppKit
import ApplicationServices

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasAccessibilityPermission: Bool = false
    @Published var hasInputMonitoringPermission: Bool = false
    
    private let logger = Logger.shared
    
    private init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasInputMonitoringPermission = checkInputMonitoringPermission()
        
        logger.log("Permission check - Accessibility: \(hasAccessibilityPermission), Input Monitoring: \(hasInputMonitoringPermission)", level: .info)
    }
    
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        return accessEnabled
    }
    
    func checkInputMonitoringPermission() -> Bool {
        // Input Monitoring permission check
        // Try to create an event tap - if it fails, permission is likely not granted
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, _, event, _) -> Unmanaged<CGEvent>? in
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            // If tap creation fails, permission is likely not granted
            return false
        }
        // Disable the tap immediately - we just wanted to test if we could create it
        CGEvent.tapEnable(tap: eventTap, enable: false)
        // Note: eventTap is automatically memory managed in Swift, no need to release
        return true
    }
    
    func requestAccessibilityPermission() {
        logger.log("Requesting Accessibility permission", level: .info)
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Check again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkPermissions()
        }
    }
    
    func requestInputMonitoringPermission() {
        logger.log("Requesting Input Monitoring permission", level: .info)
        
        // Input Monitoring permission requires opening System Settings
        let alert = NSAlert()
        alert.messageText = "Input Monitoring Permission Required"
        alert.informativeText = "OverPass needs Input Monitoring permission to capture keyboard input.\n\nPlease grant permission in System Settings > Privacy & Security > Input Monitoring.\n\nAfter granting permission, you'll need to restart the app."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Input Monitoring
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}
