//
//  ContentView.swift
//  OverPass
//
//  Main content view with version display
//  Version: Managed by build script
//

import SwiftUI

struct ContentView: View {
    @StateObject private var logger = Logger.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Version display at top center
            HStack {
                Spacer()
                Text("OverPass v\(AppVersion.current)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                Spacer()
            }
            .frame(height: 30)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main content area - Figma UI screens
            ZStack {
                // Dark background matching Figma design
                Color(red: 0.09, green: 0.09, blue: 0.11)
                    .ignoresSafeArea()
                
                // Show appropriate screen based on state
                Group {
                    switch appState.currentScreen {
                    case .permissions:
                        PermissionsScreenView(appState: appState, onBack: nil)
                    case .keyboardDetection:
                        KeyboardDetectionScreenView(appState: appState) {
                            appState.navigateTo(.permissions)
                        }
                    case .confirmation:
                        if let keyboardInfo = appState.keyboardInfo {
                            ConfirmationScreenView(
                                keyboardInfo: keyboardInfo,
                                appState: appState
                            ) {
                                appState.navigateTo(.keyboardDetection)
                            }
                        }
                    case .controlPanel:
                        if let keyboardInfo = appState.keyboardInfo {
                            ControlPanelView(
                                keyboardInfo: keyboardInfo,
                                appState: appState
                            ) {
                                appState.navigateTo(.confirmation)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            logger.log("App launched - Version: \(AppVersion.current)", level: .info)
            // Check permissions and navigate accordingly
            permissionManager.checkPermissions()
            if permissionManager.hasAccessibilityPermission && permissionManager.hasInputMonitoringPermission {
                // If permissions granted, go to keyboard detection
                appState.navigateTo(.keyboardDetection)
            } else {
                // Otherwise start at permissions screen
                appState.navigateTo(.permissions)
            }
        }
    }
}

#Preview {
    ContentView()
}
