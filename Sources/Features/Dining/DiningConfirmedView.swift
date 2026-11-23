import SwiftUI

/// Success: reservation record, unified trip preview and the new points balance.
struct DiningConfirmedView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Screen(title: "Confirmed") {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.success)
                Text("Table reserved").font(.ltTitle)
                Text("Confirmation RSV-7K2M9Q").font(.ltBody).foregroundStyle(Theme.textBody)
            }
            .frame(maxWidth: .infinity).padding(24).card()

            DiningSummary()

            VStack(spacing: 10) {
                KeyValueRow(key: "Name", value: app.guest.fullName)
                KeyValueRow(key: "Seating", value: app.seating.title)
                if app.diningRequests.occasion != .none {
                    KeyValueRow(key: "Occasion", value: app.diningRequests.occasion.rawValue)
                }
                KeyValueRow(key: "Deposit paid", value: Money.usd(app.diningDeposit))
                KeyValueRow(key: "Points balance", value: Money.pts(app.points), bold: true)
                Text("Free cancellation until \(app.diningCancelDeadline)")
                    .font(.ltCaptionBold).foregroundStyle(Theme.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.cardPadding).card()

            VStack(alignment: .leading, spacing: 10) {
                Label(app.restaurant.address, systemImage: "mappin.and.ellipse")
                Label(app.restaurant.hoursText, systemImage: "clock")
            }
            .font(.ltBody).foregroundStyle(Theme.textBody)
            .labelStyle(IconLabelStyle())
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

            VStack(alignment: .leading, spacing: 12) {
                Text("Your trip").font(.ltHeadline)
                Label("Flight LAX → IAH · Jan 1", systemImage: "airplane")
                Label(app.hotelBooked ? app.hotel.name : "Hotel not booked", systemImage: "bed.double")
                Label("\(app.restaurant.name) · \(app.slot?.time ?? app.dining.timeText)", systemImage: "fork.knife")
            }
            .font(.ltBody).foregroundStyle(Theme.textBody)
            .labelStyle(IconLabelStyle())
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
        }
        .navigationBarBackButtonHidden(true)     // reservation is done – no going back into checkout
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: "Done", kind: .secondary) { app.goHome() }
                PillButton(title: "View itinerary") { app.path = [.itinerary] }
            }
        }
    }
}
