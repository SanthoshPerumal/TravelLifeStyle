import SwiftUI

/// Hotel search: destination, dates, and travelers & rooms. Each row opens a sheet.
struct HotelSearchView: View {
    @EnvironmentObject var app: AppState

    private enum Field: String, Identifiable { case destination, dates, travelers; var id: String { rawValue } }
    @State private var editing: Field?

    var body: some View {
        Screen(title: "Find a hotel") {
            VStack(spacing: 0) {
                row(icon: "mappin.circle",
                    text: app.search.destination?.name ?? "City, neighborhood, or point of interest",
                    isPlaceholder: app.search.destination == nil,
                    label: "Destination") { editing = .destination }
                Divider().padding(.leading, 56)
                row(icon: "calendar", text: app.search.datesText, label: "Dates",
                    detail: app.search.nightsText) { editing = .dates }
                Divider().padding(.leading, 56)
                row(icon: "person", text: app.search.travelersText, label: "Travelers and rooms") { editing = .travelers }
            }
            .card()

            PillButton(title: "Search hotels", enabled: app.search.destination != nil) {
                app.push(.hotelResults)
            }

            SectionTitle(text: "Popular in Houston")
            FlowRow(spacing: 8) {
                ForEach(Sample.destinations.prefix(6)) { d in
                    Chip(title: d.name, selected: app.search.destination == d) {
                        app.search.destination = d
                    }
                }
            }
        }
        .sheet(item: $editing) { field in
            switch field {
            case .destination:
                DestinationPicker(selection: $app.search.destination)
            case .dates:
                DateRangeSheet(checkIn: $app.search.checkIn, checkOut: $app.search.checkOut)
            case .travelers:
                TravelersSheet(rooms: $app.search.rooms)
            }
        }
    }

    private func row(icon: String, text: String, isPlaceholder: Bool = false, label: String,
                     detail: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.icon)
                    .frame(width: 26)
                Text(text)
                    .font(.ltBody)
                    .foregroundStyle(isPlaceholder ? Theme.textSecondary : Theme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let detail {
                    Text(detail).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isPlaceholder ? "Not set" : text)
        .accessibilityHint("Double-tap to change")
    }
}

// MARK: - Destination

/// Searchable list of destinations, with a free-text fallback.
struct DestinationPicker: View {
    @Binding var selection: Destination?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }

    private var matches: [Destination] {
        guard !trimmed.isEmpty else { return Sample.destinations }
        return Sample.destinations.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) || $0.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(trimmed.isEmpty ? "Popular destinations" : "Suggestions") {
                    ForEach(matches) { d in
                        Button { choose(d) } label: { destinationRow(d) }
                    }
                    if !trimmed.isEmpty && !matches.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        Button { choose(.custom(trimmed)) } label: {
                            destinationRow(.custom(trimmed), title: "Search for “\(trimmed)”")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "City, neighborhood, or point of interest")
            .searchFocused($searchFocused)
            .onAppear { searchFocused = true }     // ready to type as soon as it opens
            .onSubmit(of: .search) {
                if let first = matches.first { choose(first) } else if !trimmed.isEmpty { choose(.custom(trimmed)) }
            }
            .navigationTitle("Where to?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .tint(Theme.button)
    }

    private func destinationRow(_ d: Destination, title: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: d.icon)
                .font(.body)
                .foregroundStyle(Theme.icon)
                .frame(width: 34, height: 34)
                .background(Theme.background, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title ?? d.name).font(.ltBody).foregroundStyle(Theme.textPrimary)
                Text(d.detail).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if selection == d {
                Image(systemName: "checkmark").foregroundStyle(Theme.button)
            }
        }
        .contentShape(Rectangle())
    }

    private func choose(_ d: Destination) {
        selection = d
        dismiss()
    }
}

// MARK: - Dates

/// Check-in / check-out picker. Picking check-in moves on to check-out, and
/// check-out is always at least one night later (at most 30 nights).
struct DateRangeSheet: View {
    @Binding var checkIn: Date
    @Binding var checkOut: Date
    @Environment(\.dismiss) private var dismiss

    private enum Edge { case checkIn, checkOut }
    @State private var editing: Edge = .checkIn
    @State private var draftIn: Date
    @State private var draftOut: Date

    private let cal = Calendar.current

    init(checkIn: Binding<Date>, checkOut: Binding<Date>) {
        _checkIn = checkIn
        _checkOut = checkOut
        _draftIn = State(initialValue: checkIn.wrappedValue)
        _draftOut = State(initialValue: checkOut.wrappedValue)
    }

    private var nights: Int {
        max(cal.dateComponents([.day], from: cal.startOfDay(for: draftIn), to: cal.startOfDay(for: draftOut)).day ?? 1, 1)
    }

    private var range: ClosedRange<Date> {
        let today = cal.startOfDay(for: .now)
        switch editing {
        case .checkIn:
            return today...(cal.date(byAdding: .year, value: 1, to: today) ?? today)
        case .checkOut:
            let first = cal.date(byAdding: .day, value: 1, to: draftIn) ?? draftIn
            return first...(cal.date(byAdding: .day, value: HotelSearch.maxNights, to: draftIn) ?? first)
        }
    }

