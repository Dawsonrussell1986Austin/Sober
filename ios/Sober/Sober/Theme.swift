import SwiftUI

/// GitHub-inspired dark palette, matching the web version.
enum Theme {
    static let bg       = Color(hex: 0x0d1117)
    static let surface  = Color(hex: 0x161b22)
    static let surface2 = Color(hex: 0x21262d)
    static let border   = Color(hex: 0x30363d)
    static let text     = Color(hex: 0xe6edf3)
    static let textDim  = Color(hex: 0x7d8590)
    static let accent   = Color(hex: 0x2ea043)
    static let danger   = Color(hex: 0xf85149)

    // Contribution-grid levels
    static let level0 = Color(hex: 0x161b22)
    static let level1 = Color(hex: 0x0e4429)
    static let level2 = Color(hex: 0x006d32)
    static let level3 = Color(hex: 0x26a641)
    static let level4 = Color(hex: 0x39d353)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue:  Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
