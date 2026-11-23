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
        Service("Book hotel", "building.2", .hotelResults),
        Service("Book car", "car", nil),
        Service("Reserve a table", "fork.knife", .diningRestaurant),
        Service("Book event", "theatermasks", nil),
        Service("Book experience", "ticket", nil)
    ]

    /// A discounted hotel deal in the "Latest hotel offers" carousel.
    private struct HotelOffer: Identifiable {
        let hotel: Hotel
        let photo: String       // asset name (Unsplash photo, see README)
        let percentOff: Int
        var id: String { hotel.id }
        var dealPrice: Int { hotel.nightly * (100 - percentOff) / 100 }
    }
    private let offers: [HotelOffer] = {
        let deals: [String: (String, Int)] = [
            "caribbean": ("HotelCaribbean", 20),
            "modern":    ("HotelModern", 15),
            "garden":    ("HotelGarden", 25),
            "bayou":     ("HotelBayou", 10),
            "sunset":    ("HotelSunset", 30)
        ]
        return Sample.hotels.compactMap { h in
            deals[h.id].map { HotelOffer(hotel: h, photo: $0.0, percentOff: $0.1) }
        }
    }()

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
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(alignment: .topTrailing) { CountBadge(count: 3).offset(x: -2, y: 2) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications, 3 unread")
            Button("Sign off") {}
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.textPrimary)
                .buttonStyle(.plain)
                .padding(.leading, 8)
        }
        .padding(.top, 8)
    }

    private var titleBlock: some View {
        Text("\(greeting), Alex")
            .font(.system(size: 28, weight: .regular))
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text("Rewards balance")
                        .font(.ltBody).foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "star")
                    .font(.system(size: 16, weight: .regular))
                Text("\(app.points.formatted()) rewards points")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14).frame(height: 44)
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
                .font(.system(size: 16))
                .padding(.horizontal, 14).frame(height: 42)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button { app.push(.concierge) } label: {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(colors: [Theme.red, Color(hex: 0x6B1E5C)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
                                .font(.system(size: 30, weight: .light))
                                .foregroundStyle(Theme.red)
                                .frame(height: 36)
                            Text(s.id)
                                .font(.system(size: 15, weight: .regular))
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

    // MARK: Latest hotel offers

    private var hotelOffers: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(text: "Latest hotel offers")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(offers) { o in
                        Button { app.push(.hotelRooms(o.hotel.id)) } label: {
                            offerCard(o)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)   // room for the card shadows
            }
            .scrollClipDisabled()
        }
    }

    private func offerCard(_ o: HotelOffer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(o.photo)
                .resizable()
                .scaledToFill()
                .frame(width: 260, height: 160)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text("\(o.percentOff)% OFF")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.red, in: Capsule())
                        .padding(12)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(o.hotel.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(Theme.gold)
                    Text(String(format: "%.1f", o.hotel.rating)).foregroundStyle(Theme.textPrimary)
                    Text("· \(o.hotel.area)").foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
                .font(.ltCaption)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Money.usd(o.dealPrice))
                        .font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    Text(Money.usd(o.hotel.nightly))
                        .font(.ltCaption).strikethrough().foregroundStyle(Theme.textSecondary)
                    Text("/ night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
        }
        .frame(width: 260, alignment: .leading)
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(o.hotel.name), \(o.percentOff) percent off, \(Money.usd(o.dealPrice)) per night, was \(Money.usd(o.hotel.nightly))")
    }

    // MARK: My plans

    private var myPlans: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "My plans")
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
            tabItem("house.fill", "Home", active: true) {}
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
                Image(systemName: icon).font(.system(size: 19))
                Text(label).font(.system(size: 10, weight: .medium))
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
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 17, minHeight: 17)
            .background(Theme.red, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
    }
}
