import SwiftUI

/// Bookings tab: every reservation on the trip. On a phone a row pushes its
/// details; on wide layouts (iPhone Duo open, iPad) the details fill the
/// secondary column.
struct BookingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selected: TripItem = .hotel

    private var isSplit: Bool { sizeClass == .regular }

    var body: some View {
        AdaptiveSplit {
            Screen(title: "Bookings") {
                Text("\(Sample.city) · \(Sample.dates)").font(.ltBody).foregroundStyle(Theme.textBody)
                ForEach(TripItem.allCases) { item in
                    Button {
                        if isSplit { selected = item } else { app.push(.tripItem(item)) }
                    } label: {
                        row(item).splitSelection(isSplit && selected == item)
                    }
                    .buttonStyle(.plain)
                }
            }
        } secondary: {
            TripItemDetailView(item: selected).id(selected)
        }
    }

    private func row(_ item: TripItem) -> some View {
        let summary = TripItemSummary(item: item, app: app)
        return HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.headline).foregroundStyle(Theme.icon)
                .frame(width: 44, height: 44)
                .background(Theme.background, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(summary.subtitle).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            StatusTag(confirmed: summary.confirmed)
        }
        .padding(16)
        .card()
    }
}

/// Title / subtitle / status for a trip entry, shared by the list and detail.
struct TripItemSummary {
    let title: String
    let subtitle: String
    let confirmed: Bool

    @MainActor
    init(item: TripItem, app: AppState) {
        switch item {
        case .flight:
            title = "UA 1203 · LAX → IAH"
            subtitle = "Jan 1 · 11:15 AM · Main Cabin"
            confirmed = true
        case .hotel:
            title = app.hotelBooked ? app.hotel.name : "Hotel"
            subtitle = app.hotelBooked ? "\(app.room.name) · \(Sample.nights) nights" : "Not booked yet"
            confirmed = app.hotelBooked
        case .dining:
            title = app.diningBooked ? app.restaurant.name : "Dinner"
            subtitle = app.diningBooked
                ? "\(app.dining.dateText) · \(app.slot?.time ?? "–") · party of \(app.party)"
                : "Not reserved yet"
            confirmed = app.diningBooked
        }
    }
}

/// "Confirmed" / "Pending" pill.
struct StatusTag: View {
    let confirmed: Bool
    var body: some View {
        Text(confirmed ? "Confirmed" : "Pending")
            .font(.ltCaptionBold)
            .foregroundStyle(confirmed ? Theme.success : Theme.goldText)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(confirmed ? Theme.success.opacity(0.12) : Theme.goldSoft, in: Capsule())
    }
}
