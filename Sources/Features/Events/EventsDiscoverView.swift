import SwiftUI

/// Book event: search, categories, recommendations and the event list with filters.
struct EventsDiscoverView: View {
    @EnvironmentObject var app: AppState
    @State private var query = ""
    @State private var showFilters = false

    private var filters: EventFilters { app.eventFilters }

    private var upcoming: [Event] { Sample.events.filter { !$0.isPast } }

    private var results: [Event] {
        let q = query.trimmingCharacters(in: .whitespaces)
        var list = upcoming.filter { e in
            if let c = filters.category, e.category != c { return false }
            if !q.isEmpty && !(e.title.localizedCaseInsensitiveContains(q) || e.subtitle.localizedCaseInsensitiveContains(q)
                                || e.venue.localizedCaseInsensitiveContains(q)) { return false }
            if filters.onSaleOnly && !e.isOnSale { return false }
            if filters.favoritesOnly && !app.favoriteEvents.contains(e.id) { return false }
            if let max = filters.maxPrice, e.priceFrom > max { return false }
            let days = Calendar.current.dateComponents([.day], from: .now, to: e.date).day ?? 0
            switch filters.when {
            case .any: break
            case .week: if days > 7 { return false }
            case .month: if days > 31 { return false }
            case .quarter: if days > 92 { return false }
            }
            return true
        }
        switch filters.sort {
        case .date:    list.sort { $0.date < $1.date }
        case .price:   list.sort { $0.priceFrom < $1.priceFrom }
        case .popular: list.sort { $0.popularity > $1.popularity }
        }
        return list
    }

    /// Picked from preferences (cuisines/venues don't apply; favor popular + favorites).
    private var recommended: [Event] {
        upcoming.sorted { a, b in
            let fa = app.favoriteEvents.contains(a.id) ? 1000 : 0, fb = app.favoriteEvents.contains(b.id) ? 1000 : 0
            return a.popularity + fa > b.popularity + fb
        }.prefix(5).map { $0 }
    }

    /// Events during the Houston trip (Jan 1 – 3, 2027).
    private var duringTrip: [Event] {
        upcoming.filter { $0.date >= HotelSearch.initial.checkIn && $0.date <= Sample.day(2027, 1, 3, 23, 59) }
    }

    private var isSearching: Bool { !query.isEmpty || filters.category != nil || filters.activeCount > 0 }

    var body: some View {
        Screen(title: "Events") {
            searchField
            shortcuts
            categoryChips

            if !isSearching {
                VStack(alignment: .leading, spacing: 4) {
                    SectionTitle(text: "Recommended for you")
                    CardCarousel(items: recommended, itemWidth: Self.wideWidth, itemLabel: "Event") { e in
                        Button { app.push(.eventDetail(e.id)) } label: {
                            EventCard(event: e, photoHeight: 190).frame(width: Self.wideWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !duringTrip.isEmpty {
                    SectionTitle(text: "During your Houston trip")
                    ForEach(duringTrip) { e in eventLink(e) }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                SectionTitle(text: isSearching ? "\(results.count) event\(results.count == 1 ? "" : "s")" : "All events")
                Spacer()
                Menu {
                    Picker("Sort", selection: $app.eventFilters.sort) {
                        ForEach(EventFilters.Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label("Sort: \(filters.sort.rawValue)", systemImage: "arrow.up.arrow.down")
                        .font(.ltCaptionBold).foregroundStyle(Theme.textPrimary)
                }
            }

            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket").font(.title).foregroundStyle(Theme.icon)
                    Text("No events match").font(.ltHeadline)
                    Text("Try another search or clear the filters.").font(.ltBody).foregroundStyle(Theme.textBody)
                    PillButton(title: "Clear filters", kind: .secondary) {
                        query = ""; app.eventFilters = EventFilters()
                    }
                }
                .frame(maxWidth: .infinity).padding(24).card()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                ForEach(results) { e in eventLink(e) }
            }
        }
        .sheet(isPresented: $showFilters) { EventFiltersSheet(filters: $app.eventFilters) }
    }

    private static let wideWidth: CGFloat = 300

    private func eventLink(_ e: Event) -> some View {
        Button { app.push(.eventDetail(e.id)) } label: { EventCard(event: e) }
            .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
            TextField("Artists, teams or venues", text: $query)
                .font(.ltBody)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textSecondary) }
                    .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14).frame(minHeight: 48)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
    }

    /// My Tickets · Favorites · Alerts
    private var shortcuts: some View {
        let ticketCount = app.tickets.filter { ($0.event.map { !$0.isPast } ?? false) && $0.status == .active }.count
        return HStack(spacing: 10) {
            shortcut("ticket", "My Tickets", "\(ticketCount)") { app.push(.myTickets) }
            shortcut("heart", "Favorites", "\(app.favoriteEvents.count)") {
                app.eventFilters.favoritesOnly.toggle()
            }
            shortcut("bell", "Alerts", "\(app.eventAlerts.count)") { showFilters = true }
        }
    }

    private func shortcut(_ icon: String, _ title: String, _ count: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.title3).foregroundStyle(Theme.icon)
                Text(title).font(.ltCaptionBold).foregroundStyle(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.8)
                Text(count).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).card()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count)")
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { showFilters = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filters")
                        if filters.activeCount > 0 {
                            Text("\(filters.activeCount)").font(.caption2.bold()).foregroundStyle(.white)
                                .frame(minWidth: 18, minHeight: 18).background(Theme.textPrimary, in: Circle())
                        }
                    }
                    .font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(Theme.textSecondary.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Chip(title: "All", selected: filters.category == nil) { app.eventFilters.category = nil }
                ForEach(EventCategory.allCases) { c in
                    Chip(title: c.title, selected: filters.category == c) {
                        app.eventFilters.category = filters.category == c ? nil : c
                    }
                }
            }
        }
        .bleedsIntoPadding()
    }
}

/// Filters sheet for events.
struct EventFiltersSheet: View {
    @Binding var filters: EventFilters
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EventFilters

    init(filters: Binding<EventFilters>) {
        _filters = filters
        _draft = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Date") {
                    Picker("Date", selection: $draft.when) {
                        ForEach(EventFilters.When.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.inline).labelsHidden()
                }
                Section("Price per ticket") {
                    Picker("Price", selection: $draft.maxPrice) {
                        Text("Any").tag(Int?.none)
                        ForEach(EventFilters.priceSteps, id: \.self) { Text("≤ $\($0)").tag(Int?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
                Section {
                    Toggle("On sale now", isOn: $draft.onSaleOnly)
                    Toggle("Favorites only", isOn: $draft.favoritesOnly)
                }
                if !app.eventAlerts.isEmpty {
                    Section("Your alerts") {
                        ForEach(Sample.events.filter { app.eventAlerts.contains($0.id) }) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.title).font(.ltBody)
                                    Text(e.isOnSale ? "Price drops" : "On-sale reminder").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Button("Remove") { app.toggleAlert(e) }.font(.ltCaptionBold)
                            }
                        }
                    }
                }
            }
            .tint(Theme.button)
            .navigationTitle("Filters & alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") { draft = EventFilters() }.disabled(draft.activeCount == 0)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PillButton(title: "Show events") {
                    filters = draft
                    dismiss()
                }
                .padding(.horizontal, Theme.screenPadding).padding(.vertical, 10)
                .background(.bar)
            }
        }
        .tint(Theme.button)
    }
}
