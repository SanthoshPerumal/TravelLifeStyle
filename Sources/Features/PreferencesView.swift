import SwiftUI

/// Day 5 – Preference setup. Everything auto-saves (no Save button).
struct PreferencesView: View {
    @EnvironmentObject var app: AppState

    // Locally-added custom entries (brand / venue "Add" fields).
    @State private var newBrand = ""
    @State private var newVenue = ""

    var body: some View {
        Screen(title: "Preferences") {
            Text("Changes save automatically.").font(.ltCaption).foregroundStyle(Theme.textSecondary)

            group("Hotel brands") { chipFlow(Sample.hotelBrands) }
            addField(placeholder: "Add a brand", text: $newBrand) { add($0) }

            group("Airlines") { chipFlow(Sample.airlines) }

            group("Favorite venues") { chipFlow(Sample.venues) }
            addField(placeholder: "Add a venue", text: $newVenue) { add($0) }

            group("Cuisines") { chipFlow(Sample.cuisines) }

            group("Dietary") { chipFlow(Sample.dietary) }

            group("Price range") {
                Picker("Price", selection: $app.priceLevel) {
                    ForEach(1...4, id: \.self) { Text(String(repeating: "$", count: $0)).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            // Locked traveler record
            group("Traveler details") {
                VStack(spacing: 10) {
                    KeyValueRow(key: "Name", value: "Alex Morgan")
                    KeyValueRow(key: "Home", value: "Houston, TX")
                    KeyValueRow(key: "Date of birth", value: "04/12/1985")
                    KeyValueRow(key: "Known Traveler #", value: "TT1029384")
                    KeyValueRow(key: "Passport", value: "•••• 7781")
                }
            }

            Button("Opt out of travel profile") {}
                .font(.ltBody).foregroundStyle(Theme.button).padding(.top, 4)
        }
    }

    // MARK: Helpers

    /// A titled white card group.
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.ltHeadline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()
    }

    /// Wrapping flow of selectable chips (uses a simple LazyVGrid for wrapping).
    private func chipFlow(_ items: [String]) -> some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.self) { item in
                Chip(title: item, selected: app.selected.contains(item)) { app.toggle(item) }
            }
        }
    }

    private func addField(placeholder: String, text: Binding<String>, onAdd: @escaping (String) -> Void) -> some View {
        HStack {
            TextField(placeholder, text: text)
            Button {
                let v = text.wrappedValue.trimmingCharacters(in: .whitespaces)
                if !v.isEmpty { onAdd(v); text.wrappedValue = "" }
            } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Theme.button).font(.title2) }
        }
        .padding(.horizontal, 18).padding(.vertical, 12).card()
    }

    private func add(_ v: String) { app.selected.insert(v) }
}

// MARK: - FlowLayout

/// A minimal wrapping layout so chips flow to the next line (iOS 16+ Layout API).
/// Improvement: extract to the design system if reused elsewhere.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
