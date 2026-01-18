//
//  KeyboardDeviceService.swift
//  OverPass
//
//  Service for discovering and managing connected keyboard devices
//  Uses IOKit HID Manager to enumerate real hardware devices
//  Ported from KeyRelay with cleanup
//

import Foundation
import IOKit
import IOKit.hid
import ApplicationServices

/// Service for discovering and managing connected keyboard devices
/// Uses IOKit HID Manager to enumerate real hardware devices
class KeyboardDeviceService: ObservableObject {
    @Published var availableDevices: [KeyboardDevice] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    
    private var hidManager: IOHIDManager?
    private let logger = Logger.shared
    
    init() {
        logger.log("KeyboardDeviceService initializing...", level: .info)
        setupHIDManager()
        scanForDevices()
        logger.log("KeyboardDeviceService initialization complete", level: .info)
    }
    
    deinit {
        logger.log("KeyboardDeviceService deinitializing...", level: .info)
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            logger.log("HID Manager closed", level: .info)
        }
        logger.log("KeyboardDeviceService deinitialized", level: .info)
    }
    
    // MARK: - Public Interface
    
    /// Scans for all connected keyboard devices
    func scanForDevices() {
        logger.log("Starting device scan...", level: .info)
        isScanning = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performDeviceScan()
            
            DispatchQueue.main.async {
                self.isScanning = false
                self.logger.log("Device scan completed - found \(self.availableDevices.count) devices", level: .info)
            }
        }
    }
    
    /// Refreshes the device list
    func refreshDevices() {
        logger.log("User requested device refresh", level: .info)
        
        // If HID Manager is not available, try to set it up again
        // (in case permissions were granted since last try)
        if hidManager == nil {
            logger.log("HID Manager not available - attempting to reinitialize...", level: .info)
            setupHIDManager()
        }
        
        scanForDevices()
    }
    
    /// Forces a complete refresh of permissions and devices
    func forceRefreshPermissions() {
        logger.log("User requested permission refresh", level: .info)
        
        // Force re-check by clearing current state
        hidManager = nil
        errorMessage = nil
        
        // Wait a moment for macOS to update permission status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupHIDManager()
            self.scanForDevices()
        }
    }
    
    // MARK: - Private Implementation
    
    /// Sets up the IOKit HID Manager for keyboard device detection
    private func setupHIDManager() {
        logger.log("Setting up IOKit HID Manager...", level: .info)
        
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard let manager = hidManager else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create HID Manager"
                self.logger.log("FAILED: Could not create HID Manager", level: .error)
            }
            return
        }
        
        logger.log("HID Manager created successfully", level: .info)
        
        // Set up multiple matching dictionaries to catch more devices
        let keyboardMatching1 = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard
        ] as CFDictionary
        
        let keyboardMatching2 = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keypad
        ] as CFDictionary
        
        // Set up broader device matching to catch more input devices
        let matchingArray = [keyboardMatching1, keyboardMatching2] as CFArray
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingArray)
        
        logger.log("Device matching criteria set - looking for keyboards and keypads", level: .info)
        
        // Check permissions properly first
        if !checkInputMonitoringPermission() {
            logger.log("Input Monitoring permission not granted - skipping IOKit Manager", level: .warning)
            DispatchQueue.main.async {
                self.errorMessage = "Input Monitoring permission required. Grant permission in System Settings → Privacy & Security → Input Monitoring"
            }
            hidManager = nil
            return
        }
        
        // Open the manager (this is the real test)
        logger.log("Attempting to open HID Manager...", level: .info)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            DispatchQueue.main.async {
                let errorDescription = self.ioKitErrorDescription(result)
                self.errorMessage = "Input Monitoring permission required. Grant permission in System Settings → Privacy & Security → Input Monitoring"
                self.logger.log("FAILED: IOKit HID Manager Error: \(result) - \(errorDescription)", level: .error)
            }
            // Don't fail completely - just use sample data
            hidManager = nil
        } else {
            logger.log("HID Manager opened successfully - IOKit access granted", level: .info)
            // Clear any previous error message
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
        }
    }
    
    /// Check if Input Monitoring permission is granted
    private func checkInputMonitoringPermission() -> Bool {
        logger.log("Checking Input Monitoring permission...", level: .info)
        
        // Use PermissionManager's method (consistent with our app)
        return PermissionManager.shared.hasInputMonitoringPermission
    }
    
    /// Converts IOKit error codes to human-readable descriptions
    private func ioKitErrorDescription(_ errorCode: IOReturn) -> String {
        switch errorCode {
        case kIOReturnNotPrivileged:
            return "Insufficient privileges. Enable Input Monitoring in Privacy & Security settings."
        case kIOReturnNotPermitted:
            return "Operation not permitted. Check app permissions."
        case kIOReturnBusy:
            return "Device busy or already in use."
        case kIOReturnNoDevice:
            return "No matching devices found."
        case kIOReturnUnsupported:
            return "Unsupported operation."
        default:
            return "IOKit error code: \(errorCode)"
        }
    }
    
    /// Performs the actual device scanning using IOKit
    private func performDeviceScan() {
        var detectedDevices: [KeyboardDevice] = []
        
        // Try to scan real devices if HID Manager is available
        if let manager = hidManager {
            logger.log("HID Manager available - scanning for real devices", level: .info)
            let deviceSet = IOHIDManagerCopyDevices(manager)
            let devices = deviceSet as? Set<IOHIDDevice> ?? Set<IOHIDDevice>()
            
            logger.log("IOKit found \(devices.count) total HID devices matching criteria", level: .info)
            
            for device in devices {
                if let keyboardDevice = createKeyboardDevice(from: device) {
                    detectedDevices.append(keyboardDevice)
                    logger.log("Added keyboard device: \(keyboardDevice.name) (\(keyboardDevice.manufacturer)) - Transport: \(keyboardDevice.transportType.rawValue)", level: .info)
                }
            }
            
            logger.log("IOKit detected \(detectedDevices.count) keyboard devices from \(devices.count) total devices", level: .info)
        } else {
            logger.log("IOKit HID Manager not available - using sample devices only", level: .warning)
        }
        
        DispatchQueue.main.async {
            self.availableDevices = detectedDevices.sorted { $0.name < $1.name }
            self.logger.log("Final device list has \(detectedDevices.count) total devices", level: .info)
        }
    }
    
    /// Creates a KeyboardDevice from an IOHIDDevice
    private func createKeyboardDevice(from hidDevice: IOHIDDevice) -> KeyboardDevice? {
        // Get device properties
        let vendorIDRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDVendorIDKey as CFString)
        let productIDRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductIDKey as CFString)
        let productNameRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductKey as CFString)
        let manufacturerRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDManufacturerKey as CFString)
        let transportRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDTransportKey as CFString)
        let locationIDRef = IOHIDDeviceGetProperty(hidDevice, kIOHIDLocationIDKey as CFString)
        
        // Extract values with safe casting
        let vendorID = (vendorIDRef as? NSNumber)?.intValue ?? 0
        let productID = (productIDRef as? NSNumber)?.intValue ?? 0
        let locationID = (locationIDRef as? NSNumber)?.intValue ?? 0
        let productName = productNameRef as? String ?? "Unknown Keyboard"
        let manufacturer = manufacturerRef as? String ?? "Unknown"
        let transport = transportRef as? String ?? "unknown"
        
        // Log detailed device properties
        logger.log("Examining HID device: \(productName)", level: .debug)
        logger.log("  Manufacturer: \(manufacturer), Vendor ID: \(vendorID) (0x\(String(vendorID, radix: 16))), Product ID: \(productID) (0x\(String(productID, radix: 16))), Transport: \(transport), Location ID: \(locationID)", level: .debug)
        
        // Generate unique device ID using same format as AutomaticKeyboardDetector
        let deviceID = String(format: "%04x:%04x:%08x", vendorID, productID, locationID)
        // Generate physical device ID using same format - locationID >> 8 removes interface bits
        // This groups interfaces of same physical device (USB + Bluetooth of same keyboard)
        // CRITICAL: locationID == 0 for built-in, != 0 for external, so they won't be grouped
        let physicalDeviceID = "\(vendorID)-\(productID)-\(locationID >> 8)"
        
        // Determine transport type with logic to distinguish built-in from external
        let transportType: KeyboardDevice.TransportType
        switch transport.lowercased() {
        case let t where t.contains("usb"):
            transportType = .usb
            logger.log("  Transport type determined: USB", level: .debug)
        case let t where t.contains("bluetooth") || t.contains("bt"):
            transportType = .bluetooth
            logger.log("  Transport type determined: Bluetooth", level: .debug)
        case let t where t.contains("spi") || t.contains("built"):
            transportType = .builtin
            logger.log("  Transport type determined: Built-in", level: .debug)
        default:
            // Check if it's built-in by vendor ID and location
            // CRITICAL: locationID == 0 means built-in keyboard
            if vendorID == 1452 { // Apple devices
                if locationID == 0 || transport.contains("built") {
                    transportType = .builtin
                    logger.log("  Transport type determined: Built-in (Apple device, locationID=0)", level: .debug)
                } else {
                    transportType = .usb
                    logger.log("  Transport type determined: USB (Apple external, locationID!=0)", level: .debug)
                }
            } else if vendorID != 0 {
                transportType = .usb
                logger.log("  Transport type determined: USB (non-zero vendor ID)", level: .debug)
            } else {
                transportType = .unknown
                logger.log("  Transport type determined: Unknown", level: .debug)
            }
        }
        
        // Improve naming for better identification
        var deviceName = productName
        if deviceName == "Unknown Keyboard" && manufacturer != "Unknown" {
            deviceName = "\(manufacturer) Keyboard"
        }
        
        // Add transport info to name if helpful
        if deviceName.lowercased().contains("keyboard") == false {
            deviceName += " Keyboard"
        }
        
        let device = KeyboardDevice(
            id: deviceID,
            name: deviceName,
            manufacturer: manufacturer,
            transportType: transportType,
            vendorId: vendorID,
            productId: productID,
            physicalDeviceId: physicalDeviceID
        )
        
        logger.log("Created KeyboardDevice: \(deviceName) (ID: \(deviceID), Physical: \(physicalDeviceID))", level: .info)
        
        return device
    }
}
