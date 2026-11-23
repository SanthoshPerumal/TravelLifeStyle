import SwiftUI

/// "Reserve a table" search: where, date, time and party size. Each row opens a sheet.
struct DiningSearchView: View {
    @EnvironmentObject var app: AppState

    private enum Field: String, Identifiable { case location, date, time, party; var id: String { rawValue } }
    @State private var editing: Field?

    var body: some View {
        Screen(title: "Reserve a table") {
            VStack(spacing: 0) {
                FormRow(icon: "mappin.circle", text: app.dining.location.name, label: "Location") { editing = .location }
                Divider().padding(.leading, 56)
                FormRow(icon: "calendar", text: app.dining.dateText, label: "Date") { editing = .date }
                Divider().padding(.leading, 56)
                FormRow(icon: "clock", text: app.dining.timeText, label: "Time") { editing = .time }
                Divider().padding(.leading, 56)
                FormRow(icon: "person.2", text: app.dining.partyText, label: "Party size") { editing = .party }
            }
            .card()

            PillButton(title: "Find a table") {
                app.slot = nil
                app.push(.diningResults)
            }

            SectionTitle(text: "Cuisines")
            FlowRow(spacing: 8) {
                ForEach(Cuisine.allCases) { c in
                    Chip(title: c.title, selected: app.diningFilters.cuisines.contains(c)) {
                        if app.diningFilters.cuisines.contains(c) { app.diningFilters.cuisines.remove(c) }
                        else { app.diningFilters.cuisines.insert(c) }
                    }
                }
            }

            SectionTitle(text: "Popular in Houston")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Sample.restaurants) { r in
                        Button {
                            app.restaurant = r
                            app.slot = nil
                            app.push(.diningRestaurant)
                        } label: { featured(r) }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
        .sheet(item: $editing) { field in
            switch field {
            case .location:
                DestinationPicker(selection: Binding(
                    get: { app.dining.location },
                    set: { if let d = $0 { app.dining.location = d } }))
            case .date:
                DiningDateSheet(date: $app.dining.date)
            case .time:
                DiningTimeSheet(time: $app.dining.time)
            case .party:
                PartySizeSheet(party: $app.dining.party)
            }
        }
    }

    private func featured(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FillPhoto(name: r.photo, width: 240, height: 140)
            VStack(alignment: .leading, spacing: 4) {
                Text(r.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                RestaurantMeta(restaurant: r).font(.ltCaption)
                RatingView(rating: r.rating, reviews: r.reviews).font(.ltCaption)
            }
            .padding(14)
        }
        .frame(width: 240, alignment: .leading)
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
