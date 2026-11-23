import SwiftUI

/// Bookings tab: upcoming reservations (the live Houston trip first, then
/// later trips) and past ones, switched with a segmented control. On a phone a
/// row pushes its details; on wide layouts (iPhone Duo open, iPad) the details
/// fill the secondary column.
struct BookingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum Tab: String, CaseIterable { case upcoming = "Upcoming", past = "Past" }
    /// What the secondary column shows.
    enum Selection: Hashable { case item(TripItem), booking(String) }

    @State private var tab: Tab = .upcoming
    @State private var selected: Selection = .item(.hotel)

    private var isSplit: Bool { sizeClass == .regular }
    private var trips: [Trip] { tab == .upcoming ? Sample.upcomingTrips : Sample.pastTrips }
    private var count: Int {
        trips.reduce(0) { $0 + $1.bookings.count } + (tab == .upcoming ? TripItem.allCases.count : 0)
    }

    var body: some View {
        AdaptiveSplit {
            Screen(title: "Bookings") {
                Picker("Bookings", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text(tab == .upcoming ? "\(count) upcoming reservations" : "\(count) past reservations")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)

                if tab == .upcoming {
                    tripHeader(Sample.city, Sample.dates, note: "Current trip")
                    ForEach(TripItem.allCases) { item in
                        Button { select(.item(item)) { app.push(.tripItem(item)) } } label: {
                            row(item).splitSelection(isSplit && selected == .item(item))
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(trips) { trip in
                    tripHeader(trip.city, trip.datesText, note: nil)
                    ForEach(trip.bookings) { b in
                        Button { select(.booking(b.id)) { app.push(.booking(b.id)) } } label: {
                            BookingRow(booking: b, showsDate: false)
                                .splitSelection(isSplit && selected == .booking(b.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } secondary: {
            switch selected {
            case .item(let item):   TripItemDetailView(item: item).id(selected)
            case .booking(let id):  BookingDetailView(bookingID: id).id(selected)
            }
        }
        .onChange(of: tab) {
            // Keep the detail pane on something from the visible list.
            if tab == .past, let first = Sample.pastTrips.first?.bookings.first { selected = .booking(first.id) }
            if tab == .upcoming { selected = .item(.hotel) }
        }
    }

    private func select(_ s: Selection, push: () -> Void) {
        if isSplit { selected = s } else { push() }
    }

    /// "New York · Feb 12 – 15, 2027" above a trip's bookings.
    private func tripHeader(_ city: String, _ dates: String, note: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(city).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
            Text(dates).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            Spacer()
            if let note { Text(note).font(.ltCaptionBold).foregroundStyle(Theme.success) }
        }
        .padding(.top, 8)
    }

    private func row(_ item: TripItem) -> some View {
        let summary = TripItemSummary(item: item, app: app)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.icon)
                .font(.headline).foregroundStyle(Theme.icon)
                .frame(width: 44, height: 44)
                .background(Theme.background, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(summary.subtitle).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                StatusTag(confirmed: summary.confirmed).padding(.top, 2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
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
