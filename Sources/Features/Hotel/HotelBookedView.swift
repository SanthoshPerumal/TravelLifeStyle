import SwiftUI

/// Day 2 – Success: booking record + unified itinerary + new points balance.
struct HotelBookedView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Screen(title: "Booked") {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.success)
                Text("Added to your itinerary").font(.ltTitle)
                Text("Confirmation CB-4829163").font(.ltBody).foregroundStyle(Theme.textBody)
            }
            .frame(maxWidth: .infinity).padding(24).card()

            VStack(spacing: 10) {
                KeyValueRow(key: "Booking", value: "ASP-90027415")
                KeyValueRow(key: "Hotel", value: app.hotel.name)
                KeyValueRow(key: "Room", value: app.room.name)
                KeyValueRow(key: "Dates", value: Sample.dates)
                KeyValueRow(key: "Points balance", value: Money.pts(app.points), bold: true)
            }
            .padding(18).card()

            // Unified itinerary preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Your trip").font(.ltHeadline)
                Label("Flight LAX → IAH · Jan 1", systemImage: "airplane")
                Label("\(app.hotel.name) · 2 nights", systemImage: "bed.double")
            }
            .font(.ltBody).foregroundStyle(Theme.textBody)
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()
        }
        .navigationBarBackButtonHidden(true)     // booking is done – no going back into checkout
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: "View itinerary") {
                    app.path = [.itinerary]
                }
            }
        }
    }
}
