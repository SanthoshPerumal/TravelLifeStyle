import SwiftUI

/// Deposit that holds the table, payable with points and/or the (simulated) card.
struct DiningPayView: View {
    @EnvironmentObject var app: AppState

    private var maxPoints: Int { min(app.points, app.diningDeposit * Theme.pointsPerDollar) }

    var body: some View {
        Screen(title: "Payment") {
            DiningSummary()

            VStack(spacing: 10) {
                KeyValueRow(key: "Deposit · \(app.party) × \(Money.usd(app.restaurant.depositPerGuest))",
                            value: Money.usd(app.diningDeposit))
                KeyValueRow(key: "Points applied", value: "−\(Money.usd(app.diningPointsUsed / Theme.pointsPerDollar))")
                Divider()
                KeyValueRow(key: "Due now", value: Money.usd(app.diningCash), bold: true)
                Label("Credited to your bill at \(app.restaurant.name)", systemImage: "arrow.uturn.backward.circle")
                    .font(.ltCaptionBold).foregroundStyle(Theme.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18).card()

            PointsSlider(value: $app.diningPointsUsed, maxValue: maxPoints, balance: app.points)

            // Card is simulated – never collect real card data in this POC.
            HStack {
                Image(systemName: "creditcard.fill").foregroundStyle(Theme.textSecondary)
                Text("Autograph Journey •••• 4821").font(.ltBody)
                Spacer()
                Text(Money.usd(app.diningCash)).font(.ltHeadline)
            }
            .padding(18).card()

            VStack(alignment: .leading, spacing: 8) {
                Text("Cancellation policy").font(.ltHeadline)
                Text("Free cancellation until \(app.diningCancelDeadline)")
                    .font(.ltCaptionBold).foregroundStyle(Theme.success)
                Text("After that, or if you don't show up, the deposit isn't refunded. Tables are held for 15 minutes.")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()
        }
        .onAppear { app.diningPointsUsed = min(app.diningPointsUsed, maxPoints) }
        .safeAreaInset(edge: .bottom) {
            StickyBar { PillButton(title: "Review reservation") { app.push(.diningReview) } }
        }
    }
}
