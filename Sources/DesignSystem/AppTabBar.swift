import SwiftUI

/// The four root screens reached from the tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case home, explore, bookings, profile
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:     return "Home"
        case .explore:  return "Explore"
        case .bookings: return "Bookings"
        case .profile:  return "Profile"
        }
    }

    /// Outline symbol; the selected tab uses its filled variant.
    var icon: String {
        switch self {
        case .home:     return "house"
        case .explore:  return "safari"
        case .bookings: return "suitcase"
        case .profile:  return "person"
        }
    }
}

/// Floating Liquid Glass tab bar, shown only on the root screens. The selected
/// tab is red with a filled symbol; the others are grey outlines.
struct AppTabBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                let active = app.tab == tab
                Button { app.tab = tab } label: {
                    VStack(spacing: 2) {
                        Image(systemName: active ? tab.icon + ".fill" : tab.icon).font(.title3)
                        Text(tab.title).font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(active ? Theme.red : Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .glass(in: Capsule())
        .frame(maxWidth: 440)
        .padding(.horizontal, 28).padding(.bottom, 4)
    }
}

/// The root of the navigation stack: the selected tab's screen with the tab bar.
/// Screens pushed on top (bookings flows, details) cover it, so the tab bar only
/// appears on the four root screens.
struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Group {
            switch app.tab {
            case .home:     LandingView()
            case .explore:  ExploreView()
            case .bookings: BookingsView()
            case .profile:  PreferencesView()
            }
        }
        .safeAreaInset(edge: .bottom) { AppTabBar() }
    }
}
