import SwiftUI

/// Slider that lets the user choose how many reward points to spend.
/// Steps of 100 points (= $1) so the dollar value is always a whole number.
struct PointsSlider: View {
    @Binding var value: Int
    let maxValue: Int
    var balance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Use points").font(.ltHeadline)
                Spacer()
                Text("\(value.formatted()) pts = \(Money.usd(value / Theme.pointsPerDollar))")
                    .font(.ltBody).foregroundStyle(Theme.textBody)
            }
            // Bridge Int <-> Double because SwiftUI's Slider works with Double.
            Slider(
                value: Binding(get: { Double(value) }, set: { value = Int($0) }),
                in: 0...Double(max(maxValue, 100)),
                step: 100
            )
            HStack {
                Chip(title: "Card only", selected: value == 0) { value = 0 }
                Chip(title: "Max points", selected: value == maxValue) { value = maxValue }
                Spacer()
            }
            Text("Balance: \(balance.formatted()) pts")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)
        }
        .padding(18)
        .card()
    }
}
