import SwiftUI

/// Restaurants for the dining search, with filters, sorting and bookable times.
struct DiningResultsView: View {
    @EnvironmentObject var app: AppState

    enum Sort: String, CaseIterable { case recommended = "Recommended", rating = "Rating", price = "Price" }

    @State private var sort: Sort = .recommended
    @State private var showFilters = false

    /// Quick filters shown as chips (the rest live in the filters sheet).
    private let quickFeatures: [DiningFeature] = [.outdoorSeating, .waterView, .fullBar, .vegetarianOptions]

    private var restaurantsHere: [Restaurant] { Sample.restaurants(for: app.dining.location) }

    private var results: [Restaurant] {
        var list = restaurantsHere.filter(app.diningFilters.matches)
        switch sort {
        case .recommended:
            // Restaurants with tables near the chosen time first.
            list.sort { !$0.nearbySlots(app.dining).isEmpty && $1.nearbySlots(app.dining).isEmpty }
        case .rating: list.sort { $0.rating > $1.rating }
        case .price:  list.sort { $0.priceLevel < $1.priceLevel }
        }
        return list
    }

    var body: some View {
        Screen(title: "Restaurants") {
            Button(action: editSearch) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.dining.location.name).font(.ltHeadline)
                        Text(app.dining.summary).font(.ltCaption).foregroundStyle(Theme.textBody)
                    }
                    Spacer()
                    Text("Edit").font(.ltCaptionBold).foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Change location, date, time or party size")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filtersButton
                    ForEach(quickFeatures) { f in
                        Chip(title: f.chipTitle, selected: app.diningFilters.features.contains(f)) {
                            if app.diningFilters.features.contains(f) { app.diningFilters.features.remove(f) }
                            else { app.diningFilters.features.insert(f) }
                        }
                    }
                }
            }
            .bleedsIntoPadding()

            Picker("Sort", selection: $sort) {
                ForEach(Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Text(results.count == 1 ? "1 restaurant" : "\(results.count) restaurants")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)

            if results.isEmpty { emptyState }

            // One column on phones, two side by side on wide screens.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                ForEach(results) { r in card(r) }
            }
        }
        .sheet(isPresented: $showFilters) {
            DiningFiltersSheet(filters: $app.diningFilters, restaurants: restaurantsHere)
        }
    }

    private var filtersButton: some View {
        Button { showFilters = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                Text("Filters")
                if app.diningFilters.activeCount > 0 {
                    Text("\(app.diningFilters.activeCount)")
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Theme.textPrimary, in: Circle())
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(Theme.textSecondary.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(app.diningFilters.activeCount > 0 ? "Filters, \(app.diningFilters.activeCount) applied" : "Filters")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife").font(.title).foregroundStyle(Theme.icon)
            Text(restaurantsHere.isEmpty ? "No restaurants here yet" : "No restaurants match your filters").font(.ltHeadline)
            Text(restaurantsHere.isEmpty
                 ? "Try Houston or one of its neighborhoods."
                 : "Try removing a filter or two.")
                .font(.ltBody).foregroundStyle(Theme.textBody).multilineTextAlignment(.center)
            if restaurantsHere.isEmpty {
                PillButton(title: "Change search", kind: .secondary, action: editSearch)
            } else {
                PillButton(title: "Clear filters", kind: .secondary) { app.diningFilters = DiningFilters() }
            }
        }
        .frame(maxWidth: .infinity).padding(24).card()
    }

    private func editSearch() {
        if let i = app.path.lastIndex(of: .diningSearch) {
            app.path.removeSubrange((i + 1)...)
        } else {
            app.push(.diningSearch)
        }
    }

    private func open(_ r: Restaurant, slot: TimeSlot? = nil) {
        app.restaurant = r
        app.slot = slot
        app.syncDiningSelection()
        app.push(.diningRestaurant)
    }

    private func card(_ r: Restaurant) -> some View {
        let slots = r.nearbySlots(app.dining)
        return VStack(alignment: .leading, spacing: 0) {
            Button { open(r) } label: {
                VStack(alignment: .leading, spacing: 0) {
                    FillPhoto(name: r.photo, height: 150)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(r.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                            RestaurantMeta(restaurant: r).font(.ltCaption)
                            HStack(spacing: 10) {
                                ForEach(r.features.prefix(4)) { f in
                                    Image(systemName: f.icon).accessibilityLabel(f.title)
                                }
                            }
                            .font(.footnote).foregroundStyle(Theme.textSecondary)
                            .padding(.top, 2)
                        }
                        Spacer()
                        RatingView(rating: r.rating, reviews: r.reviews).font(.ltCaption)
                    }
                    .padding([.horizontal, .top], 16)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Group {
                if slots.isEmpty {
                    Text("No tables within 90 min of \(app.dining.timeText)")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(slots) { s in
                                TimeChip(slot: s, compact: true) { open(r, slot: s) }
                            }
                        }
                    }
                    .bleedsIntoPadding()
                }
            }
            .padding(16)
        }
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

/// All restaurant filters. Edits a draft and applies it with "Show N restaurants".
struct DiningFiltersSheet: View {
    @Binding var filters: DiningFilters
    let restaurants: [Restaurant]

    @Environment(\.dismiss) private var dismiss
    @State private var draft: DiningFilters

    init(filters: Binding<DiningFilters>, restaurants: [Restaurant]) {
        _filters = filters
        self.restaurants = restaurants
        _draft = State(initialValue: filters.wrappedValue)
    }

    private var count: Int { restaurants.filter(draft.matches).count }

    var body: some View {
        NavigationStack {
            List {
                Section("Cuisine") {
                    ForEach(Cuisine.allCases) { c in
                        Toggle(c.title, isOn: binding(c, in: \.cuisines)).font(.ltBody)
                    }
                }
                Section("Features") {
                    ForEach(DiningFeature.allCases) { f in
                        Toggle(isOn: binding(f, in: \.features)) {
                            HStack(spacing: 12) {
                                Image(systemName: f.icon).foregroundStyle(Theme.icon).frame(width: 26)
                                Text(f.title).foregroundStyle(Theme.textPrimary)
                            }
                            .font(.ltBody)
                        }
                    }
                }
                Section("Price") {
                    Picker("Price", selection: $draft.maxPrice) {
                        Text("Any").tag(Int?.none)
                        ForEach(DiningFilters.priceSteps, id: \.self) {
                            Text("≤ " + String(repeating: "$", count: $0)).tag(Int?.some($0))
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section("Guest rating") {
                    Picker("Guest rating", selection: $draft.minRating) {
                        Text("Any").tag(Double?.none)
                        ForEach(DiningFilters.ratingSteps, id: \.self) { Text(String(format: "%.1f+", $0)).tag(Double?.some($0)) }
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
                    Button("Reset") { draft = DiningFilters() }.disabled(draft.activeCount == 0)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PillButton(title: count == 0 ? "No restaurants match" : "Show \(count) restaurant\(count == 1 ? "" : "s")",
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

    private func binding<T: Hashable>(_ value: T, in keyPath: WritableKeyPath<DiningFilters, Set<T>>) -> Binding<Bool> {
        Binding {
            draft[keyPath: keyPath].contains(value)
        } set: { on in
            if on { draft[keyPath: keyPath].insert(value) } else { draft[keyPath: keyPath].remove(value) }
        }
    }
}
