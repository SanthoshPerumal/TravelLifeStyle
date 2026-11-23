import SwiftUI

// MARK: - Dining building blocks shared by the "Reserve a table" screens.

/// A photo asset that fills its frame (callers round the corners).
struct FillPhoto: View {
    let name: String
    var width: CGFloat? = nil
    let height: CGFloat

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay { Image(name).resizable().scaledToFill() }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// "Italian · Montrose · $$$"
struct RestaurantMeta: View {
    let restaurant: Restaurant
    var body: some View {
        Text("\(restaurant.cuisine.title) · \(restaurant.area) · \(restaurant.priceText)")
            .foregroundStyle(Theme.textSecondary)
    }
}

/// Bookable time. Selected uses the primary button style, otherwise secondary.
struct TimeChip: View {
    let slot: TimeSlot
    var selected = false
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(slot.time)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(slot.available ? (selected ? Color.white : Theme.button) : Theme.textSecondary)
                .strikethrough(!slot.available)
                .frame(maxWidth: compact ? nil : .infinity)
                .padding(.horizontal, compact ? 14 : 0)
                .frame(minHeight: 40)
                .background(selected ? Theme.button : Color.white, in: Capsule())
                .overlay(Capsule().strokeBorder(slot.available ? Theme.button : Theme.hairline, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!slot.available)
        .accessibilityLabel(slot.available ? slot.time : "\(slot.time), fully booked")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Small dietary badge, e.g. leaf + "V".
struct DietBadge: View {
    let tag: DietTag
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: tag.icon)
            Text(tag.short)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(tag == .spicy ? Theme.goldText : Theme.success)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background((tag == .spicy ? Theme.goldSoft : Theme.success.opacity(0.1)), in: Capsule())
        .fixedSize()
        .accessibilityLabel(tag.title)
    }
}

/// "Popular" badge on menu items.
struct PopularBadge: View {
    var body: some View {
        Label("Popular", systemImage: "star.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.goldText)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Theme.goldSoft, in: Capsule())
            .fixedSize()
    }
}

/// One menu item: name, description, ingredients, badges, price and photo.
struct MenuItemRow: View {
    let item: MenuItem
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(item.detail).font(.ltCaption).foregroundStyle(Theme.textBody).lineLimit(2)
                Text(item.ingredients.joined(separator: " · "))
                    .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                if item.popular || !item.tags.isEmpty {
                    FlowRow(spacing: 6) {
                        if item.popular { PopularBadge() }
                        ForEach(item.tags) { DietBadge(tag: $0) }
                    }
                    .padding(.top, 2)
                }
                Text(Money.usd(item.price)).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
            }
            Spacer(minLength: 0)
            FillPhoto(name: item.photo, width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows ingredients and allergens")
    }
}

/// Full details for a dish: photo, description, ingredients, allergens.
struct MenuItemSheet: View {
    let item: MenuItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FillPhoto(name: item.photo, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name).font(.ltTitle)
                            Spacer()
                            Text(Money.usd(item.price)).font(.title3.bold())
                        }
                        HStack(spacing: 6) {
                            if item.popular { PopularBadge() }
                            ForEach(item.tags) { DietBadge(tag: $0) }
                        }
                        Text(item.detail).font(.ltBody).foregroundStyle(Theme.textBody)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingredients").font(.ltHeadline)
                        FlowRow(spacing: 8) {
                            ForEach(item.ingredients, id: \.self) { i in
                                Text(i).font(.subheadline)
                                    .foregroundStyle(Theme.textBody)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Theme.background, in: Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

                    VStack(alignment: .leading, spacing: 10) {
                        Label(item.allergens.isEmpty ? "No major allergens"
                              : "Contains: " + item.allergens.map(\.rawValue).joined(separator: ", "),
                              systemImage: "exclamationmark.triangle")
                        Label("\(item.calories) calories", systemImage: "flame")
                        if !item.tags.isEmpty {
                            Label(item.tags.map(\.title).joined(separator: " · "), systemImage: "leaf")
                        }
                    }
                    .font(.ltBody).foregroundStyle(Theme.textBody)
                    .labelStyle(IconLabelStyle())
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

                    Text("Tell your server about any allergies. Dishes are prepared in a kitchen that handles all major allergens.")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background)
            .navigationTitle("Menu item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.fontWeight(.semibold) }
            }
        }
        .tint(Theme.button)
    }
}

