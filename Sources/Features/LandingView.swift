import SwiftUI

/// Day 1 – Landing page: balance, "Travel, dining & experiences" grid, hotel offers, plans, tab bar.
struct LandingView: View {
    @EnvironmentObject var app: AppState

    /// One tile in the "Travel, dining & experiences" grid. `route == nil` means "not in this release".
    private struct Service: Identifiable {
        let id: String; let title: String; let icon: String; let tint: Color; let route: Route?
        init(_ id: String, _ title: String, _ icon: String, _ tint: UInt32, _ route: Route?) {
            self.id = id; self.title = title; self.icon = icon; self.tint = Color(hex: tint); self.route = route
        }
    }
    /// Each service has its own muted accent, shown on a soft tinted tile.
    private let services = [
        Service("Book flight", "Flights", "airplane", 0x2F6FDE, nil),
        Service("Book hotel", "Hotels", "bed.double.fill", 0x5856D6, .hotelSearch),
        Service("Book car", "Cars", "car.fill", 0x0F8A80, nil),
        Service("Reserve a table", "Dining", "fork.knife", 0xD9731A, .diningSearch),
        Service("Book event", "Events", "theatermasks.fill", 0x8E4FD8, .events),
        Service("Book experience", "Experiences", "binoculars.fill", 0x2E9457, nil)
    ]

    /// Offers carousel position (drives the page indicator and dot taps).
    @State private var offerScroll = ScrollPosition(idType: String.self)
    @State private var offerIndex = 0

    /// Hotels with a current offer, for the "Hotel offers" carousel.
    private var offers: [Hotel] { Sample.hotels.filter { $0.percentOff > 0 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Tinted top section: header, greeting and "Ask Fargo" search.
                VStack(alignment: .leading, spacing: 22) {
                    header
                    titleBlock
                    fargoSearch
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
                .background {
                    // Fills to the screen edges, so on the iPhone Duo's outer screen
                    // the sheet also runs behind the camera / status column.
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                        .fill(Theme.background)
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                }
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
            .font(.ltLargeTitle)
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(1).minimumScaleFactor(0.7)
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
    /// Dark "premium card" panel in the Autograph card's own colours: near-black
    /// with a burgundy glow and gold accents, white balance for high contrast.
    private var balanceCard: some View {
        let gold = Color(hex: 0xD9B77E)
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AUTOGRAPH JOURNEY")
                        .font(.caption.weight(.semibold)).tracking(1.2)
                        .foregroundStyle(gold)
                    Text("Visa Signature ••4821")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 12)
                Image("AutographJourneyCard")
                    .resizable()
                    .aspectRatio(432.0 / 276.0, contentMode: .fit)
                    .scaleEffect(1.03) // trims the white matte baked into the artwork's corners
                    .frame(width: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Money.usd(app.points / Theme.pointsPerDollar) + ".50")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("Rewards balance")
                    .font(.ltCaption).foregroundStyle(.white.opacity(0.65))
            }

            HStack(spacing: 8) {
                Image(systemName: "star.fill").font(.footnote).foregroundStyle(gold)
                Text("\(app.points.formatted()) points")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Spacer(minLength: 8)
                Text("\(Theme.pointsPerDollar) pts = $1")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14).frame(minHeight: 44)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 0.5))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
            ZStack {
                LinearGradient(colors: [Color(hex: 0x2B1D20), Color(hex: 0x141113)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color(hex: 0x8C2232).opacity(0.55), .clear],
                               center: .topTrailing, startRadius: 0, endRadius: 260)
            }
            .clipShape(shape)
            .overlay(shape.stroke(gold.opacity(0.25), lineWidth: 0.75))
            .shadow(color: Color(hex: 0x2B1D20).opacity(0.25), radius: 16, y: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Autograph Journey Visa ending 4821. Rewards balance \(Money.usd(app.points / Theme.pointsPerDollar)).50, \(app.points.formatted()) points")
    }

    // MARK: Fargo search bar

    private var fargoSearch: some View {
        HStack(spacing: 12) {
            Button { app.push(.fargo) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                    Text("Need help? Ask Fargo").foregroundStyle(Theme.textBody)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer()
                }
                .font(.body)
                .padding(.horizontal, 14).frame(minHeight: 42)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { app.push(.fargo) } label: {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.icon)
                    .frame(width: 36, height: 36)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                    .overlay(alignment: .topTrailing) { CountBadge(count: 1).offset(x: 6, y: -6) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fargo chat, 1 new message")
        }
    }

    // MARK: Book now grid

    private var bookNow: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Travel, dining & experiences")
            // White cards with a soft tinted icon tile; "Soon" on services not open yet.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(services) { s in
                    Button { if let r = s.route { app.push(r) } } label: { serviceTile(s) }
                        .buttonStyle(ServiceTileStyle())
                        .accessibilityLabel(s.route == nil ? "\(s.id), coming soon" : s.id)
                }
            }
        }
    }

    private func serviceTile(_ s: Service) -> some View {
        VStack(spacing: 10) {
            Image(systemName: s.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(s.tint)
                .frame(width: 48, height: 48)
                .background(s.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                // "Soon" badge pinned to the icon tile, so it never covers it on narrow columns.
                .overlay(alignment: .topTrailing) {
                    if s.route == nil {
                        Text("Soon")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.card, in: Capsule())
                            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                            .fixedSize()
                            .offset(x: 18, y: -8)
                    }
                }
            Text(s.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 6)
        .card()
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
            .bleedsIntoPadding()
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
                        .font(.title3).foregroundStyle(Theme.textPrimary)
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
                // Live trip: same layout as `TripCard`, with booking status dots.
                HStack(spacing: 14) {
                    FillPhoto(name: "HotelCaribbean", width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Sample.city).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                        Text(Sample.dates).font(.ltCaption).foregroundStyle(Theme.textBody)
                        HStack(spacing: 16) {
                            status("Stay", on: app.hotelBooked)
                            status("Dining", on: app.diningBooked)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding).card()
            }
            .buttonStyle(.plain)

            // Later trips, then a link to completed ones.
            ForEach(Sample.upcomingTrips) { t in
                Button { app.push(.trip(t.id)) } label: { TripCard(trip: t) }
                    .buttonStyle(.plain)
            }
            if !Sample.pastTrips.isEmpty {
                Button { app.push(.pastTrips) } label: {
                    HStack {
                        Label("Past trips", systemImage: "clock.arrow.circlepath").labelStyle(IconLabelStyle())
                        Spacer()
                        Text("\(Sample.pastTrips.count)").foregroundStyle(Theme.textSecondary)
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                    }
                    .font(.ltBody).foregroundStyle(Theme.textPrimary)
                    .padding(Theme.cardPadding).card()
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Green dot when booked, grey when not.
    private func status(_ name: String, on: Bool) -> some View {
        HStack(spacing: 6) {
            Circle().fill(on ? Theme.success : Theme.hairline).frame(width: 8, height: 8)
            Text(name).font(.ltCaption).foregroundStyle(Theme.textBody)
        }
    }
}

/// Small red count bubble used on the bell and Fargo chat icons.
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

/// Service tiles dip slightly when pressed.
private struct ServiceTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
