//
//  KeyboardCaptureService.swift
//  OverPass
//
//  Service for capturing and blocking keyboard input from a specific device
//  Based on KeyRelay's working implementation using HID + CGEvent correlation
//

import Foundation
import AppKit
import CoreGraphics
import IOKit
import IOKit.hid

// MARK: - Parallels Data Structures

enum ParallelsVMStatus {
    case running
    case stopped
    case suspended
    case unknown
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .suspended: return "Suspended"
        case .unknown: return "Unknown"
        }
    }
}

struct ParallelsVM: Identifiable, Hashable {
    let id = UUID()
    let uuid: String
    let name: String
    let status: ParallelsVMStatus
    
    var isRunning: Bool {
        return status == .running
    }
}

@MainActor
class KeyboardCaptureService: ObservableObject {
    static let shared = KeyboardCaptureService()
    
    @Published var isCapturing = false
    @Published var capturedEventCount = 0
    @Published var capturedEvents: [CapturedKeyEvent] = []
    
    // Relay mode properties
    @Published var isRelayMode = false  // Toggle between capture-only and relay modes
    @Published var targetVM: ParallelsVM?  // Target VM for keystroke relay
    @Published var availableVMs: [ParallelsVM] = []  // List of available VMs
    
    // Format captured keystrokes for clipboard
    func copyKeystrokeHistoryToClipboard() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        var historyText = "OverPass Keystroke History\n"
        historyText += "Generated: \(Date())\n"
        historyText += "Total Keystrokes: \(capturedEventCount)\n"
        historyText += "========================================\n\n"
        
        for event in capturedEvents {
            let timeStr = formatter.string(from: event.timestamp)
            historyText += "[\(timeStr)] \(event.key) (\(event.event))\n"
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(historyText, forType: .string)
        
        logger.log("Keystroke history copied to clipboard - \(capturedEventCount) events", level: .info)
    }
    
    private var hidManager: IOHIDManager?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var targetDevice: KeyboardDevice?
    private let logger = Logger.shared
    private var maxHistorySize = 1000
    
