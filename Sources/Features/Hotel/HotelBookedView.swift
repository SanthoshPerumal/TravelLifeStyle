import SwiftUI

/// Day 2 – Success: booking record + unified itinerary + new points balance.
struct HotelBookedView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        // Wide layouts: booking details on the left, the full trip itinerary on the right.
        AdaptiveSplit {
            confirmation
        } secondary: {
            ItineraryView()
        }
        .navigationBarBackButtonHidden(true)     // booking is done – no going back into checkout
        .safeAreaInset(edge: .bottom) {
            if sizeClass != .regular {
                StickyBar {
                    PillButton(title: "View itinerary") {
                        app.path = [.itinerary]
                    }
                }
            }
        }
    }

    private var confirmation: some View {
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
                KeyValueRow(key: "Dates", value: app.search.datesText)
                KeyValueRow(key: "Guests", value: app.search.travelersText)
                KeyValueRow(key: "Guest name", value: app.guest.fullName)
                KeyValueRow(key: "Points balance", value: Money.pts(app.points), bold: true)
            }
            .padding(Theme.cardPadding).card()

            // Unified itinerary preview (the full itinerary is beside it on wide layouts)
            if sizeClass != .regular {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your trip").font(.ltHeadline)
                    Label("Flight LAX → IAH · Jan 1", systemImage: "airplane")
                    Label("\(app.hotel.name) · \(app.search.nightsText)", systemImage: "bed.double")
                }
                .font(.ltBody).foregroundStyle(Theme.textBody)
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
            } else {
                PillButton(title: "Done") { app.goHome() }
            }
        }
    }
}
