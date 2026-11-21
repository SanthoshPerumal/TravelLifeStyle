import SwiftUI

/// Day 3 – Review → Confirm → success with the unified itinerary.
struct DiningConfirmedView: View {
    @EnvironmentObject var app: AppState
    @State private var working = false

    var body: some View {
        Screen(title: app.diningBooked ? "Confirmed" : "Review") {
            if app.diningBooked {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.success)
                    Text("Table reserved").font(.ltTitle)
                    Text("Reservation ID RSV-7K2M9Q").font(.ltBody).foregroundStyle(Theme.textBody)
                }
                .frame(maxWidth: .infinity).padding(24).card()
            }

            VStack(spacing: 10) {
                KeyValueRow(key: "Restaurant", value: Sample.restaurant.name)
                KeyValueRow(key: "When", value: "01/01/2027 · \(app.slot?.time ?? "–")")
                KeyValueRow(key: "Party", value: "\(app.party)")
                KeyValueRow(key: "Points balance", value: Money.pts(app.points), bold: true)
            }
            .padding(18).card()

            if app.diningBooked {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your trip").font(.ltHeadline)
                    Label("Flight LAX → IAH · Jan 1", systemImage: "airplane")
                    Label("\(app.hotelBooked ? app.hotel.name : "Hotel not booked")", systemImage: "bed.double")
                    Label("\(Sample.restaurant.name) · \(app.slot?.time ?? "")", systemImage: "fork.knife")
                }
                .font(.ltBody).foregroundStyle(Theme.textBody)
                .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()
            }
        }
        .navigationBarBackButtonHidden(app.diningBooked)
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                if app.diningBooked {
                    PillButton(title: "View itinerary") { app.path = [.itinerary] }
                } else {
                    PillButton(title: working ? "Confirming…" : "Confirm reservation", enabled: !working) {
                        working = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)   // simulated request
                            app.finishDining()
                        }
                    }
                }
            }
        }
    }
}
