import SwiftUI

/// Details of one trip entry (flight, hotel stay or dinner). Used as the
/// secondary pane of the itinerary and Bookings tab, and pushed on a phone.
struct TripItemDetailView: View {
    @EnvironmentObject var app: AppState
    let item: TripItem

    var body: some View {
        let summary = TripItemSummary(item: item, app: app)
        Screen(title: title) {
            header(summary)
            switch item {
            case .flight: flight
            case .hotel:  hotel
            case .dining: dining
            }
        }
    }

    private var title: String {
        switch item {
        case .flight: return "Flight"
        case .hotel:  return "Hotel stay"
        case .dining: return "Dinner"
        }
    }

    private func header(_ summary: TripItemSummary) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Label(summary.title, systemImage: item.icon).font(.ltHeadline)
                Text(summary.subtitle).font(.ltBody).foregroundStyle(Theme.textBody)
            }
            Spacer()
            StatusTag(confirmed: summary.confirmed)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
    }

    // MARK: Flight

    @ViewBuilder private var flight: some View {
        VStack(spacing: 10) {
            KeyValueRow(key: "Flight", value: "UA 1203")
            KeyValueRow(key: "Route", value: "LAX → IAH")
            KeyValueRow(key: "Date", value: "Jan 1, 2027")
            KeyValueRow(key: "Departs", value: "11:15 AM")
            KeyValueRow(key: "Boards", value: "10:40 AM")
            KeyValueRow(key: "Gate", value: "22B")
            KeyValueRow(key: "Cabin", value: "Main Cabin", bold: true)
        }
        .padding(Theme.cardPadding).card()

        VStack(spacing: 12) {
            Image(systemName: "qrcode").font(.system(size: 96)).foregroundStyle(Theme.textPrimary)
            Text("Boarding pass").font(.ltCaption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(24).card()
    }

    // MARK: Hotel

    @ViewBuilder private var hotel: some View {
        if app.hotelBooked {
            SceneArt(kind: app.hotel.scene).frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            VStack(spacing: 10) {
                KeyValueRow(key: "Confirmation", value: "CB-4829163")
                KeyValueRow(key: "Booking", value: "ASP-90027415")
                KeyValueRow(key: "Hotel", value: app.hotel.name)
                KeyValueRow(key: "Room", value: app.room.name)
                KeyValueRow(key: "Dates", value: Sample.dates)
                KeyValueRow(key: "Guests", value: "\(Sample.guests)")
                Divider()
                KeyValueRow(key: "Points", value: Money.pts(app.hotelPointsUsed))
                KeyValueRow(key: "Card", value: Money.usd(app.hotelCash))
                KeyValueRow(key: "Total", value: Money.usd(app.hotelTotal), bold: true)
            }
            .padding(Theme.cardPadding).card()
        } else {
            notBooked("No hotel booked for this trip yet.", action: "Find a hotel") { app.push(.hotelResults) }
        }
    }

    // MARK: Dining

    @ViewBuilder private var dining: some View {
        if app.diningBooked {
            VStack(spacing: 10) {
                KeyValueRow(key: "Reservation", value: "RSV-7K2M9Q")
                KeyValueRow(key: "Restaurant", value: app.restaurant.name)
                KeyValueRow(key: "Area", value: app.restaurant.area)
                KeyValueRow(key: "When", value: "\(app.dining.dateText) · \(app.slot?.time ?? "–")")
                KeyValueRow(key: "Party", value: "\(app.party)")
                KeyValueRow(key: "Seating", value: app.seating.title)
                Divider()
                KeyValueRow(key: "Points", value: Money.pts(app.diningPointsUsed))
                KeyValueRow(key: "Deposit", value: Money.usd(app.diningDeposit), bold: true)
            }
            .padding(Theme.cardPadding).card()
        } else {
            notBooked("No table reserved yet.", action: "Reserve a table") {
                app.push(.diningSearch)
            }
        }
    }

    private func notBooked(_ message: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(message).font(.ltBody).foregroundStyle(Theme.textBody)
            PillButton(title: action, action: perform)
        }
        .padding(Theme.cardPadding).card()
    }
}
