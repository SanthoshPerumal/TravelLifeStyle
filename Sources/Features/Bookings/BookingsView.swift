import SwiftUI

/// Bookings tab: every reservation, split into Upcoming and Past by date and
/// grouped by trip. A booking stays upcoming until it ends, so a trip under way
/// shows in both lists. The live Houston trip lists its flight, hotel and dinner
/// (pending until booked) in whichever list its dates fall in. On a phone a row
/// pushes its details; on wide layouts (iPhone Duo open, iPad) the details fill
/// the secondary column.
struct BookingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum Tab: String, CaseIterable { case upcoming = "Upcoming", past = "Past" }
    /// What the secondary column shows.
    enum Selection: Hashable { case item(TripItem), booking(String) }

    @State private var tab: Tab = .upcoming
    @State private var selected: Selection = .item(.hotel)

    private var isSplit: Bool { sizeClass == .regular }
    private var live: Trip { app.liveTrip }
    /// The Houston entries belong to this tab.
    private var showsLive: Bool { live.isPast == (tab == .past) }
    private var groups: [BookingGroup] { Sample.bookingGroups(Sample.trips, past: tab == .past) }
    private var count: Int {
        groups.reduce(0) { $0 + $1.bookings.count } + (showsLive ? TripItem.allCases.count : 0)
    }

    var body: some View {
        AdaptiveSplit {
            Screen(title: "Bookings") {
                Picker("Bookings", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if count == 0 {
                    empty
                } else {
                    Text("\(count) \(tab == .upcoming ? "upcoming" : "past") reservation\(count == 1 ? "" : "s")")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }

                if showsLive {
                    tripHeader(live)
                    ForEach(TripItem.allCases) { item in
                        Button { select(.item(item)) { app.push(.tripItem(item)) } } label: {
                            row(item).splitSelection(isSplit && selected == .item(item))
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(groups) { group in
                    tripHeader(group.trip)
                    ForEach(group.bookings) { b in
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
        .onAppear(perform: selectFirst)
        .onChange(of: tab) { selectFirst() }
    }

    /// Keep the detail pane on the first entry of the visible list.
    private func selectFirst() {
        if showsLive { selected = .item(.flight) }
        else if let first = groups.first?.bookings.first { selected = .booking(first.id) }
    }

    private func select(_ s: Selection, push: () -> Void) {
        if isSplit { selected = s } else { push() }
    }

    /// "New York  Feb 12 – 15, 2027   In progress" above a trip's bookings.
    private func tripHeader(_ trip: Trip) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(trip.city).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
            Text(trip.datesText).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            Spacer()
            if trip.isInProgress {
                Text("In progress").font(.ltCaptionBold).foregroundStyle(Theme.success)
            }
        }
        .padding(.top, 8)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: tab == .upcoming ? "suitcase" : "clock.arrow.circlepath")
                .font(.largeTitle).foregroundStyle(Theme.textSecondary)
            Text(tab == .upcoming ? "No upcoming bookings" : "No past bookings").font(.ltHeadline)
            Text(tab == .upcoming ? "Trips you book will appear here." : "Completed and cancelled bookings will appear here.")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
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

// MARK: - Live trip

extension AppState {
    static let liveTripID = "houston"

    /// The Houston trip as bookings: the flight, plus the hotel and dinner once booked.
    var liveTrip: Trip {
        let cal = Calendar.current
        let flight = Sample.day(2027, 1, 1, 11, 15)
        var bookings = [
            Booking(id: "hou-flight", kind: .flight, title: "UA 1203 · LAX → IAH",
                    detail: "Fri, Jan 1 · 11:15 AM · Main Cabin", start: flight,
                    confirmation: "UA-HX4T2R", total: 0)
        ]
        if hotelBooked {
            bookings.append(Booking(
                id: "hou-hotel", kind: .hotel, title: hotel.name,
                detail: "\(search.nights) night\(search.nights == 1 ? "" : "s") · \(room.name)",
                start: cal.date(bySettingHour: 15, minute: 0, second: 0, of: search.checkIn) ?? search.checkIn,
                end: cal.date(bySettingHour: 11, minute: 0, second: 0, of: search.checkOut) ?? search.checkOut,
                confirmation: "", total: hotelTotal, photo: hotel.photo))
        }
        if diningBooked {
            let time = slot?.minutes ?? dining.time
            bookings.append(Booking(
                id: "hou-dinner", kind: .dining, title: restaurant.name,
                detail: "\(dining.dateText) · \(DiningSearch.timeText(time)) · party of \(party)",
                start: cal.date(byAdding: .minute, value: time, to: cal.startOfDay(for: dining.date)) ?? dining.date,
                confirmation: "", total: diningDeposit))
        }
        let end = bookings.map { $0.end ?? $0.start }.max() ?? flight
        return Trip(id: Self.liveTripID, city: Sample.city, region: "Texas, United States",
                    start: min(flight, bookings.map(\.start).min() ?? flight),
                    end: max(end, Sample.day(2027, 1, 3, 23, 59)),
                    photo: "HotelCaribbean", bookings: bookings)
    }
}
