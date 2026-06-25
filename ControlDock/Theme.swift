//
//  Theme.swift
//  ControlDock (iOS)
//
//  Visual language for the Steam Deck-inspired control surface.
//

import SwiftUI

extension Color {
    /// Creates a color from a "#RRGGBB" hex string. Falls back to blue.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b: Double
        if cleaned.count == 6 {
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
        } else {
            r = 0.231; g = 0.510; b = 0.965 // #3B82F6
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum DeckTheme {
    /// Deep, slightly blue-tinted background gradient like the Steam Deck shell.
    static let background = LinearGradient(
        colors: [Color(red: 0.05, green: 0.06, blue: 0.09),
                 Color(red: 0.10, green: 0.11, blue: 0.16)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = Color.white.opacity(0.06)
    static let panelStroke = Color.white.opacity(0.10)
    static let accent = Color(red: 0.36, green: 0.55, blue: 1.0)
}
