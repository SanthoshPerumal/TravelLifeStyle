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
    static let red        = Color(hex: 0xBA0721)   // errors & notification badges only ("Red 00")
    static let redSoft    = Color(hex: 0xFFE7E7)   // tinted backgrounds ("Red 7")
    static let gold       = Color(hex: 0xFFB200)   // accent dot / highlights
    static let goldSoft   = Color(hex: 0xF6E7C8)   // badge background
    static let goldText   = Color(hex: 0x8A6A2E)   // badge text

    // Buttons
    /// Fill for primary buttons and outline/text for secondary buttons
    /// (dark warm brown, replaces red on buttons).
    static let button     = Color(hex: 0x463D3A)

    // Surfaces
    static let background = Color(hex: 0xF5F5F7)   // app background
    static let headerTintTop    = Color(hex: 0xE4DBD1)   // warm tint behind the landing header
    static let headerTintBottom = Color(hex: 0xEFE9E3)
    /// Neutral tint for content icons (services grid, list icons). Red is kept
    /// for errors and badges; buttons and selection use `button`.
    static let icon             = Color(hex: 0x3A3A3C)
    /// Dark scrim behind white text on photos (offer badges).
    static let photoBadge       = Color.black.opacity(0.68)
    static let rewardsStrip     = Color(hex: 0xF4F2FB)   // lavender rewards row on account tiles
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

// MARK: - Type scale
// Built on Apple's text styles (SF Pro) so every size follows the HIG type
// ramp and scales with Dynamic Type. Avoid `.system(size:)` for text.
// Default sizes: largeTitle 34 · title 28 · title2 22 · title3 20 · headline 17
// semibold · body 17 · callout 16 · subheadline 15 · footnote 13 · caption 12 ·
// caption2 11 (the HIG minimum).

extension Font {
    static let ltLargeTitle  = Font.largeTitle.bold()
    static let ltTitle       = Font.title2.bold()
    static let ltHeadline    = Font.headline
    static let ltBody        = Font.body
    static let ltCaption     = Font.footnote
    static let ltCaptionBold = Font.caption.weight(.semibold)
}