/// Neutral-grey icon + text (a plain Label would pick up the tint).
struct IconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon.foregroundStyle(Theme.icon).frame(width: 22)
            configuration.title
        }
    }
}

/// Tappable row on a search form card (icon, value, optional detail).
struct FormRow: View {
    let icon: String
    let text: String
    var isPlaceholder = false
    let label: String
    var detail: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title3).foregroundStyle(Theme.icon).frame(width: 26)
                Text(text).font(.ltBody)
                    .foregroundStyle(isPlaceholder ? Theme.textSecondary : Theme.textPrimary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let detail { Text(detail).font(.ltCaption).foregroundStyle(Theme.textSecondary) }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(text)
        .accessibilityHint("Double-tap to change")
    }
}

/// Restaurant, date, time, party and seating – top of the checkout screens.
struct DiningSummary: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            FillPhoto(name: app.restaurant.photo, width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(app.restaurant.name).font(.ltHeadline)
                Text("\(app.dining.dateText) · \(app.slot?.time ?? app.dining.timeText)")
                    .font(.ltCaption).foregroundStyle(Theme.textBody)
                Text("\(app.dining.partyText) · \(app.seating.title)")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                RestaurantMeta(restaurant: app.restaurant).font(.ltCaption)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16).card()
        .accessibilityElement(children: .combine)
    }
}

extension AppState {
    /// "Thu, Dec 31 at 7:30 PM" – free cancellation ends 24 hours before the table.
    var diningCancelDeadline: String {
        let cal = Calendar.current
        let minutes = slot?.minutes ?? dining.time
        let day = cal.date(byAdding: .day, value: -1, to: dining.date) ?? dining.date
        return "\(HotelSearch.dayText(day)) at \(DiningSearch.timeText(minutes))"
    }

    /// Keeps the chosen time and seating valid for the restaurant, date and party.
    func syncDiningSelection() {
        if let s = slot,
           !restaurant.slots(on: dining.date, party: dining.party).contains(where: { $0.minutes == s.minutes && $0.available }) {
            slot = nil
        }
        if !restaurant.seatingForSearch.contains(seating) || !seating.fits(dining.party) { seating = .any }
    }
}

// MARK: - Search sheets

/// Single-date picker for the reservation.
struct DiningDateSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Date

    init(date: Binding<Date>) {
        _date = date
        _draft = State(initialValue: date.wrappedValue)
    }

    private var range: ClosedRange<Date> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return today...(cal.date(byAdding: .year, value: 1, to: today) ?? today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DatePicker("Reservation date", selection: $draft, in: range, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Theme.button)
                        .padding(8)
                        .card(radius: 20)
                    Text(HotelSearch.dayText(draft)).font(.ltBody).foregroundStyle(Theme.textBody)
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background)
            .navigationTitle("Select date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        date = Calendar.current.startOfDay(for: draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.button)
    }
}

/// Preferred time: a grid of times. Picking one closes the sheet.
struct DiningTimeSheet: View {
    @Binding var time: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(DiningSearch.times, id: \.self) { t in
                        TimeChip(slot: TimeSlot(minutes: t, available: true, tablesLeft: 0), selected: t == time) {
                            time = t
                            dismiss()
                        }
                    }
                }
                .padding(Theme.screenPadding)
                Text("We'll show tables up to 90 minutes either side.")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .background(Theme.background)
            .navigationTitle("Preferred time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .tint(Theme.button)
        .presentationDetents([.medium])
    }
}

/// Party size, 1–12.
struct PartySizeSheet: View {
    @Binding var party: Int
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Int

    init(party: Binding<Int>) {
        _party = party
        _draft = State(initialValue: party.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CounterRow(title: "Guests", subtitle: "Including children", value: $draft, range: 1...DiningSearch.maxParty)
                } footer: {
                    Text("For more than \(DiningSearch.maxParty) guests, ask Concierge to arrange a private event.")
                }
            }
            .navigationTitle("Party size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        party = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.button)
        .presentationDetents([.medium])
    }
}
