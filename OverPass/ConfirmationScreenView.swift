//
//  ConfirmationScreenView.swift
//  OverPass
//
//  Confirmation screen - confirms detected keyboard
//

import SwiftUI

struct ConfirmationScreenView: View {
    let keyboardInfo: AppState.KeyboardInfo
    @ObservedObject var appState: AppState
    var onBack: (() -> Void)?
    @StateObject private var logger = Logger.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
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
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 96, height: 96)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                    }
                    
                    // Title and description
                    VStack(spacing: 12) {
                        Text("Keyboard Detected")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Please confirm this is the correct keyboard")
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
                    
                    // Keyboard info card
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 16) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 24))
                                .foregroundColor(Color(white: 0.6))
                            Text(keyboardInfo.name)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(white: 0.3))
                                .offset(y: 12)
                        )
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Vendor ID:")
                                    .foregroundColor(Color(white: 0.6))
                                Spacer()
                                Text(keyboardInfo.vendorId)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Product ID:")
                                    .foregroundColor(Color(white: 0.6))
                                Spacer()
                                Text(keyboardInfo.productId)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            HStack(alignment: .top) {
                                Text("Interfaces:")
                                    .foregroundColor(Color(white: 0.6))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    ForEach(keyboardInfo.interfaces, id: \.self) { iface in
                                        HStack(spacing: 8) {
                                            Image(systemName: iface.lowercased() == "usb" ? "cable.connector" : "waveform")
                                                .font(.system(size: 16))
                                            Text(iface)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .font(.system(size: 16))
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.2).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            appState.navigateTo(.keyboardDetection)
                        }) {
                            Text("Detect Again")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color(white: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(white: 0.3), lineWidth: 1)
                        )
                        
                        Button(action: {
                            appState.navigateTo(.controlPanel)
                        }) {
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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
                    
                    Text("Make sure this matches your intended keyboard device")
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
