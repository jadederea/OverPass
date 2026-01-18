//
//  AutomaticKeyboardDetector.swift
//  OverPass
//
//  Simplified keyboard detection service for automatic device identification
//  Detects which keyboard device the user is typing on by listening to HID input events
//  Ported from KeyRelay with cleanup
//

import Foundation
import IOKit.hid

/// Simplified keyboard detector that automatically identifies which keyboard device the user is typing on
@MainActor
class AutomaticKeyboardDetector: ObservableObject {
    @Published var isListening = false
    @Published var keyPressCount = 0
    @Published var detectedDevices: [KeyboardDevice] = []
    
    private var hidManager: IOHIDManager?
    private var availableDevices: [KeyboardDevice] = []
    private var detectedDeviceIds: Set<String> = []
    private let logger = Logger.shared
    
    func startDetection(with devices: [KeyboardDevice]) {
        logger.log("Starting detection with \(devices.count) available devices", level: .info)
        self.availableDevices = devices
        self.detectedDeviceIds.removeAll()
        self.detectedDevices.removeAll()
        self.keyPressCount = 0
        
        setupHIDManager()
        isListening = true
        
        logger.log("Detection started - waiting for user input", level: .info)
    }
    
    func stopDetection() {
        logger.log("Stopping detection", level: .info)
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            hidManager = nil
        }
        
        isListening = false
        
        // Correlate detected device IDs with available devices
        correlateDetectedDevices()
        
        logger.log("Detection stopped - found \(detectedDevices.count) devices", level: .info)
    }
    
    private func setupHIDManager() {
        logger.log("Setting up HID manager for detection", level: .info)
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else {
            logger.log("Failed to create HID manager", level: .error)
            return
        }
        
        // Create matching dictionaries for keyboards
        let keyboardMatch1 = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard
        ] as CFDictionary
        
        let keyboardMatch2 = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keypad
        ] as CFDictionary
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, [keyboardMatch1, keyboardMatch2] as CFArray)
        
        // Set up input callback
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(manager, hidInputCallback, context)
        
        // Open and schedule
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if result == kIOReturnSuccess {
            logger.log("HID manager configured and listening", level: .info)
        } else {
            logger.log("Failed to open HID manager: \(result)", level: .error)
        }
    }
    
    private func correlateDetectedDevices() {
        logger.log("Correlating \(detectedDeviceIds.count) detected IDs with \(availableDevices.count) available devices", level: .info)
        
        var matchedDevices: [KeyboardDevice] = []
        
        for deviceId in detectedDeviceIds {
            logger.log("Looking for device ID: \(deviceId)", level: .debug)
            
            // Try exact match first
            if let exactMatch = availableDevices.first(where: { $0.id == deviceId }) {
                matchedDevices.append(exactMatch)
                logger.log("Exact match found: \(exactMatch.name)", level: .info)
                continue
            }
            
            // Try physical device match - find all devices with same physicalDeviceId
            // This handles multiple interfaces (USB + Bluetooth) of same keyboard
            let physicalMatches = availableDevices.filter { device in
                guard let physicalId = device.physicalDeviceId else { return false }
                // Extract physical ID from deviceId (format: vendorId:productId:locationId)
                // We need to calculate physical ID from the detected deviceId
                let parts = deviceId.split(separator: ":")
                if parts.count == 3,
                   let vendorId = Int(parts[0], radix: 16),
                   let productId = Int(parts[1], radix: 16),
                   let locationId = Int(parts[2], radix: 16) {
                    let detectedPhysicalId = "\(vendorId)-\(productId)-\(locationId >> 8)"
                    return detectedPhysicalId == physicalId
                }
                return false
            }
            
            if !physicalMatches.isEmpty {
                matchedDevices.append(contentsOf: physicalMatches)
                logger.log("Physical match found: \(physicalMatches.map { $0.name }.joined(separator: ", "))", level: .info)
                continue
            }
            
            logger.log("No match found for device ID: \(deviceId)", level: .warning)
        }
        
        // Remove duplicates and group by physical device
        // This ensures we get all interfaces (USB, Bluetooth) of the same physical keyboard
        var uniqueDevices: [KeyboardDevice] = []
        var seenPhysicalIds: Set<String> = []
        
        for device in matchedDevices {
            if let physicalId = device.physicalDeviceId {
                if !seenPhysicalIds.contains(physicalId) {
                    seenPhysicalIds.insert(physicalId)
                    uniqueDevices.append(device)
                    logger.log("Added unique device: \(device.name) (physical: \(physicalId))", level: .info)
                } else {
                    // Already have a device with this physical ID, but check if this is a different interface
                    // If same physical ID but different transport type, add it (multiple interfaces)
                    let hasSameInterface = uniqueDevices.contains(where: { $0.physicalDeviceId == physicalId && $0.transportType == device.transportType })
                    if !hasSameInterface {
                        // Same physical device but different transport - add it (multiple interfaces)
                        uniqueDevices.append(device)
                        logger.log("Added additional interface: \(device.name) (\(device.transportType.rawValue))", level: .info)
                    }
                    // If hasSameInterface is true, skip (duplicate)
                }
            } else {
                uniqueDevices.append(device)
                logger.log("Added device without physical ID: \(device.name)", level: .info)
            }
        }
        
        self.detectedDevices = uniqueDevices
        logger.log("Final result: \(uniqueDevices.count) unique devices detected", level: .info)
        
        for device in uniqueDevices {
            logger.log("Selected: \(device.name) (\(device.manufacturer)) - ID: \(device.id), Physical: \(device.physicalDeviceId ?? "none")", level: .info)
        }
    }
    
    func handleHIDInput(value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let device = IOHIDElementGetDevice(element)
        let intValue = IOHIDValueGetIntegerValue(value)
        
        // Only process key press events (not releases)
        guard intValue > 0 else { return }
        
        // Get device properties
        let vendorId = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let productId = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let locationId = (IOHIDDeviceGetProperty(device, kIOHIDLocationIDKey as CFString) as? NSNumber)?.intValue ?? 0
        let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown"
        
        // Create device identifier (same format as KeyboardDeviceService)
        let deviceId = String(format: "%04x:%04x:%08x", vendorId, productId, locationId)
        let physicalDeviceId = String(format: "%d-%d-%d", vendorId, productId, locationId >> 8)
        
        logger.log("Key press from device: \(productName)", level: .debug)
        logger.log("  Device ID: \(deviceId), Physical ID: \(physicalDeviceId)", level: .debug)
        logger.log("  Vendor: 0x\(String(vendorId, radix: 16, uppercase: true)), Product: 0x\(String(productId, radix: 16, uppercase: true)), Location: 0x\(String(locationId, radix: 16, uppercase: true))", level: .debug)
        
        // Track this device
        detectedDeviceIds.insert(deviceId)
        keyPressCount += 1
        
        logger.log("Total keystrokes: \(keyPressCount), Unique devices: \(detectedDeviceIds.count)", level: .info)
    }
}

// MARK: - HID Input Callback
private func hidInputCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    value: IOHIDValue
) {
    guard let context = context else { return }
    let detector = Unmanaged<AutomaticKeyboardDetector>.fromOpaque(context).takeUnretainedValue()
    
    Task { @MainActor in
        detector.handleHIDInput(value: value)
    }
}
