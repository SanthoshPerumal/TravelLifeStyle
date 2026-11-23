import SwiftUI

/// All hotel filters. Edits a draft and applies it with "Show N hotels".
struct HotelFiltersSheet: View {
    @Binding var filters: HotelFilters
    /// Hotels before filtering, used for the live result count.
    let hotels: [Hotel]

    @Environment(\.dismiss) private var dismiss
    @State private var draft: HotelFilters

    init(filters: Binding<HotelFilters>, hotels: [Hotel]) {
        _filters = filters
        self.hotels = hotels
        _draft = State(initialValue: filters.wrappedValue)
    }

    private var count: Int { hotels.filter(draft.matches).count }

    var body: some View {
        NavigationStack {
            List {
                Section("Booking") {
                    Toggle(isOn: $draft.freeCancellation) {
                        row("Free cancellation", icon: "calendar.badge.checkmark")
                    }
                }

                Section("Amenities") {
                    ForEach(Amenity.allCases) { a in
                        Toggle(isOn: amenityBinding(a)) {
                            row(a.title, icon: a.icon)
                        }
                    }
                }

                Section("Price per night") {
                    Picker("Price per night", selection: $draft.maxNightly) {
                        Text("Any").tag(Int?.none)
                        ForEach(HotelFilters.priceSteps, id: \.self) { Text("≤ $\($0)").tag(Int?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Guest rating") {
                    Picker("Guest rating", selection: $draft.minRating) {
                        Text("Any").tag(Double?.none)
                        ForEach(HotelFilters.ratingSteps, id: \.self) { Text(String(format: "%.1f+", $0)).tag(Double?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .tint(Theme.button)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") { draft = HotelFilters() }.disabled(draft.activeCount == 0)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PillButton(title: count == 0 ? "No hotels match" : "Show \(count) hotel\(count == 1 ? "" : "s")",
                           enabled: count > 0) {
                    filters = draft
                    dismiss()
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
        .tint(Theme.button)
    }

    /// Neutral icon + title (a Label would pick up the red list tint).
    private func row(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Theme.icon)
                .frame(width: 26)
            Text(title).foregroundStyle(Theme.textPrimary)
        }
        .font(.ltBody)
    }

    private func amenityBinding(_ a: Amenity) -> Binding<Bool> {
        Binding {
            draft.amenities.contains(a)
        } set: { on in
            if on { draft.amenities.insert(a) } else { draft.amenities.remove(a) }
        }
    }
}
