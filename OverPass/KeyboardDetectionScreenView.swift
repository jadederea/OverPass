//
//  KeyboardDetectionScreenView.swift
//  OverPass
//
//  Keyboard detection screen - user types to detect keyboard
//

import SwiftUI

struct KeyboardDetectionScreenView: View {
    @ObservedObject var appState: AppState
    var onBack: (() -> Void)?
    @StateObject private var logger = Logger.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var deviceService = KeyboardDeviceService()
    @StateObject private var detector = AutomaticKeyboardDetector()
    @State private var hasStartedDetection = false
    
    // Helper to get icon name for transport type
    private func iconName(for transportType: KeyboardDevice.TransportType) -> String {
        switch transportType {
        case .usb: return "cable.connector"
        case .bluetooth: return "waveform"
        default: return "keyboard"
        }
    }
    
    // Helper to format vendor/product string
    private func vendorProductString(for device: KeyboardDevice) -> String {
        let vendorHex = String(device.vendorId, radix: 16, uppercase: true)
        let productHex = String(device.productId, radix: 16, uppercase: true)
        return "Vendor: 0x\(vendorHex), Product: 0x\(productHex)"
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.09, blue: 0.11)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                backButtonView
                Spacer()
                mainContentView
                Spacer()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var backButtonView: some View {
        if let onBack = onBack {
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .background(Color(white: 0.2))
                .cornerRadius(6)
                .padding(32)
                Spacer()
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 96, height: 96)
                        Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                    }
                    
                    // Title and description
                    VStack(spacing: 12) {
                        Text("Detect Your Keyboard")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Type on the keyboard you want to use for Parallels relay")
                            .font(.system(size: 18))
                            .foregroundColor(Color(white: 0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Permissions status
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Accessibility: ")
                                .foregroundColor(.green)
                            Text("Granted")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Input Monitoring: ")
                                .foregroundColor(.green)
                            Text("Granted")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .font(.system(size: 16))
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Keystroke detection area
                    detectionStatusView
                    .frame(minHeight: 192)
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color(white: 0.2).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
                    
                    // Copy Debug Logs button
                    HStack(spacing: 8) {
                        Button(action: {
                            logger.copyDebugLogsToClipboard()
                        }) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Copy Debug Logs")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(Color(white: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(white: 0.3), lineWidth: 1)
                        )
                        
                        if let message = logger.copyConfirmationMessage {
                            Text(message)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                    
                    // Start Detection button
                    if !hasStartedDetection {
                        Button(action: {
                            logger.log("User clicked Start Detection", level: .info)
                            hasStartedDetection = true
                            // Start device scanning if not already done
                            if deviceService.availableDevices.isEmpty {
                                deviceService.scanForDevices()
                            }
                            // Wait a moment for devices to be scanned, then start detection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                detector.startDetection(with: deviceService.availableDevices)
                                logger.log("Started detection with \(deviceService.availableDevices.count) available devices", level: .info)
                            }
                        }) {
                            Text("Start Detection")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(deviceService.isScanning)
                    } else if detector.isListening {
                        Button(action: {
                            logger.log("User clicked Stop Detection", level: .info)
                            detector.stopDetection()
                            hasStartedDetection = false
                        }) {
                            Text("Stop Detection")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(Color(white: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if hasStartedDetection {
                        Text("Type on the keyboard you want to use. The app will detect it and all its interfaces (USB, Bluetooth, etc.)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("The app will identify your keyboard hardware and interfaces automatically")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
                .padding(48)
                .frame(maxWidth: 600)
    }
    
    private var detectionStatusView: some View {
        Group {
            if !hasStartedDetection {
                Text("Click 'Start Detection' and type on your keyboard")
                    .font(.system(size: 18))
                    .foregroundColor(Color(white: 0.5))
            } else if detector.keyPressCount == 0 {
                Text("Waiting for input... Type on your keyboard")
                    .font(.system(size: 18))
                    .foregroundColor(Color(white: 0.5))
            } else if detector.detectedDevices.isEmpty {
                detectingInProgressView
            } else {
                detectionCompleteView
            }
        }
    }
    
    private var detectingInProgressView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.purple)
            Text("Detecting keyboard... (\(detector.keyPressCount) keystrokes)")
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.6))
            Text("Keep typing (detection will stop automatically)")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.5))
        }
    }
    
    private var detectionCompleteView: some View {
        VStack(spacing: 20) {
            Text("Keyboard Detected!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.green)
            
            Text("Found \(detector.detectedDevices.count) device(s)")
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.6))
            
            detectedDevicesListView
            confirmationButtonsView
        }
    }
    
    private var detectedDevicesListView: some View {
        VStack(spacing: 12) {
            ForEach(detector.detectedDevices) { device in
                deviceInfoCard(for: device)
            }
        }
    }
    
    private func deviceInfoCard(for device: KeyboardDevice) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: device.transportType))
                    .font(.system(size: 16))
                Text(device.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            Text("\(device.manufacturer) - \(device.transportType.rawValue)")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.6))
            Text(vendorProductString(for: device))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
    }
    
    private var confirmationButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: handleDetectAgain) {
                Text("Detect Again")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(Color(white: 0.2))
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.3), lineWidth: 1)
            )
            
            Button(action: handleConfirm) {
                Text("Confirm")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Actions
    
    private func handleDetectAgain() {
        logger.log("User cancelled detection, restarting", level: .info)
        hasStartedDetection = false
        detector.stopDetection()
        // Reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            hasStartedDetection = true
            detector.startDetection(with: deviceService.availableDevices)
        }
    }
    
    private func handleConfirm() {
        logger.log("User confirmed detected keyboard(s)", level: .info)
        appState.detectedKeyboardDevices = detector.detectedDevices
        
        if let firstDevice = detector.detectedDevices.first {
            appState.setKeyboardInfo(AppState.KeyboardInfo(
                name: firstDevice.name,
                vendorId: String(format: "0x%04x", firstDevice.vendorId),
                productId: String(format: "0x%04x", firstDevice.productId),
                interfaces: detector.detectedDevices.map { $0.transportType.rawValue }
            ))
        }
        
        appState.navigateTo(.confirmation)
    }
}