    private var selection: Binding<Date> {
        Binding {
            editing == .checkIn ? draftIn : draftOut
        } set: { new in
            let day = cal.startOfDay(for: new)
            if editing == .checkIn {
                draftIn = day
                let minOut = cal.date(byAdding: .day, value: 1, to: day) ?? day
                let maxOut = cal.date(byAdding: .day, value: HotelSearch.maxNights, to: day) ?? minOut
                if draftOut < minOut || draftOut > maxOut { draftOut = minOut }
                editing = .checkOut
            } else {
                draftOut = day
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        dateBox("Check-in", draftIn, active: editing == .checkIn) { editing = .checkIn }
                        dateBox("Check-out", draftOut, active: editing == .checkOut) { editing = .checkOut }
                    }

                    DatePicker("Select \(editing == .checkIn ? "check-in" : "check-out") date",
                               selection: selection, in: range, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Theme.button)
                        .padding(8)
                        .card(radius: 20)

                    Text("\(nights) night\(nights == 1 ? "" : "s") · \(HotelSearch.dayText(draftIn)) – \(HotelSearch.dayText(draftOut))")
                        .font(.ltBody).foregroundStyle(Theme.textBody)
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.background)
            .navigationTitle("Select dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        checkIn = draftIn
                        checkOut = draftOut
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.button)
    }

    private func dateBox(_ title: String, _ date: Date, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text(HotelSearch.dayText(date)).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(active ? Theme.button : Theme.hairline, lineWidth: active ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(HotelSearch.dayText(date))")
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

// MARK: - Travelers & rooms

/// Per-room adults and children (with ages). Up to 5 rooms.
struct TravelersSheet: View {
    @Binding var rooms: [RoomOccupancy]
    @Environment(\.dismiss) private var dismiss
    @State private var draft: [RoomOccupancy]

    init(rooms: Binding<[RoomOccupancy]>) {
        _rooms = rooms
        _draft = State(initialValue: rooms.wrappedValue)
    }

    private var travelers: Int { draft.reduce(0) { $0 + $1.guests } }

    var body: some View {
        NavigationStack {
            List {
                ForEach($draft) { $room in
                    let index = draft.firstIndex(where: { $0.id == room.id }) ?? 0
                    Section {
                        CounterRow(title: "Adults", subtitle: "Ages 18 or above", value: $room.adults, range: 1...6)
                        CounterRow(title: "Children", subtitle: "Ages 0 to 17",
                                   value: childCount($room), range: 0...4)
                        ForEach(room.childAges.indices, id: \.self) { i in
                            Picker("Child \(i + 1) age", selection: $room.childAges[i]) {
                                Text("Under 1").tag(0)
                                ForEach(1...17, id: \.self) { Text("\($0)").tag($0) }
                            }
                            .font(.ltBody)
                        }
                    } header: {
                        HStack {
                            Text("Room \(index + 1)")
                            Spacer()
                            if draft.count > 1 {
                                Button("Remove", role: .destructive) {
                                    withAnimation { draft.removeAll { $0.id == room.id } }
                                }
                                .font(.ltCaptionBold)
                                .textCase(nil)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        withAnimation { draft.append(RoomOccupancy(adults: 1)) }
                    } label: {
                        Label("Add another room", systemImage: "plus")
                    }
                    .disabled(draft.count >= HotelSearch.maxRooms)
                } footer: {
                    Text("Up to \(HotelSearch.maxRooms) rooms. Children's ages help us find rooms that fit.")
                }
            }
            .navigationTitle("Travelers & rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        rooms = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("\(travelers) traveler\(travelers == 1 ? "" : "s"), \(draft.count) room\(draft.count == 1 ? "" : "s")")
                    .font(.ltHeadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.bar)
            }
        }
        .tint(Theme.button)
    }

    /// Children count backed by the ages array (new children default to age 5).
    private func childCount(_ room: Binding<RoomOccupancy>) -> Binding<Int> {
        Binding {
            room.wrappedValue.childAges.count
        } set: { n in
            var ages = room.wrappedValue.childAges
            while ages.count < n { ages.append(5) }
            if ages.count > n { ages.removeLast(ages.count - n) }
            room.wrappedValue.childAges = ages
        }
    }
}

/// "Adults  ⊖ 2 ⊕" row. VoiceOver treats it as one adjustable control.
struct CounterRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ltBody).foregroundStyle(Theme.textPrimary)
                if let subtitle { Text(subtitle).font(.ltCaption).foregroundStyle(Theme.textSecondary) }
            }
            Spacer()
            stepButton("minus", enabled: value > range.lowerBound) { value -= 1 }
            Text("\(value)").font(.ltHeadline).monospacedDigit().frame(minWidth: 28)
            stepButton("plus", enabled: value < range.upperBound) { value += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if value < range.upperBound { value += 1 }
            case .decrement: if value > range.lowerBound { value -= 1 }
            @unknown default: break
            }
        }
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(enabled ? Theme.textPrimary : Theme.hairline)
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(enabled ? Theme.textSecondary.opacity(0.5) : Theme.hairline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.borderless)      // keeps taps on the button inside a List row
        .disabled(!enabled)
    }
}

/// Wrapping row of chips.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += s.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: min(maxX, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + s.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
