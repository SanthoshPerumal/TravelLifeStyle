import SwiftUI

/// Day 3 – Fixed date, party-size stepper and time slots with SOLD OUT logic.
struct DiningTimeView: View {
    @EnvironmentObject var app: AppState

    /// A slot can be booked only when the table is big enough for the party.
    private func fits(_ s: TimeSlot) -> Bool { s.tableSize >= app.party }

    var body: some View {
        Screen(title: "Date & time") {
            VStack(spacing: 14) {
                KeyValueRow(key: "Date", value: "01/01/2027")
                Divider()
                Stepper(value: $app.party, in: 1...6) {
                    Text("Party size: \(app.party)").font(.ltBody)
                }
            }
            .padding(18).card()
            // If the chosen slot stops fitting after the party changes, clear it.
            .onChange(of: app.party) { _, _ in
                if let s = app.slot, !fits(s) { app.slot = nil }
            }

            SectionTitle(text: "Available times")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Sample.slots) { s in
                    let ok = fits(s)
                    Button { if ok { app.slot = s } } label: {
                        VStack(spacing: 4) {
                            Text(s.time).font(.ltHeadline)
                            Text(ok ? "\(s.tablesLeft) tables · up to \(s.tableSize)" : "SOLD OUT")
                                .font(.ltCaption)
                                .foregroundStyle(ok ? Theme.textSecondary : Theme.red)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(ok ? Theme.textPrimary : Theme.textSecondary)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(app.slot?.id == s.id ? Theme.red : Theme.hairline, lineWidth: 1.5))
                        .opacity(ok ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .disabled(!ok)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar { PillButton(title: "Continue", enabled: app.slot != nil) { app.push(.diningGuest) } }
        }
    }
}
