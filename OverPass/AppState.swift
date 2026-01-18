//
//  AppState.swift
//  OverPass
//
//  Manages application state and navigation between screens
//

import Foundation
import SwiftUI

enum AppScreen {
    case permissions
    case keyboardDetection
    case confirmation
    case controlPanel
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentScreen: AppScreen = .permissions
    @Published var keyboardInfo: KeyboardInfo?
    
    struct KeyboardInfo {
        let name: String
        let vendorId: String
        let productId: String
        let interfaces: [String]
    }
    
    private init() {}
    
    func navigateTo(_ screen: AppScreen) {
        currentScreen = screen
    }
    
    func setKeyboardInfo(_ info: KeyboardInfo) {
        keyboardInfo = info
    }
}
