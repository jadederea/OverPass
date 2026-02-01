//
//  ControlPanelView.swift
//  OverPass
//
//  Main control panel with timer, keyboard info, and keystroke history
//

import SwiftUI

struct ControlPanelView: View {
    let keyboardInfo: AppState.KeyboardInfo
    @ObservedObject var appState: AppState
    var onBack: (() -> Void)?
    @StateObject private var logger = Logger.shared
    @StateObject private var captureService = KeyboardCaptureService.shared
    
    @State private var minutes = 120  // Default: 2 hours
    @State private var seconds = 0
    @State private var timeRemaining: Int? = nil
    @State private var timer: Timer? = nil  // Store timer to prevent multiple instances
    
    // Computed properties for capture service
    private var isCapturing: Bool {
        captureService.isCapturing
    }
    
    private var capturedKeys: Int {
        captureService.capturedEventCount
    }
    
    private var keyHistory: [KeyEvent] {
        captureService.capturedEvents.map { event in
            KeyEvent(
                id: event.id,
                device: targetDevice?.name ?? "Unknown",
                key: event.key,
                event: event.event,
                timestamp: formatTimestamp(event.timestamp)
            )
        }
    }
    
    private var targetDevice: KeyboardDevice? {
        appState.detectedKeyboardDevices.first
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    struct KeyEvent: Identifiable {
        let id: String
        let device: String
        let key: String
        let event: String // "down" or "up"
        let timestamp: String
    }
    
    var body: some View {
        ZStack {
            Color.sapphireDark
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                if let onBack = onBack {
                    HStack {
                        Button(action: {
                            // Stop capture/relay before navigating back
                            if captureService.isCapturing {
                                captureService.stopCapture()
                                logger.log("Capture stopped due to navigation back", level: .info)
                            }
                            onBack()
                        }) {
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
                
                // Main content - two column layout
                HStack(spacing: 0) {
                    // Left Column
                    ScrollView {
                        VStack(alignment: .center, spacing: 16) {
                            // Header
                            VStack(alignment: .center, spacing: 4) {
                                Text("Parallels Keyboard Relay")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Capture keystrokes and relay them to your Parallels VM")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            .padding(.top, 24)
                            .frame(maxWidth: .infinity)
                            
                            // Status Card
                            VStack(alignment: .center, spacing: 12) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(isCapturing ? Color.green : Color(white: 0.4))
                                            .frame(width: 10, height: 10)
                                        Text(isCapturing ? "Active" : "Inactive")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { isCapturing },
                                        set: { newValue in
                                            toggleCapture(newValue)
                                        }
                                    ))
                                    .toggleStyle(.switch)
                                }
                                
                                if isCapturing, let timeRemaining = timeRemaining {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "waveform")
                                                .font(.system(size: 12))
                                            Text("\(capturedKeys) events relayed")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.green)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12))
                                            Text(formatTime(timeRemaining))
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        }
                                        .foregroundColor(.green)
                                    }
                                    .padding(12)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.2).opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(white: 0.3), lineWidth: 1)
                            )
                            
                            // Safety Timer and Device Info side by side
                            HStack(alignment: .top, spacing: 12) {
                                // Safety Timer
                                VStack(alignment: .center, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 16))
                                        Text("Safety Timer")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    
                                    // Preset buttons - more compact
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                        PresetButton(title: "15m", seconds: 900, isCapturing: isCapturing) {
                                            setPresetTime(900)
                                        }
                                        PresetButton(title: "30m", seconds: 1800, isCapturing: isCapturing) {
                                            setPresetTime(1800)
                                        }
                                        PresetButton(title: "1h", seconds: 3600, isCapturing: isCapturing) {
                                            setPresetTime(3600)
                                        }
                                        PresetButton(title: "2h", seconds: 7200, isCapturing: isCapturing) {
                                            setPresetTime(7200)
                                        }
                                        PresetButton(title: "4h", seconds: 14400, isCapturing: isCapturing) {
                                            setPresetTime(14400)
                                        }
                                        PresetButton(title: "8h", seconds: 28800, isCapturing: isCapturing) {
                                            setPresetTime(28800)
                                        }
                                    }
                                    
                                    // Manual time input
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Min")
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(white: 0.6))
                                            TextField("", value: $minutes, format: .number)
                                                .textFieldStyle(.plain)
                                                .padding(6)
                                                .background(Color(white: 0.2))
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                                .disabled(isCapturing)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Sec")
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(white: 0.6))
                                            TextField("", value: $seconds, format: .number)
                                                .textFieldStyle(.plain)
                                                .padding(6)
                                                .background(Color(white: 0.2))
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                                .disabled(isCapturing)
                                        }
                                    }
                                    
                                    Text("Auto-stops after duration")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(white: 0.5))
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity)
                                .background(Color(white: 0.2).opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(white: 0.3), lineWidth: 1)
                                )
                                
                                // Device Info
                                DeviceInfoCard(keyboardInfo: keyboardInfo)
                            }
                            
                            // Parallels Settings
                            ParallelsSettingsCard(captureService: captureService)
                                .frame(maxWidth: .infinity)
                            
                            // Action buttons - horizontal layout
                            HStack(spacing: 8) {
                                Button(action: {
                                    // Settings action
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 12))
                                        Text("Settings")
                                            .font(.system(size: 12))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .background(Color(white: 0.2))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(white: 0.3), lineWidth: 1)
                                )
                                
                                Button(action: {
                                    appState.navigateTo(.keyboardDetection)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "keyboard")
                                            .font(.system(size: 12))
                                        Text("Change Keyboard")
                                            .font(.system(size: 12))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .background(Color(white: 0.2))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(white: 0.3), lineWidth: 1)
                                )
                                
                                Button(action: {
                                    logger.copyDebugLogsToClipboard()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 12))
                                        Text("Copy Logs")
                                            .font(.system(size: 12))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .background(Color(white: 0.2))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(white: 0.3), lineWidth: 1)
                                )
                                
                                Button(action: {
                                    captureService.copyKeystrokeHistoryToClipboard()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "keyboard")
                                            .font(.system(size: 12))
                                        Text("Copy Keystrokes")
                                            .font(.system(size: 12))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .background(Color(white: 0.2))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(white: 0.3), lineWidth: 1)
                                )
                                
                                if let message = logger.copyConfirmationMessage {
                                    Text(message)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .transition(.opacity)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(24)
                        .frame(maxWidth: 450)
                    }
                    .frame(width: 450)
                    
                    // Right Column - Keystroke History
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Keystroke History")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Live capture events")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            Spacer()
                            Button(action: {
                                captureService.clearHistory()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear History")
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .disabled(keyHistory.isEmpty)
                        }
                        .padding(24)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(white: 0.2))
                                .offset(y: 24)
                        )
                        
                        ScrollView {
                            if keyHistory.isEmpty {
                                VStack {
                                    Spacer()
                                    Text("No keystrokes captured yet")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(white: 0.5))
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(keyHistory) { event in
                                        KeyEventRow(event: event)
                                    }
                                }
                                .padding(24)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.05))
                }
            }
        }
        .onChange(of: captureService.isCapturing) { newValue in
            if newValue {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopTimer()
        }
    }
    
    private func setPresetTime(_ totalSeconds: Int) {
        guard !isCapturing else { return }
        minutes = totalSeconds / 60
        seconds = totalSeconds % 60
    }
    
    private func toggleCapture(_ newValue: Bool) {
        if newValue {
            guard let device = targetDevice else {
                logger.log("Cannot start capture - no target device selected", level: .error)
                return
            }
            
            // If relay mode, check that a VM is selected
            if captureService.isRelayMode {
                guard let vm = captureService.targetVM else {
                    logger.log("Cannot start relay - no VM selected", level: .error)
                    return
                }
                guard vm.isRunning else {
                    logger.log("Cannot start relay - VM is not running", level: .error)
                    return
                }
            }
            
            let totalSeconds = minutes * 60 + seconds
            timeRemaining = totalSeconds
            captureService.startCapture(targetDevice: device)
            startTimer()
            let modeText = captureService.isRelayMode ? "Relay" : "Capture"
            logger.log("\(modeText) started - Timer: \(minutes)m \(seconds)s", level: .info)
        } else {
            captureService.stopCapture()
            stopTimer()
            timeRemaining = nil
            logger.log("Capture stopped - Total events: \(capturedKeys)", level: .info)
        }
    }
    
    private func startTimer() {
        // Stop any existing timer first
        stopTimer()
        
        // Create and store the timer
        // Timer runs on main run loop, so state updates are safe
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard captureService.isCapturing,
                  let time = timeRemaining else {
                stopTimer()
                return
            }
            
            if time <= 1 {
                captureService.stopCapture()
                timeRemaining = nil
                stopTimer()
                logger.log("Safety timer expired - Capture stopped", level: .warning)
            } else {
                timeRemaining = time - 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct PresetButton: View {
    let title: String
    let seconds: Int
    let isCapturing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(Color(white: 0.2))
        .foregroundColor(.white)
        .cornerRadius(4)
        .disabled(isCapturing)
        .opacity(isCapturing ? 0.5 : 1.0)
    }
}

struct DeviceInfoCard: View {
    let keyboardInfo: AppState.KeyboardInfo
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.system(size: 16))
                Text("Monitored Device")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            
            VStack(alignment: .center, spacing: 8) {
                InfoRow(label: "Device:", value: keyboardInfo.name)
                InfoRow(label: "Vendor:", value: keyboardInfo.vendorId, monospaced: true)
                InfoRow(label: "Product:", value: keyboardInfo.productId, monospaced: true)
                
                HStack(alignment: .top) {
                    Text("Interfaces:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        ForEach(keyboardInfo.interfaces, id: \.self) { iface in
                            HStack(spacing: 4) {
                                Image(systemName: iface.lowercased() == "usb" ? "cable.connector" : "waveform")
                                    .font(.system(size: 12))
                                Text(iface)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.2).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.6))
            Spacer()
            Text(value)
                .font(.system(size: 12, design: monospaced ? .monospaced : .default))
                .foregroundColor(.white)
        }
    }
}