    // Relay queue - allow 2 concurrent prlctl to reduce lag during rapid key presses
    // Serial was causing "lag then burst" when many keys queued (each prlctl ~150ms)
    private let relayOperationQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.overpass.relay"
        q.maxConcurrentOperationCount = 2  // Parallelism reduces backlog, 2 is safe for Parallels
        q.qualityOfService = .userInteractive
        return q
    }()
    
    // O(1) event correlation for blocking - replaces O(n) array iteration
    // Event tap callback runs for EVERY system key event; must be very fast
    private var lastHIDKeyDownTime: [Int: Date] = [:]  // keyCode -> timestamp
    private var lastHIDKeyUpTime: [Int: Date] = [:]    // keyCode -> timestamp
    private let correlationLock = NSLock()  // Protects the maps from HID vs CGEvent threads
    
    // Track pressed keys to allow key repeats for continuous movement
    private var pressedKeys: Set<Int> = [] // Track which keys are currently pressed
    
    // Track previous HID state to detect key up events
    // HID keyboards send state reports - we need to compare current vs previous state
    private var previousHIDState: [Int: Bool] = [:] // keyCode -> wasPressed
    
    // Periodic cleanup to prevent degradation over time (stale state accumulation)
    private var cleanupTimer: Timer?
    private let maxCorrelationMapSize = 50  // Prune if we exceed this many keys
    
    struct CapturedKeyEvent: Identifiable {
        let id: String
        let key: String
        let event: String // "down" or "up"
        let timestamp: Date
        let keyCode: Int64
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startCapture(targetDevice: KeyboardDevice) {
        guard !isCapturing else {
            logger.log("Capture already active", level: .warning)
            return
        }
        
        self.targetDevice = targetDevice
        logger.log("Starting keyboard capture for device: \(targetDevice.name) (ID: \(targetDevice.id))", level: .info)
        
        // Check permissions
        guard PermissionManager.shared.hasInputMonitoringPermission else {
            logger.log("Input Monitoring permission not granted - cannot capture", level: .error)
            return
        }
        
        // Start both HID monitoring AND system-wide blocking
        logger.log("Starting hybrid capture: HID monitoring + System-wide event blocking", level: .info)
        
        let hidSuccess = startDeviceSpecificCapture(for: targetDevice)
        let blockingSuccess = startSystemWideEventBlocking()
        
        if hidSuccess && blockingSuccess {
            logger.log("Hybrid capture started successfully - Device monitoring + Event blocking active", level: .info)
            isCapturing = true
            capturedEventCount = 0
            capturedEvents.removeAll()
            correlationLock.lock()
            lastHIDKeyDownTime.removeAll()
            lastHIDKeyUpTime.removeAll()
            correlationLock.unlock()
            startPeriodicCleanup()
        } else if hidSuccess {
            logger.log("Partial success - Device monitoring active, but event blocking failed", level: .warning)
            isCapturing = true
        } else if blockingSuccess {
            logger.log("Partial success - Event blocking active, but device monitoring failed", level: .warning)
            isCapturing = true
        } else {
            logger.log("Both HID monitoring and event blocking failed", level: .error)
        }
    }
    
    func stopCapture() {
        guard isCapturing else {
            logger.log("Capture not active", level: .warning)
            return
        }
        
        logger.log("Stopping keyboard capture - Total events captured: \(capturedEventCount)", level: .info)
        
        // Stop HID capture
        if let hidManager = hidManager {
            IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            self.hidManager = nil
        }
        
        // Stop event blocking
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        isCapturing = false
        targetDevice = nil
        correlationLock.lock()
        lastHIDKeyDownTime.removeAll()
        lastHIDKeyUpTime.removeAll()
        correlationLock.unlock()
        pressedKeys.removeAll() // Clear pressed keys when stopping
        previousHIDState.removeAll() // Clear previous HID state
        stopPeriodicCleanup()
    }
    
    private func startPeriodicCleanup() {
        stopPeriodicCleanup()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.performCorrelationCleanup()
        }
        RunLoop.current.add(cleanupTimer!, forMode: .common)
    }
    
    private func stopPeriodicCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    /// Prune stale correlation data to prevent degradation over time
    private func performCorrelationCleanup() {
        guard isCapturing else { return }
        
        let cutoff = Date().addingTimeInterval(-30.0)  // Remove entries older than 30 seconds
        
        correlationLock.lock()
        var pruned = 0
        for (keyCode, time) in lastHIDKeyDownTime {
            if time < cutoff {
                lastHIDKeyDownTime.removeValue(forKey: keyCode)
                pruned += 1
            }
        }
        for (keyCode, time) in lastHIDKeyUpTime {
            if time < cutoff {
                lastHIDKeyUpTime.removeValue(forKey: keyCode)
                pruned += 1
            }
        }
        // Also prune if maps grew too large (rapid key churn)
        if lastHIDKeyDownTime.count > maxCorrelationMapSize {
            let sorted = lastHIDKeyDownTime.sorted { $0.value < $1.value }
            let toRemove = sorted.prefix(lastHIDKeyDownTime.count - maxCorrelationMapSize)
            for (k, _) in toRemove {
                lastHIDKeyDownTime.removeValue(forKey: k)
                lastHIDKeyUpTime.removeValue(forKey: k)
                pruned += 1
            }
        }
        correlationLock.unlock()
        
        if pruned > 0 {
            logger.log("Correlation cleanup: pruned \(pruned) stale entries", level: .debug)
        }
    }
    
    func clearHistory() {
        capturedEvents.removeAll()
        logger.log("Cleared keystroke history", level: .info)
    }
    
    // MARK: - HID Capture Setup
    
    private func startDeviceSpecificCapture(for device: KeyboardDevice) -> Bool {
        logger.log("Attempting device-specific HID monitoring for: \(device.name)", level: .info)
        
        // Create HID Manager
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let hidManager = hidManager else {
            logger.log("Failed to create HID Manager", level: .error)
            return false
        }
        
        // Set matching criteria for keyboards
        let matching: [String: Any] = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard
        ]
        
        IOHIDManagerSetDeviceMatching(hidManager, matching as CFDictionary)
        
        // Open HID manager
        let result = IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            logger.log("Failed to open HID Manager: \(ioKitErrorDescription(result))", level: .error)
            self.hidManager = nil
            return false
        }
        
        // Schedule on run loop
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        // Register input callback
        IOHIDManagerRegisterInputValueCallback(hidManager, { (context, result, sender, value) in
            guard let context = context else { return }
            let service = Unmanaged<KeyboardCaptureService>.fromOpaque(context).takeUnretainedValue()
            if let device = sender {
                service.handleHIDInput(value: value, device: Unmanaged<IOHIDDevice>.fromOpaque(device).takeUnretainedValue())
            }
        }, Unmanaged.passUnretained(self).toOpaque())
        
        logger.log("HID capture setup complete", level: .info)
        return true
    }
    
    // MARK: - Event Blocking Setup
    
    private func startSystemWideEventBlocking() -> Bool {
        logger.log("Starting system-wide event blocking for keystroke interception...", level: .info)
        
        // Create event tap for key down and key up events with blocking capability
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,  // Allow both monitoring and blocking
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<KeyboardCaptureService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleKeyEventWithBlocking(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            logger.log("Failed to create event tap for blocking - check Input Monitoring permission", level: .error)
            return false
        }
        
        logger.log("Event tap created successfully for blocking", level: .info)
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            logger.log("Failed to create run loop source for blocking", level: .error)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            return false
        }
        
        // Enable the tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        logger.log("System-wide event blocking started successfully", level: .info)
        return true
    }
    
    // MARK: - HID Input Handling
    
    private func handleHIDInput(value: IOHIDValue, device: IOHIDDevice) {
        // Get device name
        guard let deviceName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String else {
            return
        }
        
        // Check if this is from our target device
        guard let targetDevice = targetDevice,
              deviceName == targetDevice.name else {
            // Not from target device, ignore
            return
        }
        
        let element = IOHIDValueGetElement(value)
        let intValue = IOHIDValueGetIntegerValue(value)
        
        // Get key code
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        
        guard usagePage == kHIDPage_KeyboardOrKeypad else { return }
        
        // Filter out rollover events (0xFFFFFFFF) - these cause duplicate key presses
        if usage == 4294967295 { // 0xFFFFFFFF
            logger.log("Ignoring rollover event: Usage=\(usage) - these cause duplicate key presses", level: .debug)
            return
        }
        
        // Convert HID usage to key code with error handling
        let keyCode: Int
        do {
            keyCode = try usageToKeyCode(usage)
        } catch {
            logger.log("Failed to convert HID usage \(usage) (0x\(String(usage, radix: 16))) to key code: \(error)", level: .error)
            return // Skip this event if we can't convert it
        }
        let keyName = getKeyName(from: Int64(keyCode))
        
        // CRITICAL: HID keyboards send state reports with ALL keys, not individual events
        // We need to compare current state with previous state to detect key down/up transitions
        let isCurrentlyPressed = (intValue > 0)
        let wasPreviouslyPressed = previousHIDState[keyCode] ?? false
        
        // Update state tracking
        previousHIDState[keyCode] = isCurrentlyPressed
        
        // Only process state transitions (key down or key up), not steady states
        if isCurrentlyPressed && !wasPreviouslyPressed {
            // Key DOWN transition: key was not pressed, now it is
            logger.log("HID key DOWN: \(keyName) (keyCode=\(keyCode)) - transition detected", level: .debug)
            
            // Track key state for blocking
            if !pressedKeys.contains(keyCode) {
                pressedKeys.insert(keyCode)
                logger.log("Key \(keyName) (keyCode=\(keyCode)) added to pressedKeys", level: .debug)
            }
            
            // Record HID key down for O(1) correlation (critical for fast event tap callback)
            let currentTime = Date()
            correlationLock.lock()
            lastHIDKeyDownTime[keyCode] = currentTime
            correlationLock.unlock()
            
            // Capture key down event for UI
            let capturedEvent = CapturedKeyEvent(
                id: UUID().uuidString,
                key: keyName,
                event: "down",
                timestamp: currentTime,
                keyCode: Int64(keyCode)
            )
            
            DispatchQueue.main.async {
                self.capturedEventCount += 1
                self.capturedEvents.append(capturedEvent)
                if self.capturedEvents.count > self.maxHistorySize {
                    self.capturedEvents.removeFirst()
                }
            }
            
            logger.log("Captured key down: \(keyName) from device: \(deviceName)", level: .debug)
            
            // If in relay mode, send key to Parallels VM
            if isRelayMode, let vm = targetVM {
                sendKeyToParallelsVM(vm: vm, keyCode: keyCode, isKeyDown: true)
            }
            
        } else if !isCurrentlyPressed && wasPreviouslyPressed {
            // Key UP transition: key was pressed, now it's not
            logger.log("HID key UP: \(keyName) (keyCode=\(keyCode)) - transition detected", level: .debug)
            
            // Remove from pressed keys
            if pressedKeys.contains(keyCode) {
                pressedKeys.remove(keyCode)
                logger.log("Key \(keyName) (keyCode=\(keyCode)) removed from pressedKeys", level: .debug)
            }
            
            // Record HID key up for O(1) correlation
            let currentTime = Date()
            correlationLock.lock()
            lastHIDKeyUpTime[keyCode] = currentTime
            correlationLock.unlock()
            
            // Capture key up event for UI
            let capturedEvent = CapturedKeyEvent(
                id: UUID().uuidString,
                key: keyName,
                event: "up",
                timestamp: currentTime,
                keyCode: Int64(keyCode)
            )
            
            DispatchQueue.main.async {
                self.capturedEventCount += 1
                self.capturedEvents.append(capturedEvent)
                if self.capturedEvents.count > self.maxHistorySize {
                    self.capturedEvents.removeFirst()
                }
            }
            
            logger.log("Captured key up: \(keyName) from device: \(deviceName)", level: .debug)
            
            // If in relay mode, send key release to Parallels VM
            if isRelayMode, let vm = targetVM {
                sendKeyToParallelsVM(vm: vm, keyCode: keyCode, isKeyDown: false)
            }
            
        } else {
            // No state change - key is either still pressed or still not pressed
            // This is a steady state, not a transition - ignore it
            // (We only care about transitions for key down/up detection)
            return
        }
        
    }
    
    // MARK: - Event Blocking
    
    private func handleKeyEventWithBlocking(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Only process keyDown and keyUp
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        
        guard let targetDevice = targetDevice, isCapturing else {
            // No target device or not capturing, pass through all events
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isKeyDown = (type == .keyDown)
        let eventTimestamp = Date()
        let keyName = getKeyName(from: keyCode)
        
        // CRITICAL: Check if this event is from the built-in keyboard
        // We can't directly identify the source device from CGEvent, but we can use timing correlation
        // If a key is NOT in pressedKeys and there's NO recent HID correlation, it's likely from built-in keyboard
        // Only block if we have strong evidence it's from the target device
        
        // Check if this CGEvent should be blocked (from target device)
        // For blocking mode: block ALL events (including repeats) from target device
        let shouldBlock = hasDirectHIDCorrelation(keyCode: Int(keyCode), isKeyDown: isKeyDown, eventTimestamp: eventTimestamp, allowRepeats: false)
        
        if shouldBlock {
            logger.log("Blocking event: keyCode=\(keyCode) (\(keyName)), isKeyDown=\(isKeyDown) from device: \(targetDevice.name)", level: .debug)
            
            // DON'T capture here - we already capture from HID events in handleHIDInput
            // Capturing here would cause duplicates. We only use CGEvent for blocking.
            
            // Return nil to block the event from reaching macOS
            return nil
        } else {
            // Return the event to allow normal processing (e.g., from built-in keyboard)
            return Unmanaged.passUnretained(event)
        }
    }
    
    /// Check if a CGEvent should be blocked (from target device)
    /// OPTIMIZED: O(1) lookup - event tap runs for EVERY system key event, must be very fast
    /// Prevents blocking built-in keyboard; only blocks events with strong HID correlation
    private func hasDirectHIDCorrelation(keyCode: Int, isKeyDown: Bool, eventTimestamp: Date, allowRepeats: Bool = false) -> Bool {
        guard targetDevice != nil else {
            return false
        }
        
        if isKeyDown {
            // O(1) lookup for key down correlation
            correlationLock.lock()
            let lastDown = lastHIDKeyDownTime[keyCode]
            correlationLock.unlock()
            // First check: Key in pressedKeys = we captured it from HID, block all repeats
            if pressedKeys.contains(keyCode) {
                // Verify we have recent HID key down (within 10s for long holds)
                let repeatTimeWindow: TimeInterval = 10.0
                if let downTime = lastDown, eventTimestamp.timeIntervalSince(downTime) <= repeatTimeWindow {
                    return true
                }
                // Stale - remove and allow through (prevents stuck state)
                pressedKeys.remove(keyCode)
                return false
            }
            
            // Second check: Initial press - HID key down within 80ms (wider than 30ms for load tolerance)
            let initialTimeWindow: TimeInterval = 0.08
            if let downTime = lastDown, eventTimestamp.timeIntervalSince(downTime) <= initialTimeWindow {
                pressedKeys.insert(keyCode)
                return true
            }
            
            return false
        } else {
            // Key up: block if key is in pressedKeys (we captured key down from HID)
            // Don't require lastUp - CGEvent can arrive before HID callback, causing missed blocks
            // Note: Don't add to capturedEvents here - HID path already captures key up
            if pressedKeys.contains(keyCode) {
                pressedKeys.remove(keyCode)
                return true
            }
            return false
        }
    }
    
    // MARK: - Parallels Integration
    
    /// Get list of available Parallels VMs
    func getAvailableVMs() -> [ParallelsVM] {
        logger.log("Getting available Parallels VMs...", level: .info)
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/prlctl")
        task.arguments = ["list", "--all"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            logger.log("prlctl output: \(output)", level: .debug)
            
            var vms: [ParallelsVM] = []
            let lines = output.split(separator: "\n")
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("UUID") { continue }
                
                let components = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                guard components.count >= 3 else { continue }
                
                let uuid = String(components[0])
                let status = String(components[1])
                let name = String(components[2])
                
                let vmStatus: ParallelsVMStatus = {
                    switch status.lowercased() {
                    case "running": return .running
                    case "stopped": return .stopped
                    case "suspended": return .suspended
                    default: return .unknown
                    }
                }()
                
                let vm = ParallelsVM(
                    uuid: uuid,
                    name: name,
                    status: vmStatus
                )
                vms.append(vm)
            }
            
            logger.log("Found \(vms.count) Parallels VMs", level: .info)
            return vms
        } catch {
            logger.log("Failed to get Parallels VMs: \(error)", level: .error)
            return []
        }
    }
    
    /// Refresh the list of available Parallels VMs
    func refreshParallelsVMs() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let vms = self.getAvailableVMs()
            DispatchQueue.main.async {
                self.availableVMs = vms
            }
        }
    }
    
    /// Send a keystroke to the specified VM
    func sendKeyToParallelsVM(vm: ParallelsVM, keyCode: Int, isKeyDown: Bool) {
        guard vm.status == .running else {
            logger.log("Cannot send key event - VM not running", level: .error)
            return
        }
        
        relayOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            let scanCode = self.convertToScanCode(keyCode)
            let scanCodeFormatted = self.formatScanCodeForVM(scanCode)
            let keyName = self.getKeyName(from: Int64(keyCode))
            let eventType = isKeyDown ? "press" : "release"
            
            logger.log("RELAY: \(keyName) (\(eventType)) HID \(keyCode) → scan \(scanCode) to VM \(vm.name)", level: .info)
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/local/bin/prlctl")
            task.arguments = ["send-key-event", vm.uuid, "--scancode", scanCodeFormatted, "--event", eventType]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            do {
                let startTime = Date()
                try task.run()
                task.waitUntilExit()
                let duration = Date().timeIntervalSince(startTime)
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if task.terminationStatus != 0 {
                    logger.log("prlctl command failed for scan code \(scanCode) - status: \(task.terminationStatus)", level: .error)
                    if !errorOutput.isEmpty {
                        logger.log("prlctl error: \(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))", level: .error)
                    }
                } else {
                    logger.log("prlctl command succeeded for scan code \(scanCode) in \(String(format: "%.3f", duration))s", level: .debug)
                }
            } catch {
                logger.log("Failed to execute prlctl: \(error)", level: .error)
            }
        }
    }
    
    /// Convert macOS key code to Windows scan code (QWERTY layout)
    /// CRITICAL: Scan codes follow QWERTY layout, NOT macOS key code layout
    /// This function receives macOS key codes (from usageToKeyCode), NOT HID usage codes
    private func convertToScanCode(_ keyCode: Int) -> Int {
        switch keyCode {
        // Letters A-Z (macOS key codes from usageToKeyCode)
        case 0: return 30    // A
        case 11: return 48   // B
        case 8: return 46    // C
        case 2: return 32    // D
        case 14: return 18   // E
        case 3: return 33    // F
        case 5: return 34    // G
        case 4: return 35    // H
        case 34: return 23   // I
        case 38: return 36   // J
        case 40: return 37   // K
        case 37: return 38   // L
        case 46: return 50   // M
        case 45: return 49   // N
        case 31: return 24   // O
        case 35: return 25   // P
        case 12: return 16   // Q
        case 15: return 19   // R
        case 1: return 31    // S
        case 17: return 20   // T
        case 32: return 22   // U
        case 9: return 47    // V
        case 13: return 17   // W (FIXED: was 36/J, now 17/W)
        case 7: return 45    // X
        case 16: return 21   // Y
        case 6: return 44    // Z
        
        // Numbers 1-0 (macOS key codes)
        case 18: return 2    // 1
        case 19: return 3    // 2
        case 20: return 4    // 3
        case 21: return 5    // 4
        case 23: return 6    // 5
        case 22: return 7    // 6
        case 26: return 8    // 7
        case 28: return 9    // 8
        case 25: return 10   // 9
        case 29: return 11   // 0
        
        // Special keys (macOS key codes)
        case 36: return 28   // Return/Enter
        case 53: return 1    // Escape
        case 51: return 14   // Delete/Backspace
        case 48: return 15   // Tab
        case 49: return 57   // Space (FIXED: was 43/\, now 57/Space)
        case 27: return 12   // - (minus/hyphen)
        case 24: return 13   // = (equals)
        case 33: return 26   // [ (left bracket)
        case 30: return 27   // ] (right bracket)
        case 42: return 43   // \ (backslash)
        case 41: return 39   // ; (semicolon)
        case 39: return 40   // ' (quote/apostrophe)
        case 50: return 41   // ` (grave accent/backtick)
        case 43: return 51   // ,
        case 47: return 52   // .
        case 44: return 53   // /
        case 57: return 58   // Caps Lock
        
        // Arrow keys (macOS key codes)
        case 124: return 77  // Right Arrow
        case 123: return 75  // Left Arrow
        case 125: return 80  // Down Arrow
        case 126: return 72  // Up Arrow
        
        // Function keys (macOS key codes) - common ones
        case 64: return 59   // F1
        case 65: return 60   // F2
        case 66: return 61   // F3
        case 67: return 62   // F4
        case 68: return 63   // F5
        case 69: return 64   // F6
        case 70: return 65   // F7
        case 71: return 66   // F8
        case 72: return 67   // F9
        case 73: return 68   // F10
        case 74: return 87   // F11
        case 75: return 88   // F12
        
        // Other special keys
        case 76: return 211  // Forward Delete (Fn+Delete on some keyboards)
        
        default:
            logger.log("RELAY: Unknown macOS key code to scan code mapping: \(keyCode), using 30 (A) as fallback", level: .warning)
            return 30 // Default to 'A' key scan code if unknown
        }
    }
    
    /// Format scan code for Parallels VM - use decimal format
    private func formatScanCodeForVM(_ scanCode: Int) -> String {
        return String(scanCode)
    }
    
    // MARK: - Helper Methods
    
    private func usageToKeyCode(_ usage: UInt32) throws -> Int {
        // Map HID usage codes to macOS key codes
        // Use safe arithmetic to prevent overflow
        
        // First, check if usage is within reasonable bounds (most HID keyboard usage codes are < 0xFFFF)
        // But allow up to UInt32.max and handle it safely
        guard usage <= UInt32.max else {
            throw NSError(domain: "KeyboardCaptureService", code: 1, userInfo: [NSLocalizedDescriptionKey: "HID usage code \(usage) exceeds maximum"])
        }
        
        // Convert to Int64 first to ensure we can handle the value safely
        let usageInt = Int64(usage)
        
        // HID usage codes to macOS key codes mapping
        // HID usage codes 0x04-0x1D are A-Z, but macOS key codes are NOT sequential
        switch usage {
        // Letters A-Z (HID 0x04-0x1D)
        case 0x04: return 0  // A
        case 0x05: return 11 // B
        case 0x06: return 8  // C
        case 0x07: return 2  // D
        case 0x08: return 14 // E
        case 0x09: return 3  // F
        case 0x0A: return 5  // G
        case 0x0B: return 4  // H
        case 0x0C: return 34 // I
        case 0x0D: return 38 // J
        case 0x0E: return 40 // K
        case 0x0F: return 37 // L
        case 0x10: return 46 // M
        case 0x11: return 45 // N
        case 0x12: return 31 // O
        case 0x13: return 35 // P
        case 0x14: return 12 // Q
        case 0x15: return 15 // R
        case 0x16: return 1  // S
        case 0x17: return 17 // T
        case 0x18: return 32 // U
        case 0x19: return 9  // V
        case 0x1A: return 13 // W
        case 0x1B: return 7  // X
        case 0x1C: return 16 // Y
        case 0x1D: return 6  // Z
        
        // Numbers 1-9, 0 (HID 0x1E-0x27)
        case 0x1E: return 18 // 1
        case 0x1F: return 19 // 2
        case 0x20: return 20 // 3
        case 0x21: return 21 // 4
        case 0x22: return 23 // 5
        case 0x23: return 22 // 6
        case 0x24: return 26 // 7
        case 0x25: return 28 // 8
        case 0x26: return 25 // 9
        case 0x27: return 29 // 0
        
        // Special keys
        case 0x28: return 36 // Return/Enter
        case 0x29: return 53 // Escape
        case 0x2A: return 51 // Delete/Backspace
        case 0x2B: return 48 // Tab
        case 0x2C: return 49 // Space
        case 0x2D: return 27 // -
        case 0x2E: return 24 // =
        case 0x2F: return 33 // [
        case 0x30: return 30 // ]
        case 0x31: return 42 // \
        case 0x33: return 41 // ; (semicolon)
        case 0x34: return 39 // ' (apostrophe)
        case 0x35: return 50 // ` (backtick)
        case 0x36: return 43 // ,
        case 0x37: return 47 // .
        case 0x38: return 44 // /
        case 0x39: return 57 // Caps Lock
        case 0x4F: return 124 // Right Arrow
        case 0x50: return 123 // Left Arrow
        case 0x51: return 125 // Down Arrow
        case 0x52: return 126 // Up Arrow
        default:
            // For unmapped usage codes, check if it's a reasonable value
            // macOS key codes are typically 0-127, but some special keys go higher
            if usageInt <= 127 {
                // If it's a small value, use it directly
                return Int(usageInt)
            } else {
                // For larger unmapped values, log and return a safe default
                logger.log("Unmapped HID usage code: \(usage) (0x\(String(usage, radix: 16))), using default key code 0", level: .warning)
                return 0
            }
        }
    }
    
    private func getKeyName(from keyCode: Int64) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return ";"
        case 40: return "K"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Escape"
        case 57: return "CapsLock"
        case 59: return "Control"
        case 76: return "ForwardDelete" // Forward Delete (Fn+Delete on some keyboards)
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        default:
            return "Key\(keyCode)"
        }
    }
    
    private func ioKitErrorDescription(_ error: IOReturn) -> String {
        switch error {
        case kIOReturnSuccess: return "Success"
        case kIOReturnError: return "General error"
        case kIOReturnNoMemory: return "No memory"
        case kIOReturnNoResources: return "No resources"
        case kIOReturnNotPrivileged: return "Not privileged"
        default: return "Unknown error: \(error)"
        }
    }
}
