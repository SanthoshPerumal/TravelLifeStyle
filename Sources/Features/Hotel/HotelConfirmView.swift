import SwiftUI

/// Day 2 – Final review. "Book now" is blocked while in progress to stop double bookings.
struct HotelConfirmView: View {
    @EnvironmentObject var app: AppState
    @State private var agreed = false
    @State private var booking = false      // true while the (simulated) request runs

    var body: some View {
        Screen(title: "Complete booking") {
            VStack(alignment: .leading, spacing: 8) {
                Text(app.hotel.name).font(.ltHeadline)
                Text("\(app.room.name) · \(Sample.dates)").font(.ltBody).foregroundStyle(Theme.textBody)
                Text("\(Sample.guests) guests").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            VStack(spacing: 10) {
                KeyValueRow(key: "Points", value: Money.pts(app.hotelPointsUsed))
                KeyValueRow(key: "Card", value: Money.usd(app.hotelCash))
                Divider()
                KeyValueRow(key: "Total", value: Money.usd(app.hotelTotal), bold: true)
            }
            .padding(18).card()

            Toggle("I agree to the terms and cancellation policy", isOn: $agreed)
                .tint(Theme.red).font(.ltBody).padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: booking ? "Booking…" : "Book now", enabled: agreed && !booking) {
                    booking = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)   // simulate network
                        app.finishHotel()
                        app.push(.hotelBooked)
                    }
                }
            }
        }
    }
}
