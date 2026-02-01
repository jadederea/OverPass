//
//  AppIconGenerator.swift
//  OverPass
//
//  SwiftUI view to generate app icon
//  Design: Keyboard keys flowing over a bridge (overpass) in sapphire colors
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background - sapphire dark with gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1A1F2E"),  // Darker than sapphireDark for depth
                    Color.sapphireDark,
                    Color.sapphireSlate
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Bridge/Overpass structure
            VStack(spacing: 0) {
                Spacer()
                
                // Bridge deck (horizontal)
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.sapphireNavy.opacity(0.8),
                                Color.sapphireRoyal.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 280, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.sapphireRoyal.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: Color.sapphireRoyal.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Bridge supports (vertical pillars)
                HStack(spacing: 80) {
                    ForEach(0..<2) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.sapphireNavy.opacity(0.7))
                            .frame(width: 16, height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.sapphireRoyal.opacity(0.4), lineWidth: 1.5)
                            )
                    }
                }
                .offset(y: -12)
                
                Spacer()
            }
            
            // Keyboard keys flowing over the bridge
            VStack {
                // Top keys (approaching the bridge)
                HStack(spacing: 12) {
                    KeyIcon(letter: "W", color: Color.sapphireRoyal)
                    KeyIcon(letter: "A", color: Color.sapphireDusty)
                    KeyIcon(letter: "S", color: Color.sapphireRoyal)
                    KeyIcon(letter: "D", color: Color.sapphireDusty)
                }
                .offset(x: -40, y: 20)
                .opacity(0.9)
                
                Spacer()
                
                // Keys on the bridge (center)
                HStack(spacing: 10) {
                    KeyIcon(letter: "O", color: Color.sapphireLight, size: 32)
                    KeyIcon(letter: "P", color: Color.sapphireLight, size: 32)
                }
                .offset(y: -80)
                .shadow(color: Color.sapphireRoyal.opacity(0.5), radius: 12, x: 0, y: 4)
                
                Spacer()
                
                // Bottom keys (leaving the bridge)
                HStack(spacing: 12) {
                    KeyIcon(letter: "↑", color: Color.sapphireDusty)
                    KeyIcon(letter: "↓", color: Color.sapphireRoyal)
                    KeyIcon(letter: "←", color: Color.sapphireDusty)
                    KeyIcon(letter: "→", color: Color.sapphireRoyal)
                }
                .offset(x: 40, y: -20)
                .opacity(0.8)
            }
            
            // Subtle glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.sapphireRoyal.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 60, y: -60)
        }
        .frame(width: 512, height: 512)
        .clipShape(RoundedRectangle(cornerRadius: 100))
    }
}

struct KeyIcon: View {
    let letter: String
    let color: Color
    var size: CGFloat = 28
    
    var body: some View {
        ZStack {
            // Key background
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.9),
                            color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
            
            // Key letter
            Text(letter)
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Preview for testing
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
            .previewLayout(.fixed(width: 512, height: 512))
    }
}
