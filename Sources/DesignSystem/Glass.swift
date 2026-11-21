import SwiftUI

// MARK: - Liquid Glass with fallback

/// Apple's HIG: Liquid Glass belongs to the *navigation / control layer*
/// (tab bars, floating buttons, sticky action bars) – NOT to content cards.
/// So the app only uses `.glass(in:)` for those controls.
///
/// * iOS 26+ (built with Xcode 26 / Swift 6.2): real `glassEffect`.
/// * Older OS or older Xcode: a frosted `.ultraThinMaterial` look-alike.
extension View {

    @ViewBuilder
    func glass<S: Shape>(in shape: S) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            // Native Liquid Glass.
            self.glassEffect(.regular, in: shape)
        } else {
            self.frostedFallback(in: shape)
        }
        #else
        self.frostedFallback(in: shape)
        #endif
    }

    /// Frosted-glass approximation used on iOS 17–25.
    fileprivate func frostedFallback<S: Shape>(in shape: S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(Color.white.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
    }
}
