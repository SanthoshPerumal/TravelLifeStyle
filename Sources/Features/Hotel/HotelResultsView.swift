import SwiftUI

/// Day 2 – Hotel search & results with filters and sorting.
struct HotelResultsView: View {
    @EnvironmentObject var app: AppState

    enum Sort: String, CaseIterable { case recommended = "Recommended", price = "Price", rating = "Rating" }

    @State private var sort: Sort = .recommended
    @State private var freeCancelOnly = false

    /// Applies the filter + sort to the sample list.
    private var results: [Hotel] {
        var list = Sample.hotels
        if freeCancelOnly { list = list.filter { $0.freeCancel } }
        switch sort {
        case .recommended: break
        case .price:  list.sort { $0.nightly < $1.nightly }
        case .rating: list.sort { $0.rating > $1.rating }
        }
        return list
    }

    var body: some View {
        Screen(title: "Hotels") {
            // Search summary card
            VStack(alignment: .leading, spacing: 6) {
                Text(Sample.city).font(.ltHeadline)
                Text("\(Sample.dates) · \(Sample.guests) guests").font(.ltBody).foregroundStyle(Theme.textBody)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            // Filters – wrapped in a scroll view so every chip stays reachable.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Chip(title: "Free cancellation", selected: freeCancelOnly, tint: Theme.success) { freeCancelOnly.toggle() }
                }
            }

            // Segmented sort control
            Picker("Sort", selection: $sort) {
                ForEach(Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            ForEach(results) { h in
                Button {
                    app.hotel = h
                    app.push(.hotelRooms(h.id))
                } label: { row(h) }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ h: Hotel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SceneArt(kind: h.scene).frame(height: 150)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(h.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    Text("\(h.area) · ★ \(String(format: "%.1f", h.rating)) (\(h.reviews))")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    if h.freeCancel {
                        Text("Free cancellation").font(.ltCaptionBold).foregroundStyle(Theme.success)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(Money.usd(h.nightly)).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    Text("per night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
        }
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}
