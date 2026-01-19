//
//  AppColors.swift
//  OverPass
//
//  Color palette: Sapphire nightfall whisper
//  Blue gradient palette for dark theme with colorful accents
//

import SwiftUI

extension Color {
    // Sapphire Nightfall Whisper Color Palette
    
    // Dark backgrounds (primary)
    static let sapphireDark = Color(hex: "#262B40")      // Very dark midnight blue - main background
    static let sapphireSlate = Color(hex: "#2C444D")     // Dark slate blue - alternative background
    
    // Deep blues (buttons, primary actions)
    static let sapphireNavy = Color(hex: "#06457F")      // Deep rich navy - primary buttons
    
    // Vibrant accents (icons, highlights)
    static let sapphireRoyal = Color(hex: "#0474C4")     // Vibrant royal blue - icons, primary accents
    static let sapphireDusty = Color(hex: "#5379AE")     // Muted dusty blue - secondary accents
    
    // Light accents (highlights, subtle elements)
    static let sapphireLight = Color(hex: "#A8C4EC")     // Light periwinkle - highlights
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
