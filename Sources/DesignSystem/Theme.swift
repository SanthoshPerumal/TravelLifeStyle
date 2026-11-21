import SwiftUI

// MARK: - Color helper

extension Color {
    /// Create a Color from a 24-bit hex value, e.g. `Color(hex: 0xBA0721)`.
    /// Keeps the design tokens below readable and identical to the design file.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex         & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Design tokens

/// Single source of truth for colors, spacing and type.
/// Change a value here and the entire app updates (this is the "design system").
enum Theme {

    // Brand
    static let red        = Color(hex: 0xBA0721)   // primary action color ("Red 00")
    static let redSoft    = Color(hex: 0xFFE7E7)   // tinted backgrounds ("Red 7")
    static let gold       = Color(hex: 0xFFB200)   // accent dot / highlights
    static let goldSoft   = Color(hex: 0xF6E7C8)   // badge background
    static let goldText   = Color(hex: 0x8A6A2E)   // badge text

    // Surfaces
    static let background = Color(hex: 0xF5F5F7)   // app background
    static let card       = Color.white            // content cards stay solid & clear
    static let hairline   = Color(hex: 0xE5E5E5)

    // Text
    static let textPrimary   = Color(hex: 0x1C1C1E)
    static let textSecondary = Color(hex: 0x8A8A8E)
    static let textBody      = Color(hex: 0x5C5C62)

    // Status
    static let success = Color(hex: 0x1E7B34)

    // Layout
    static let screenPadding: CGFloat = 20
    static let cardRadius: CGFloat = 22
    static let pillRadius: CGFloat = 26

    /// 100 points = $1 (the rule used for every points calculation).
    static let pointsPerDollar = 100
}

// MARK: - Type scale (SF Pro via system fonts → supports Dynamic Type)

extension Font {
    static let ltLargeTitle  = Font.system(size: 34, weight: .bold)
    static let ltTitle       = Font.system(size: 22, weight: .bold)
    static let ltHeadline    = Font.system(size: 17, weight: .semibold)
    static let ltBody    = Font.system(size: 15, weight: .regular)
    static let ltCaption     = Font.system(size: 13, weight: .regular)
    static let ltCaptionBold = Font.system(size: 12, weight: .semibold)
}