struct ParallelsSettingsCard: View {
    @ObservedObject var captureService: KeyboardCaptureService
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // Mode Toggle
            HStack(spacing: 12) {
                Text("Mode:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: Binding(
                    get: { captureService.isRelayMode ? "relay" : "capture" },
                    set: { newValue in
                        captureService.isRelayMode = (newValue == "relay")
                        if captureService.isRelayMode {
                            captureService.refreshParallelsVMs()
                        }
                    }
                )) {
                    Text("Capture Only").tag("capture")
                    Text("Relay to VM").tag("relay")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // VM Selection (only show in relay mode)
            if captureService.isRelayMode {
                VStack(alignment: .center, spacing: 8) {
                    HStack {
                        Text("Target VM:")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        Button(action: {
                            isRefreshing = true
                            captureService.refreshParallelsVMs()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isRefreshing = false
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(isRefreshing)
                    }
                    
                    if captureService.availableVMs.isEmpty {
                        Text("No VMs found. Click refresh or ensure Parallels is running.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                    } else {
                        Picker("", selection: Binding(
                            get: { captureService.targetVM?.id.uuidString ?? "" },
                            set: { uuidString in
                                captureService.targetVM = captureService.availableVMs.first { $0.id.uuidString == uuidString }
                            }
                        )) {
                            Text("Select VM...").tag("")
                            ForEach(captureService.availableVMs) { vm in
                                Text("\(vm.name) (\(vm.status.displayName))").tag(vm.id.uuidString)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    
                    if let vm = captureService.targetVM {
                        HStack {
                            Text("Status:")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.6))
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(vm.isRunning ? Color.green : Color(white: 0.4))
                                    .frame(width: 6, height: 6)
                                Text(vm.status.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(vm.isRunning ? .green : Color(white: 0.6))
                            }
                        }
                    }
                }
            } else {
                Text("Capture mode - keys will be blocked from macOS")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .background(Color(white: 0.2).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
        .onAppear {
            if captureService.isRelayMode && captureService.availableVMs.isEmpty {
                captureService.refreshParallelsVMs()
            }
        }
    }
}

struct KeyEventRow: View {
    let event: ControlPanelView.KeyEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.timestamp)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                Spacer()
                Text(event.event == "down" ? "↓ DOWN" : "↑ UP")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.event == "down" ? Color.sapphireRoyal.opacity(0.2) : Color.sapphireDusty.opacity(0.2))
                    .foregroundColor(event.event == "down" ? .sapphireRoyal : .sapphireDusty)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 8) {
                Text("Key:")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
                Text(event.key)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.2))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text("Device: \(event.device)")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.2).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
    }
}
