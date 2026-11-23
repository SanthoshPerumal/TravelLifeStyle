import SwiftUI

/// Final review. "Confirm reservation" is blocked while in progress to stop double bookings.
struct DiningReviewView: View {
    @EnvironmentObject var app: AppState
    @State private var agreed = false
    @State private var working = false

    var body: some View {
        Screen(title: "Review") {
            DiningSummary()

            VStack(alignment: .leading, spacing: 10) {
                Text("Guest").font(.ltHeadline)
                KeyValueRow(key: "Name", value: app.guest.fullName)
                KeyValueRow(key: "Email", value: app.guest.email)
                if !app.guest.phone.isEmpty { KeyValueRow(key: "Phone", value: app.guest.phone) }
                if app.diningRequests.occasion != .none {
                    KeyValueRow(key: "Occasion", value: app.diningRequests.occasion.rawValue)
                }
                if !app.diningRequests.dietary.isEmpty {
                    KeyValueRow(key: "Dietary", value: app.diningRequests.dietary.sorted().joined(separator: ", "))
                }
                if !app.diningRequests.notes.isEmpty {
                    Text("“\(app.diningRequests.notes)”").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            VStack(alignment: .leading, spacing: 10) {
                KeyValueRow(key: "Deposit", value: Money.usd(app.diningDeposit))
                KeyValueRow(key: "Points", value: Money.pts(app.diningPointsUsed))
                Divider()
                KeyValueRow(key: "Card", value: Money.usd(app.diningCash), bold: true)
                Text("Free cancellation until \(app.diningCancelDeadline)")
                    .font(.ltCaptionBold).foregroundStyle(Theme.success)
            }
            .padding(18).card()

            Toggle("I agree to the terms and cancellation policy", isOn: $agreed)
                .tint(Theme.button).font(.ltBody).padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: working ? "Confirming…" : "Confirm reservation", enabled: agreed && !working) {
                    working = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)   // simulated request
                        app.finishDining()
                        app.push(.diningConfirmed)
                    }
                }
            }
        }
    }
}
