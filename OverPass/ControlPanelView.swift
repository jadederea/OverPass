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
    
    @State private var isCapturing = false
    @State private var capturedKeys = 0
    @State private var keyHistory: [KeyEvent] = []
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var timeRemaining: Int? = nil
    
    struct KeyEvent: Identifiable {
        let id: String
        let device: String
        let key: String
        let event: String // "down" or "up"
        let timestamp: String
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.09, blue: 0.11)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
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
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(white: 0.2))
                            .offset(y: 0)
                    )
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
                                        PresetButton(title: "10s", seconds: 10, isCapturing: isCapturing) {
                                            setPresetTime(10)
                                        }
                                        PresetButton(title: "30s", seconds: 30, isCapturing: isCapturing) {
                                            setPresetTime(30)
                                        }
                                        PresetButton(title: "1m", seconds: 60, isCapturing: isCapturing) {
                                            setPresetTime(60)
                                        }
                                        PresetButton(title: "5m", seconds: 300, isCapturing: isCapturing) {
                                            setPresetTime(300)
                                        }
                                        PresetButton(title: "15m", seconds: 900, isCapturing: isCapturing) {
                                            setPresetTime(900)
                                        }
                                        PresetButton(title: "30m", seconds: 1800, isCapturing: isCapturing) {
                                            setPresetTime(1800)
                                        }
                                        PresetButton(title: "1h", seconds: 3600, isCapturing: isCapturing) {
                                            setPresetTime(3600)
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
                            ParallelsSettingsCard()
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
                                keyHistory.removeAll()
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
        .onChange(of: isCapturing) { newValue in
            if newValue {
                startTimer()
            }
        }
    }
    
    private func setPresetTime(_ totalSeconds: Int) {
        guard !isCapturing else { return }
        minutes = totalSeconds / 60
        seconds = totalSeconds % 60
    }
    
    private func toggleCapture(_ newValue: Bool) {
        if newValue {
            let totalSeconds = minutes * 60 + seconds
            timeRemaining = totalSeconds
            isCapturing = true
            startTimer()
            logger.log("Capture started - Timer: \(minutes)m \(seconds)s", level: .info)
        } else {
            isCapturing = false
            timeRemaining = nil
            logger.log("Capture stopped - Total events: \(capturedKeys)", level: .info)
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard isCapturing, let time = timeRemaining else {
                timer.invalidate()
                return
            }
            
            if time <= 1 {
                isCapturing = false
                timeRemaining = nil
                timer.invalidate()
                logger.log("Safety timer expired - Capture stopped", level: .warning)
            } else {
                timeRemaining = time - 1
            }
        }
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
    @State private var selectedVM = "Windows 11"
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "display")
                    .font(.system(size: 16))
                Text("Parallels VM")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Text("Target VM:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    Picker("", selection: $selectedVM) {
                        Text("Windows 11").tag("Windows 11")
                        Text("Ubuntu 22.04").tag("Ubuntu 22.04")
                        Text("macOS Ventura").tag("macOS Ventura")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                HStack {
                    Text("Connection:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(white: 0.2).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
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
                    .background(event.event == "down" ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                    .foregroundColor(event.event == "down" ? .blue : .purple)
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
