import SwiftUI

/// Day 3 – Restaurant details (record details + menu) → pick date & time.
struct DiningRestaurantView: View {
    @EnvironmentObject var app: AppState
    private let r = Sample.restaurant
    private let menu = [("Burrata & tomato", "$14"), ("Wild mushroom risotto", "$26"),
                        ("Branzino al forno", "$34"), ("Tiramisu", "$12")]

    var body: some View {
        Screen(title: r.name) {
            SceneArt(kind: .restaurant).frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("\(r.cuisine) · \(r.area)").font(.ltBody)
                Text("Open daily · 5:30 PM – 10:30 PM").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text("$400 refundable deposit holds your table.").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            SectionTitle(text: "Menu highlights")
            VStack(spacing: 12) {
                ForEach(menu, id: \.0) { KeyValueRow(key: $0.0, value: $0.1) }
            }
            .padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar { PillButton(title: "Select date & time") { app.push(.diningTime) } }
        }
    }
}
