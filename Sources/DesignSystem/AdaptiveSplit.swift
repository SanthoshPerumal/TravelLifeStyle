import SwiftUI

// MARK: - Adaptive master-detail

/// True for a screen rendered inside the secondary (detail) column of an
/// `AdaptiveSplit`. `Screen` reads it to show an inline header instead of
/// claiming the navigation bar title, which belongs to the primary column.
private struct SplitDetailKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    var isSplitDetail: Bool {
        get { self[SplitDetailKey.self] }
        set { self[SplitDetailKey.self] = newValue }
    }
}

/// Primary/secondary layout keyed on horizontal size class.
///
/// - Compact width (a regular iPhone, or an iPhone Duo folded shut): only the
///   primary column is shown and the caller pushes the detail as before.
/// - Regular width (an iPhone Duo's large inner screen, iPad): the primary list
///   and the selected item's details sit side by side.
///
/// Both columns get a compact size class so views inside them lay out as on a
/// phone and never nest a second split.
struct AdaptiveSplit<Primary: View, Secondary: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let isEnabled: Bool
    private let primary: Primary
    private let secondary: Secondary

    init(isEnabled: Bool = true,
         @ViewBuilder primary: () -> Primary,
         @ViewBuilder secondary: () -> Secondary) {
        self.isEnabled = isEnabled
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        if isEnabled && sizeClass == .regular {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    primary
                        .frame(width: min(max(geo.size.width * 0.4, 320), 420))
                        .environment(\.horizontalSizeClass, .compact)
                    Divider()
                    secondary
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .environment(\.horizontalSizeClass, .compact)
                        .environment(\.isSplitDetail, true)
                }
            }
            .background(Theme.background.ignoresSafeArea())
        } else {
            primary
        }
    }
}

extension View {
    /// Red outline marking the row whose details fill the secondary column.
    func splitSelection(_ selected: Bool) -> some View {
        overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .stroke(selected ? Theme.red : .clear, lineWidth: 2))
    }
}
