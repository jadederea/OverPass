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
    @State private var keystrokes: [String] = []
    @State private var detecting = false
    
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
                }
                
                Spacer()
                
                // Main content
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
                    VStack(spacing: 16) {
                        if keystrokes.isEmpty {
                            Text("Waiting for input...")
                                .font(.system(size: 18))
                                .foregroundColor(Color(white: 0.5))
                        } else if detecting {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.5)
                                    .tint(.purple)
                                Text("Detecting keyboard...")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(white: 0.6))
                            }
                        } else {
                            VStack(spacing: 16) {
                                Text("Keys detected:")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(white: 0.6))
                                
                                HStack(spacing: 12) {
                                    ForEach(keystrokes, id: \.self) { key in
                                        Text(key)
                                            .font(.system(size: 16, design: .monospaced))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(white: 0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color(white: 0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .frame(minHeight: 192)
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color(white: 0.2).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
                    .onAppear {
                        // Keyboard detection will be implemented when we port functionality from KeyRelay
                        // For now, simulate detection after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // This will be replaced with real keyboard detection
                            logger.log("Keyboard detection screen appeared - detection will be implemented", level: .info)
                        }
                    }
                    
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
                    
                    // Temporary button to proceed (will be replaced with real detection)
                    Button(action: {
                        detecting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // Mock keyboard detection - will be replaced with real implementation
                            appState.setKeyboardInfo(AppState.KeyboardInfo(
                                name: "Detected Keyboard",
                                vendorId: "0x05ac",
                                productId: "0x026c",
                                interfaces: ["USB", "Bluetooth"]
                            ))
                            appState.navigateTo(.confirmation)
                        }
                    }) {
                        Text("Simulate Detection (Temporary)")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background(Color.purple.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .opacity(keystrokes.isEmpty ? 1.0 : 0.0)
                    
                    Text("The app will identify your keyboard hardware and interfaces automatically")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }
                .padding(48)
                .frame(maxWidth: 600)
                
                Spacer()
            }
        }
    }
}
