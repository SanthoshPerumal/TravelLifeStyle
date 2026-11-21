import SwiftUI

/// Day 3 – $400 deposit, payable with points and/or the (simulated) card.
struct DiningPayView: View {
    @EnvironmentObject var app: AppState
    @State private var agreed = false

    var body: some View {
        Screen(title: "Payment") {
            VStack(spacing: 10) {
                KeyValueRow(key: "Refundable deposit", value: Money.usd(app.diningDeposit))
                KeyValueRow(key: "Points applied", value: "−\(Money.usd(app.diningPointsUsed / Theme.pointsPerDollar))")
                Divider()
                KeyValueRow(key: "Card total", value: Money.usd(app.diningCash), bold: true)
            }
            .padding(18).card()

            PointsSlider(value: $app.diningPointsUsed,
                         maxValue: min(app.points, app.diningDeposit * Theme.pointsPerDollar),
                         balance: app.points)

            Text("Free cancellation up to 48 hours before your reservation; after that the deposit is forfeited.")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)

            Toggle("I agree to the terms & conditions", isOn: $agreed).tint(Theme.red)
                .font(.ltBody).padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar { PillButton(title: "Review reservation", enabled: agreed) { app.push(.diningConfirmed) } }
        }
    }
}
