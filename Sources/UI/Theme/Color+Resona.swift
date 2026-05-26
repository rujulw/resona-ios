import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let resonaBackground = Color(hex: "#121212")
    static let resonaSurface    = Color(hex: "#0e0e0e")

    // MARK: - Text
    static let resonaPrimaryText   = Color(hex: "#f2f2f2")
    static let resonaSecondaryText = Color(hex: "#8f8f8f")
    static let resonaMuted         = Color(hex: "#a5a5a5")
    static let resonaMutedDim      = Color(hex: "#6f6f6f")

    // MARK: - Overlays (applied with .overlay or .background)
    static let resonaSelected  = Color.white.opacity(0.10)
    static let resonaPressed   = Color.white.opacity(0.06)
    static let resonaHover     = Color.white.opacity(0.05)

    // MARK: - Borders
    static let resonaBorderStrong = Color.white.opacity(0.10)
    static let resonaBorderSubtle = Color.white.opacity(0.05)

    // MARK: - Hex initializer
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)
        let a, r, g, b: UInt64
        switch raw.count {
        case 3:
            (a, r, g, b) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
