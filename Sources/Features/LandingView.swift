import SwiftUI

/// Day 1 – Landing page: balance, "Travel, dining & experiences" grid, hotel offers, plans, tab bar.
struct LandingView: View {
    @EnvironmentObject var app: AppState

    /// One tile in the "Travel, dining & experiences" grid. `route == nil` means "not in this release".
    private struct Service: Identifiable {
        let id: String; let icon: String; let route: Route?
        init(_ id: String, _ icon: String, _ route: Route?) { self.id = id; self.icon = icon; self.route = route }
    }
    private let services = [
        Service("Book flight", "airplane", nil),
        Service("Book hotel", "building.2.fill", .hotelSearch),
        Service("Book car", "car.fill", nil),
        Service("Reserve a table", "fork.knife", .diningRestaurant),
        Service("Book event", "theatermasks.fill", nil),
        Service("Book experience", "ticket.fill", nil)
    ]

    /// Offers carousel position (drives the page indicator and dot taps).
    @State private var offerScroll = ScrollPosition(idType: String.self)
    @State private var offerIndex = 0

    /// Hotels with a current offer, for the "Hotel offers" carousel.
    private var offers: [Hotel] { Sample.hotels.filter { $0.percentOff > 0 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Tinted top section: header, greeting and concierge search.
                VStack(alignment: .leading, spacing: 22) {
                    header
                    titleBlock
                    conciergeSearch
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 24)

                // Content sheet that rises over the tinted top section.
                VStack(alignment: .leading, spacing: 24) {
                    balanceCard
                    bookNow
                    hotelOffers
                    myPlans
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .background(
                    Theme.background,
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                )
            }
        }
        .background {
            // Warm tint behind the top section; the light app background below it
            // so overscrolling at the bottom never shows the tint.
            VStack(spacing: 0) {
                LinearGradient(colors: [Theme.headerTintTop, Theme.headerTintBottom],
                               startPoint: .top, endPoint: .bottom)
                Theme.background
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)          // custom glass header instead
        .safeAreaInset(edge: .bottom) { tabBar }        // floating Liquid Glass tab bar
    }

    // MARK: Header (glass controls)

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image("WellsFargoLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .accessibilityLabel("Wells Fargo")
                Text("Travel LifeStyle")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(alignment: .topTrailing) { CountBadge(count: 3).offset(x: -2, y: 2) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications, 3 unread")
            Button("Sign off") {}
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .buttonStyle(.plain)
                .padding(.leading, 8)
        }
        .padding(.top, 8)
    }

    private var titleBlock: some View {
        Text("\(greeting), Alex")
            .font(.title)
            .foregroundStyle(Theme.textPrimary)
            .padding(.top, 18)
    }

    /// "Good morning / afternoon / evening" based on the current hour.
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: Balance card

    /// Account-style tile for the Autograph Journey card: name and last four,
    /// a small card thumbnail beside the balance, and a rewards points strip.
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 4) {
                Text("Autograph Journey Visa (…4821)")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(alignment: .center) {
                Image("AutographJourneyCard")
                    .resizable()
                    .aspectRatio(432.0 / 276.0, contentMode: .fit)
                    .scaleEffect(1.03) // trims the white matte baked into the artwork's corners
                    .frame(width: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .accessibilityLabel("Autograph Journey card")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Money.usd(app.points / Theme.pointsPerDollar) + ".50")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text("Rewards balance")
                        .font(.ltBody).foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "star")
                    .font(.callout)
                Text("\(app.points.formatted()) rewards points")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14).frame(minHeight: 44)
            .background(Theme.rewardsStrip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 20)
        .accessibilityElement(children: .combine)
    }

    // MARK: Concierge search bar

    private var conciergeSearch: some View {
        HStack(spacing: 12) {
            Button { app.push(.concierge) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                    Text("Need help? Ask Concierge").foregroundStyle(Theme.textBody)
                    Spacer()
                }
                .font(.body)
                .padding(.horizontal, 14).frame(minHeight: 42)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { app.push(.concierge) } label: {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.icon)
                    .frame(width: 36, height: 36)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                    .overlay(alignment: .topTrailing) { CountBadge(count: 1).offset(x: 6, y: -6) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Concierge chat, 1 new message")
        }
    }

    // MARK: Book now grid

    private var bookNow: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Travel, dining & experiences")
            // Line icons over a label, no tile chrome.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 22) {
                ForEach(services) { s in
                    Button { if let r = s.route { app.push(r) } } label: {
                        VStack(spacing: 10) {
                            Image(systemName: s.icon)
                                .font(.title.weight(.light))
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(Theme.icon)
                                .frame(height: 36)
                            Text(s.id)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Hotel offers

    private var hotelOffers: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(text: "Hotel offers")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.offerSpacing) {
                    ForEach(offers) { o in
                        Button { app.push(.hotelRooms(o.id)) } label: {
                            offerCard(o)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 12)   // room for the card shadows
            }
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)   // swipes settle on a card
            .scrollPosition($offerScroll)
            // Which card is current: by offset, and the last one once scrolled to the end.
            .onScrollGeometryChange(for: Int.self) { geo in
                let maxX = geo.contentSize.width - geo.containerSize.width
                if geo.contentOffset.x >= maxX - 4 { return offers.count - 1 }
                let step = Self.offerWidth + Self.offerSpacing
                return min(max(Int((geo.contentOffset.x / step).rounded()), 0), offers.count - 1)
            } action: { _, index in
                offerIndex = index
            }

            PageIndicator(count: offers.count, current: offerIndex) { i in
                withAnimation { offerScroll.scrollTo(id: offers[i].id, anchor: .leading) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private static let offerWidth: CGFloat = 260
    private static let offerSpacing: CGFloat = 16

    private func offerCard(_ o: Hotel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HotelPhoto(hotel: o, width: Self.offerWidth, height: 160)
            VStack(alignment: .leading, spacing: 6) {
                Text(o.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                HStack(spacing: 4) {
                    RatingView(rating: o.rating)
                    Text("· \(o.area)").foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
                .font(.ltCaption)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Money.usd(o.dealNightly))
                        .font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                    Text(Money.usd(o.nightly))
                        .font(.ltCaption).strikethrough().foregroundStyle(Theme.textSecondary)
                    Text("/ night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
        }
        .frame(width: Self.offerWidth, alignment: .leading)
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(o.name), \(o.percentOff) percent off, \(Money.usd(o.dealNightly)) per night, was \(Money.usd(o.nightly))")
    }

    // MARK: Trips

    private var myPlans: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Trips")
            Button { app.push(.itinerary) } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Houston · \(Sample.dates)").font(.ltHeadline)
                    HStack(spacing: 16) {
                        status("Stay", on: app.hotelBooked)
                        status("Dining", on: app.diningBooked)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18).card()
            }
            .buttonStyle(.plain)
        }
    }

    /// Green dot when booked, grey when not.
    private func status(_ name: String, on: Bool) -> some View {
        HStack(spacing: 6) {
            Circle().fill(on ? Theme.success : Theme.hairline).frame(width: 8, height: 8)
            Text(name).font(.ltCaption).foregroundStyle(Theme.textBody)
        }
    }

    // MARK: Floating tab bar

    private var tabBar: some View {
        HStack {
            tabItem("house", "Home", active: true) {}
            tabItem("safari", "Explore", active: false) { app.push(.concierge) }
            tabItem("suitcase", "Bookings", active: false) { app.push(.itinerary) }
            tabItem("person", "Profile", active: false) { app.push(.preferences) }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .glass(in: Capsule())
        .padding(.horizontal, 28).padding(.bottom, 4)
    }

    private func tabItem(_ icon: String, _ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Filled symbol for the selected tab, outline otherwise (iOS tab bar convention).
                Image(systemName: active ? icon + ".fill" : icon).font(.title3)
                Text(label).font(.caption2.weight(.medium))
            }
            .foregroundStyle(active ? Theme.red : Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

/// Small red count bubble used on the bell and concierge chat icons.
private struct CountBadge: View {
    let count: Int
    var body: some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(minWidth: 17, minHeight: 17)
            .background(Theme.red, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
    }
}
