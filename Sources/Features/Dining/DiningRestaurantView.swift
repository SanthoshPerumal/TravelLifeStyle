import SwiftUI

/// Restaurant details: info, date / party / time selection, seating, popular dishes
/// and amenities. Sticky glass bar → Reserve.
struct DiningRestaurantView: View {
    @EnvironmentObject var app: AppState
    @State private var editingDate = false
    @State private var dish: MenuItem?

    private var r: Restaurant { app.restaurant }
    private var slots: [TimeSlot] { r.slots(on: app.dining.date, party: app.dining.party) }

    var body: some View {
        Screen(title: r.name) {
            FillPhoto(name: r.photo, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    RestaurantMeta(restaurant: r)
                    Text("·").foregroundStyle(Theme.textSecondary)
                    RatingView(rating: r.rating, reviews: r.reviews)
                }
                .font(.ltCaption)
                Text(r.about).font(.ltBody).foregroundStyle(Theme.textBody)
                Group {
                    Label(r.hoursText, systemImage: "clock")
                    Label(r.address, systemImage: "mappin.and.ellipse")
                }
                .font(.ltCaption).foregroundStyle(Theme.textBody)
                .labelStyle(IconLabelStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

            SectionTitle(text: "Reservation")
            reservationCard

            SectionTitle(text: "Seating preference")
            ForEach(r.seatingForSearch) { s in
                Button { app.seating = s } label: { seatingRow(s) }
                    .buttonStyle(.plain)
                    .disabled(!s.fits(app.dining.party))
            }

            VStack(alignment: .leading, spacing: 4) {
                SectionTitle(text: "Popular dishes")
                CardCarousel(items: r.popularItems, itemWidth: Self.dishWidth, spacing: 12, itemLabel: "Dish") { item in
                    Button { dish = item } label: { dishCard(item) }
                        .buttonStyle(.plain)
                }
            }
            PillButton(title: "View full menu", kind: .secondary) { app.push(.diningMenu) }

            SectionTitle(text: "Amenities")
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                      alignment: .leading, spacing: 12) {
                ForEach(r.features) { f in
                    Label(f.title, systemImage: f.icon).font(.ltCaption).foregroundStyle(Theme.textPrimary)
                        .labelStyle(IconLabelStyle())
                }
            }
            .padding(Theme.cardPadding).card()

            Label("A \(Money.usd(r.depositPerGuest)) per guest deposit holds your table and comes off your bill. Free cancellation up to 24 hours before.",
                  systemImage: "info.circle")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                .labelStyle(IconLabelStyle())
        }
        .onAppear { app.syncDiningSelection() }
        .onChange(of: app.dining) { app.syncDiningSelection() }
        .sheet(isPresented: $editingDate) { DiningDateSheet(date: $app.dining.date) }
        .sheet(item: $dish) { MenuItemSheet(item: $0) }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                VStack(alignment: .leading) {
                    Text(app.slot.map { "\($0.time) · \(app.dining.partyText)" } ?? "Choose a time").font(.ltHeadline)
                    Text(app.dining.dateText).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                PillButton(title: "Reserve", enabled: app.slot != nil, fullWidth: false) { app.push(.diningGuest) }
            }
        }
    }

    private var reservationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button { editingDate = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar").font(.title3).foregroundStyle(Theme.icon).frame(width: 26)
                    Text(app.dining.dateText).font(.ltBody).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Change").font(.ltCaptionBold).foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Date, \(app.dining.dateText)")

            Divider()
            CounterRow(title: "Guests", value: $app.dining.party, range: 1...min(r.maxParty, DiningSearch.maxParty))
            Divider()

            Text("Available times").font(.ltCaptionBold).foregroundStyle(Theme.textSecondary)
            if slots.contains(where: \.available) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(slots) { s in
                        TimeChip(slot: s, selected: app.slot?.minutes == s.minutes) { app.slot = s }
                    }
                }
                if let s = app.slot, s.tablesLeft <= 2 {
                    Label("Only \(s.tablesLeft) table\(s.tablesLeft == 1 ? "" : "s") left at \(s.time)", systemImage: "clock.badge.exclamationmark")
                        .font(.ltCaptionBold).foregroundStyle(Theme.goldText)
                }
            } else {
                Text(app.dining.party > r.maxParty
                     ? "\(r.name) seats up to \(r.maxParty). Ask Concierge about a private event."
                     : "Fully booked on \(app.dining.dateText). Try another date.")
                    .font(.ltBody).foregroundStyle(Theme.textBody)
            }
        }
        .padding(Theme.cardPadding).card()
    }

    private func seatingRow(_ s: Seating) -> some View {
        let ok = s.fits(app.dining.party)
        let selected = ok && app.seating == s
        return HStack(spacing: 14) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(selected ? Theme.button : Theme.textSecondary).font(.title2)
            Image(systemName: s.icon).foregroundStyle(Theme.icon).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(s.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(ok ? s.detail : "Not available for \(app.dining.partyText)")
                    .font(.ltCaption).foregroundStyle(ok ? Theme.textSecondary : Theme.goldText)
            }
            Spacer()
        }
        .padding(16)
        .card()
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .stroke(selected ? Theme.button : .clear, lineWidth: 1.5))
        .opacity(ok ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private static let dishWidth: CGFloat = 170

    private func dishCard(_ item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FillPhoto(name: item.photo, width: Self.dishWidth, height: 120)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(Money.usd(item.price)).font(.ltCaption).foregroundStyle(Theme.textBody)
            }
            .padding(12)
        }
        .frame(width: Self.dishWidth, alignment: .leading)
        .card(radius: 18)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Full menu: sticky category chips that jump to each section, dietary key,
/// and every dish with photo, ingredients and price. Tap a dish for details.
struct DiningMenuView: View {
    @EnvironmentObject var app: AppState
    @State private var dish: MenuItem?
    @State private var current: String?

    private var r: Restaurant { app.restaurant }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(r.name).font(.ltHeadline)
                        RestaurantMeta(restaurant: r).font(.ltCaption)
                        HStack(spacing: 6) {
                            ForEach(DietTag.allCases) { DietBadge(tag: $0) }
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 4)
                        Text("V vegetarian · VG vegan · GF gluten-free").font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

                    Section {
                        ForEach(r.menu) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section.title).font(.ltTitle).padding(.bottom, 10)
                                VStack(spacing: 0) {
                                    ForEach(Array(section.items.enumerated()), id: \.element.id) { i, item in
                                        if i > 0 { Divider().padding(.vertical, 14) }
                                        Button { dish = item } label: { MenuItemRow(item: item) }
                                            .buttonStyle(.plain)
                                    }
                                }
                                .padding(Theme.cardPadding).card()
                            }
                            .id(section.id)
                        }
                    } header: {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(r.menu) { section in
                                    Chip(title: section.title, selected: current == section.id) {
                                        current = section.id
                                        withAnimation { proxy.scrollTo(section.id, anchor: .top) }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .bleedsIntoPadding()
                        .background(Theme.background)
                    }

                    Text("Prices in USD before tax and gratuity. Menu changes with the season.")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                .readableColumn()
                .padding(.bottom, 32)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { if current == nil { current = r.menu.first?.id } }
        .sheet(item: $dish) { MenuItemSheet(item: $0) }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: app.slot == nil ? "Choose a time" : "Reserve · \(app.slot!.time)") {
                    if app.slot == nil { app.path.removeLast() } else { app.push(.diningGuest) }
                }
            }
        }
    }
}
