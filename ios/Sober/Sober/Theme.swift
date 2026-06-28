import SwiftUI

/// Warm dark palette — orange→red, matching the web version.
enum Theme {
    static let bg       = Color(hex: 0x0f0b0a)
    static let surface  = Color(hex: 0x1a1514)
    static let surface2 = Color(hex: 0x251d1b)
    static let border   = Color(hex: 0x382a27)
    static let text     = Color(hex: 0xf6efea)
    static let textDim  = Color(hex: 0xa2918a)
    static let accent   = Color(hex: 0xff5a1f)
    static let accent2  = Color(hex: 0xff2e3a)
    static let danger   = Color(hex: 0xf85149)

    // Activity heat-map levels (amber -> orange)
    static let level0 = Color(hex: 0x1a1514)
    static let level1 = Color(hex: 0x4a1f08)
    static let level2 = Color(hex: 0x8a3a0d)
    static let level3 = Color(hex: 0xd65512)
    static let level4 = Color(hex: 0xff7a1f)
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
