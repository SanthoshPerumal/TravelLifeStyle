import SwiftUI

/// Day 2 – Reprice alert + payment (points slider + simulated card).
struct HotelPayView: View {
    @EnvironmentObject var app: AppState

    /// The user must accept the new price before continuing.
    @State private var accepted = false

    private var oldTotal: Int { Money.total(nightly: app.roomNightly) }

    var body: some View {
        Screen(title: "Payment") {
            // Reprice alert
            VStack(alignment: .leading, spacing: 10) {
                Label("Price changed", systemImage: "exclamationmark.triangle.fill")
                    .font(.ltHeadline).foregroundStyle(Theme.goldText)
                Text("The total went from \(Money.usd(oldTotal)) to \(Money.usd(app.hotelTotal)).")
                    .font(.ltBody).foregroundStyle(Theme.textBody)
                Toggle("I accept the new price", isOn: $accepted).tint(Theme.red)
            }
            .padding(18).background(Theme.goldSoft.opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            // Price breakdown
            VStack(spacing: 10) {
                let nightly = app.roomNightly + Sample.repricePerNight
                KeyValueRow(key: "\(app.room.name) × \(Sample.nights) nights", value: Money.usd(nightly * Sample.nights))
                KeyValueRow(key: "Taxes & fees (13%)", value: Money.usd(app.hotelTotal - nightly * Sample.nights))
                Divider()
                KeyValueRow(key: "Total", value: Money.usd(app.hotelTotal), bold: true)
                if app.hotel.percentOff > 0 {
                    Label("Includes \(app.hotel.percentOff)% hotel offer", systemImage: "tag.fill")
                        .font(.ltCaptionBold).foregroundStyle(Theme.success)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(18).card()

            PointsSlider(value: $app.hotelPointsUsed,
                         maxValue: min(app.points, app.hotelTotal * Theme.pointsPerDollar),
                         balance: app.points)

            // Card is simulated – never collect real card data in this POC.
            HStack {
                Image(systemName: "creditcard.fill").foregroundStyle(Theme.red)
                Text("Autograph Journey •••• 4821").font(.ltBody)
                Spacer()
                Text(Money.usd(app.hotelCash)).font(.ltHeadline)
            }
            .padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar { PillButton(title: "Review booking", enabled: accepted) { app.push(.hotelConfirm) } }
        }
    }
}
