import SwiftUI

/// Hotel results for the current search, with filters and sorting.
struct HotelResultsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum Sort: String, CaseIterable { case recommended = "Recommended", price = "Price", rating = "Rating" }

    @State private var sort: Sort = .recommended
    @State private var showFilters = false
    /// Hotel shown in the secondary column on wide layouts (iPhone Duo open, iPad).
    @State private var selectedID: String?

    private var isSplit: Bool { sizeClass == .regular }
    /// The selection, falling back to the first result when it was filtered out.
    private var detailID: String {
        if let id = selectedID, results.contains(where: { $0.id == id }) { return id }
        return results.first?.id ?? Sample.hotels[0].id
    }

    /// Quick filters shown as chips (the rest live in the filters sheet).
    private let quickAmenities: [Amenity] = [.breakfast, .freeParking, .petFriendly, .pool]

    /// Hotels at the destination, before filters.
    private var hotelsHere: [Hotel] { Sample.hotels(for: app.search.destination) }

    /// Applies the filters + sort to the hotels at the destination.
    private var results: [Hotel] {
        var list = hotelsHere.filter(app.filters.matches)
        switch sort {
        case .recommended: break
        case .price:  list.sort { $0.dealNightly < $1.dealNightly }
        case .rating: list.sort { $0.rating > $1.rating }
        }
        return list
    }

    var body: some View {
        AdaptiveSplit {
            list
        } secondary: {
            // Hotel details & rooms for the selected hotel.
            HotelRoomsView(hotelID: detailID).id(detailID)
        }
    }

    private var list: some View {
        Screen(title: "Hotels") {
            // Search summary – tap to change the search
            Button(action: editSearch) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.search.destination?.name ?? "All Houston hotels").font(.ltHeadline)
                        Text("\(app.search.datesText) · \(app.search.travelersText)")
                            .font(.ltCaption).foregroundStyle(Theme.textBody)
                    }
                    Spacer()
                    Text("Edit").font(.ltCaptionBold).foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Change destination, dates or travelers")

            // Filters – wrapped in a scroll view so every chip stays reachable.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filtersButton
                    Chip(title: "Free cancellation", selected: app.filters.freeCancellation) {
                        app.filters.freeCancellation.toggle()
                    }
                    ForEach(quickAmenities) { a in
                        Chip(title: a.chipTitle, selected: app.filters.amenities.contains(a)) {
                            if app.filters.amenities.contains(a) { app.filters.amenities.remove(a) }
                            else { app.filters.amenities.insert(a) }
                        }
                    }
                }
            }
            .bleedsIntoPadding()

            // Segmented sort control
            Picker("Sort", selection: $sort) {
                ForEach(Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Text(results.count == 1 ? "1 hotel" : "\(results.count) hotels")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)

            if results.isEmpty {
                emptyState
            }

            // One column on phones, two side by side on wide screens.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                ForEach(results) { h in
                    Button {
                        app.hotel = h
                        if isSplit { selectedID = h.id } else { app.push(.hotelRooms(h.id)) }
                    } label: { row(h).splitSelection(isSplit && h.id == detailID) }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            HotelFiltersSheet(filters: $app.filters, hotels: hotelsHere)
        }
    }

    private var filtersButton: some View {
        Button { showFilters = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                Text("Filters")
                if app.filters.activeCount > 0 {
                    Text("\(app.filters.activeCount)")
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
        .accessibilityLabel(app.filters.activeCount > 0 ? "Filters, \(app.filters.activeCount) applied" : "Filters")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.title).foregroundStyle(Theme.icon)
            Text(hotelsHere.isEmpty ? "No hotels here yet" : "No hotels match your filters").font(.ltHeadline)
            Text(hotelsHere.isEmpty
                 ? "We don't have hotels for \(app.search.destination?.name ?? "this search") yet. Try a Houston neighborhood or landmark."
                 : "Try removing a filter or two.")
                .font(.ltBody).foregroundStyle(Theme.textBody).multilineTextAlignment(.center)
            if hotelsHere.isEmpty {
                PillButton(title: "Change search", kind: .secondary, action: editSearch)
            } else {
                PillButton(title: "Clear filters", kind: .secondary) { app.filters = HotelFilters() }
            }
        }
        .frame(maxWidth: .infinity).padding(24).card()
    }

    /// Back to the search form (pops to it if it's on the stack).
    private func editSearch() {
        if let i = app.path.lastIndex(of: .hotelSearch) {
            app.path.removeSubrange((i + 1)...)
        } else {
            app.push(.hotelSearch)
        }
    }

    private func row(_ h: Hotel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HotelPhoto(hotel: h, height: 150)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(h.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 4) {
                        Text("\(h.area) ·").foregroundStyle(Theme.textSecondary)
                        RatingView(rating: h.rating, reviews: h.reviews)
                    }
                    .font(.ltCaption)
                    if h.freeCancel {
                        Text("Free cancellation").font(.ltCaptionBold).foregroundStyle(Theme.success)
                    }
                    HStack(spacing: 10) {
                        ForEach(h.amenityList.prefix(5)) { a in
                            Image(systemName: a.icon).accessibilityLabel(a.title)
                        }
                    }
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
                    .padding(.top, 2)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(Money.usd(h.dealNightly)).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    if h.percentOff > 0 {
                        Text(Money.usd(h.nightly)).font(.ltCaption).strikethrough().foregroundStyle(Theme.textSecondary)
                    }
                    Text("per night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
        }
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}
