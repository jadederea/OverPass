//
//  PermissionsScreenView.swift
//  OverPass
//
//  Permissions screen - requests Accessibility and Input Monitoring permissions
//

import SwiftUI

struct PermissionsScreenView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var logger = Logger.shared
    @ObservedObject var appState: AppState
    var onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.09, green: 0.09, blue: 0.11)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button (if needed)
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
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 96, height: 96)
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                    }
                    
                    // Title and description
                    VStack(spacing: 12) {
                        Text("Accessibility Permissions Required")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("This app needs accessibility permissions to detect keyboard devices and capture keystrokes for Parallels relay.")
                            .font(.system(size: 18))
                            .foregroundColor(Color(white: 0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Instructions card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("To grant permissions:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("1.")
                                    .foregroundColor(Color(white: 0.7))
                                Text("Open System Settings")
                                    .foregroundColor(Color(white: 0.7))
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .foregroundColor(Color(white: 0.7))
                                Text("Go to Privacy & Security")
                                    .foregroundColor(Color(white: 0.7))
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("3.")
                                    .foregroundColor(Color(white: 0.7))
                                Text("Select Accessibility")
                                    .foregroundColor(Color(white: 0.7))
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("4.")
                                    .foregroundColor(Color(white: 0.7))
                                Text("Enable this app")
                                    .foregroundColor(Color(white: 0.7))
                            }
                        }
                        .font(.system(size: 16))
                    }
                    .padding(24)
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
                            permissionManager.openSystemSettings()
                        }) {
                            Text("Open System Settings")
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
                            appState.navigateTo(.keyboardDetection)
                        }) {
                            Text("I've Granted Access")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color.blue)
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
                    
                    Text("The app will verify permissions once granted")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }
                .padding(48)
                .frame(maxWidth: 600)
                
                Spacer()
            }
        }
        .onAppear {
            permissionManager.checkPermissions()
        }
    }
}
