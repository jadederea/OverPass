//
//  KeyboardDevice.swift
//  OverPass
//
//  Data model representing a connected keyboard device
//  Ported from KeyRelay with cleanup
//

import Foundation

/// Represents a physical keyboard device connected to the system
/// Used for device selection and identification in key relay configuration
struct KeyboardDevice: Identifiable, Hashable {
    let id: String              // Unique device identifier (vendorId:productId:locationId)
    let name: String            // Human-readable device name
    let manufacturer: String    // Device manufacturer
    let transportType: TransportType // Connection type (USB, Bluetooth, etc.)
    let vendorId: Int           // USB/Bluetooth vendor ID
    let productId: Int          // USB/Bluetooth product ID
    let physicalDeviceId: String? // Physical device identifier for grouping interfaces
    
    enum TransportType: String, CaseIterable {
        case usb = "USB"
        case bluetooth = "Bluetooth"
        case builtin = "Built-in"
        case unknown = "Unknown"
    }
    
    /// Display name for UI purposes
    var displayName: String {
        if transportType == .builtin {
            return "\(name) (Built-in)"
        } else {
            return "\(name) (\(transportType.rawValue))"
        }
    }
    
    /// Debug description with device details
    var debugDescription: String {
        return """
        Device: \(name)
        Manufacturer: \(manufacturer)
        Type: \(transportType.rawValue)
        Product ID: 0x\(String(productId, radix: 16).uppercased())
        Vendor ID: 0x\(String(vendorId, radix: 16).uppercased())
        ID: \(id)
        Physical ID: \(physicalDeviceId ?? "none")
        """
    }
}
