import SwiftUI

/// Day 1 – Landing page: balance, "Book now" grid, explore tabs, plans, tab bar.
struct LandingView: View {
    @EnvironmentObject var app: AppState

    /// Which explore tab is selected (Travel / Entertainment / Dining / Exclusives).
    @State private var tab = "Travel"
    private let tabs = ["Travel", "Entertainment", "Dining", "Exclusives"]

    /// One tile in the "Book now" grid. `route == nil` means "not in this release".
    private struct Service: Identifiable {
        let id: String; let icon: String; let route: Route?
        init(_ id: String, _ icon: String, _ route: Route?) { self.id = id; self.icon = icon; self.route = route }
    }
    private let services = [
        Service("Hotels", "bed.double", .hotelResults),
        Service("Flights", "airplane", nil),
        Service("Cars", "car", nil),
        Service("Cruises", "ferry", nil),
        Service("Experiences", "sparkles", nil),
        Service("Events", "fork.knife", .diningRestaurant)
    ]

    /// A promo card in the carousel.
    private struct Promo: Identifiable {
        let id: String; let title: String; let sub: String; let scene: SceneKind; let route: Route
    }
    private var promos: [Promo] {
        switch tab {
        case "Travel":
            return [Promo(id: "p1", title: "Caribbean Beach Hotel", sub: "From $250 / night", scene: .beach, route: .hotelRooms("caribbean")),
                    Promo(id: "p2", title: "Alpine Adventure", sub: "Mountain stays", scene: .garden, route: .hotelResults),
                    Promo(id: "p3", title: "Big City Nights", sub: "Urban escapes", scene: .city, route: .hotelResults)]
        case "Dining":
            return [Promo(id: "d1", title: "Trattoria Verde", sub: "Italian · Montrose", scene: .restaurant, route: .diningRestaurant),
                    Promo(id: "d2", title: "Harbor & Vine", sub: "Seafood", scene: .sunset, route: .diningRestaurant),
                    Promo(id: "d3", title: "Sol y Mar", sub: "Mexican", scene: .beach, route: .diningRestaurant)]
        default:
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                titleBlock
                balanceCard
                conciergePill
                bookNow
                explore
                myPlans
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
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
            Text("\(app.points.formatted())")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14).frame(height: 44)
                .glass(in: Capsule())
            GlassIconButton(systemName: "bell")
        }
        .padding(.top, 8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Good afternoon").font(.ltBody).foregroundStyle(Theme.textSecondary)
            Text("Alex Morgan").font(.ltLargeTitle).foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: Balance card

    /// Rewards balance shown on top of the Autograph Journey card artwork.
    /// Text is placed only in the card's empty dark regions so it never covers
    /// the printed logos, chip or network mark.
    private var balanceCard: some View {
        Image("AutographJourneyCard")
            .resizable()
            .aspectRatio(432.0 / 276.0, contentMode: .fit)
            .scaleEffect(1.03) // trims the white matte baked into the artwork's corners
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    ZStack(alignment: .topLeading) {
                        // Right of the chip, below the gold stripe.
                        Text("Earn 5X on Hotels")
                            .font(.ltCaptionBold).foregroundStyle(Theme.gold)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.black.opacity(0.35), in: Capsule())
                            .overlay(Capsule().stroke(Theme.gold.opacity(0.6), lineWidth: 1))
                            .frame(width: w * 0.58, alignment: .trailing)
                            .offset(x: w * 0.36, y: h * 0.45)

                        // Bottom-left dark area, clear of the chip and the VISA mark.
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rewards balance").font(.ltCaption).foregroundStyle(.white.opacity(0.75))
                            Text(Money.usd(app.points / Theme.pointsPerDollar) + ".50")
                                .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                                .lineLimit(1).minimumScaleFactor(0.6)
                            Text("\(app.points.formatted()) points").font(.ltBody).foregroundStyle(.white.opacity(0.85))
                        }
                        .frame(width: w * 0.66, height: h * 0.42, alignment: .bottomLeading)
                        .offset(x: w * 0.06, y: h * 0.53)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            .accessibilityElement(children: .combine)
    }

    // MARK: Concierge search pill

    private var conciergePill: some View {
        Button { app.push(.concierge) } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass").foregroundStyle(Theme.red)
                Text("Ask Concierge anything").foregroundStyle(Theme.textBody)
                Spacer()
            }
            .font(.ltBody)
            .padding(.horizontal, 18).frame(height: 52)
            .glass(in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Book now grid

    private var bookNow: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Book now")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(services) { s in
                    Button { if let r = s.route { app.push(r) } } label: {
                        VStack(spacing: 8) {
                            Image(systemName: s.icon)
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Theme.red)
                                .frame(width: 64, height: 64)
                                // hairline outline (no solid fill) + chevron cue = "tappable"
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Theme.hairline, lineWidth: 1))
                            Text(s.id).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .card(radius: 20)
                        .opacity(s.route == nil ? 0.55 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Explore tabs + carousel

    private var explore: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Underline tab list – selected = bold black text + red underline.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(tabs, id: \.self) { t in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { tab = t } } label: {
                            VStack(spacing: 6) {
                                Text(t).font(.system(size: 16, weight: tab == t ? .bold : .medium))
                                    .foregroundStyle(tab == t ? Theme.textPrimary : Theme.textSecondary)
                                Rectangle().fill(tab == t ? Theme.red : .clear).frame(height: 2)
                            }
                        }
                    }
                }
            }
            if promos.isEmpty {
                Text("Coming in a later release.").font(.ltBody).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(promos) { p in
                            Button { app.push(p.route) } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    SceneArt(kind: p.scene).frame(width: 240, height: 140)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(p.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                                        Text(p.sub).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                                    }.padding(18)
                                }
                                .frame(width: 240, alignment: .leading)
                                .card()
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 12)   // room for the card shadows
                }
            }
        }
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
