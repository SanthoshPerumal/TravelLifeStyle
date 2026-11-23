import SwiftUI

/// Day 4 – Trip itinerary (Concur-style): trip hero + per-day timeline.
struct ItineraryView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// The date chips across the top (Dec 31 … Jan 5).
    private let days = ["31", "1", "2", "3", "4", "5"]
    @State private var selectedDay = "1"
    /// Timeline entry shown in the secondary column on wide layouts.
    @State private var selectedItem: TripItem = .flight

    private var isSplit: Bool { sizeClass == .regular }

    var body: some View {
        AdaptiveSplit {
            timeline
        } secondary: {
            TripItemDetailView(item: selectedItem).id(selectedItem)
        }
    }

    private var timeline: some View {
        Screen(title: "Itinerary") {
            // Trip hero with a flight sub-card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Your Trip in Houston").font(.ltHeadline)
                    Spacer()
                    Circle().fill(Theme.success).frame(width: 10, height: 10)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label("UA 1203 · Main Cabin", systemImage: "airplane").font(.ltBody)
                    Text("Gate 22B · Boards 10:40 AM").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

            // Date selector
            Text("Daily Flow").font(.ltTitle)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(days, id: \.self) { d in
                        Button { selectedDay = d } label: {
                            Text(d).font(.ltHeadline)
                                .frame(width: 48, height: 56)
                                .foregroundStyle(selectedDay == d ? .white : Theme.textPrimary)
                                .background(selectedDay == d ? Theme.button : Color.white,
                                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Theme.hairline, lineWidth: selectedDay == d ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text("Jan \(selectedDay)").font(.ltHeadline)
                Spacer()
                Text("3 Planned").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }

            // Timeline – a leading dotted rail with cards.
            timelineCard(.flight, title: "Flight to Houston", sub: "LAX → IAH · 11:15 AM") {
                HStack { Text("Boarding pass"); Spacer(); Image(systemName: "qrcode") }
                    .font(.ltCaption).foregroundStyle(Theme.textBody)
            }
            timelineCard(.hotel, title: app.hotelBooked ? app.hotel.name : "Hotel check-in",
                         sub: "Check-in 3:00 PM") { EmptyView() }
            timelineCard(.dining, title: app.restaurant.name,
                         sub: "Dinner · \(app.slot?.time ?? app.dining.timeText) · party of \(app.party)") { EmptyView() }

            // Display-only actions (POC). See README for the note on these.
            HStack {
                PillButton(title: "Add Activity", kind: .secondary) {}
                PillButton(title: "Wallet Passes") {}
            }
            .padding(.top, 4)
        }
    }

    /// One timeline row: dot + connecting line + content card. Tapping it opens
    /// the entry's details (pushed on a phone, in the secondary column when wide).
    private func timelineCard<Extra: View>(
        _ item: TripItem, title: String, sub: String, @ViewBuilder extra: () -> Extra
    ) -> some View {
        Button {
            if isSplit { selectedItem = item } else { app.push(.tripItem(item)) }
        } label: {
            timelineRow(item, title: title, sub: sub, extra: extra)
        }
        .buttonStyle(.plain)
    }

    private func timelineRow<Extra: View>(
        _ item: TripItem, title: String, sub: String, @ViewBuilder extra: () -> Extra
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Circle().fill(Theme.icon).frame(width: 12, height: 12)
                Rectangle().fill(Theme.hairline).frame(width: 2).frame(maxHeight: .infinity)
            }
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: item.icon).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(sub).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                extra()
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16).card()
            .splitSelection(isSplit && selectedItem == item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
