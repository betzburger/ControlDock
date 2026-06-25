//
//  MacTheme.swift
//  ControlDockMac
//

import SwiftUI

extension Color {
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
            r = 0.231; g = 0.510; b = 0.965
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// Converts the color to a "#RRGGBB" string via its sRGB components.
    func toHex() -> String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.systemBlue
        let r = Int(round(ns.redComponent * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

enum MacTheme {
    static let accent = Color(red: 0.36, green: 0.55, blue: 1.0)
}
