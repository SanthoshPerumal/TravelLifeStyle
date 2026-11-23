import SwiftUI

/// Day 2 – Final review. "Book now" is blocked while in progress to stop double bookings.
struct HotelConfirmView: View {
    @EnvironmentObject var app: AppState
    @State private var agreed = false
    @State private var booking = false      // true while the (simulated) request runs

    var body: some View {
        Screen(title: "Complete booking") {
            StaySummary()

            VStack(alignment: .leading, spacing: 10) {
                Text("Guest").font(.ltHeadline)
                KeyValueRow(key: "Name", value: app.guest.fullName)
                KeyValueRow(key: "Email", value: app.guest.email)
                if !app.guest.phone.isEmpty { KeyValueRow(key: "Phone", value: app.guest.phone) }
                KeyValueRow(key: "Arrival", value: app.guest.arrival)
                if !app.guest.requests.isEmpty {
                    Text("“\(app.guest.requests)”").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Text(app.rate == .flexible ? app.search.freeCancellationText : "Non-refundable – no refund if you cancel")
                    .font(.ltCaptionBold)
                    .foregroundStyle(app.rate == .flexible ? Theme.success : Theme.goldText)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

            VStack(spacing: 10) {
                KeyValueRow(key: "Points", value: Money.pts(app.hotelPointsUsed))
                KeyValueRow(key: "Card", value: Money.usd(app.hotelCash))
                Divider()
                KeyValueRow(key: "Total", value: Money.usd(app.hotelTotal), bold: true)
            }
            .padding(Theme.cardPadding).card()

            Toggle("I agree to the terms and cancellation policy", isOn: $agreed)
                .tint(Theme.button).font(.ltBody).padding(Theme.cardPadding).card()
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
