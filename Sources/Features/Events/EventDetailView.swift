import SwiftUI

/// Event page: big photo, details, alerts, verified resale and venue info.
struct EventDetailView: View {
    @EnvironmentObject var app: AppState
    let eventID: String

    var body: some View {
        if let e = Sample.event(eventID) {
            Screen(title: e.category.title) {
                FillPhoto(name: e.photo, height: 360)
                    .overlay(alignment: .topLeading) { DateBadge(event: e).padding(14) }
                    .overlay(alignment: .topTrailing) { FavoriteButton(eventID: e.id).padding(12) }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(e.title).font(.ltTitle).foregroundStyle(Theme.textPrimary)
                    Text(e.subtitle).font(.ltBody).foregroundStyle(Theme.textBody)
                    Group {
                        Label(e.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) + " · " +
                              e.date.formatted(.dateTime.hour().minute()), systemImage: "calendar")
                        Label("\(e.venue), \(e.city)", systemImage: "mappin.and.ellipse")
                        if e.sellingFast { Label("Selling fast · 80% of seats sold", systemImage: "flame") }
                    }
                    .font(.ltCaption).foregroundStyle(Theme.textBody).labelStyle(IconLabelStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

                alertCard(e)

                SectionTitle(text: "About")
                Text(e.about).font(.ltBody).foregroundStyle(Theme.textBody)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

                if !e.resale.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        SectionTitle(text: "Verified resale")
                        Spacer()
                        Label("Guaranteed", systemImage: "checkmark.seal").font(.ltCaption).foregroundStyle(Theme.success)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(e.resale.enumerated()), id: \.element.id) { i, l in
                            if i > 0 { Divider().padding(.leading, Theme.cardPadding) }
                            resaleRow(e, l)
                        }
                    }
                    .card()
                }

                SectionTitle(text: "Venue & accessibility")
                VStack(alignment: .leading, spacing: 10) {
                    Label("Wheelchair-accessible seating in every section", systemImage: "figure.roll")
                    Label("Assistive listening devices at Guest Services", systemImage: "ear")
                    Label("Clear bag policy · doors open 1 hour before", systemImage: "bag")
                    Label("Mobile tickets only · add to Apple or Google Wallet", systemImage: "iphone")
                }
                .font(.ltCaption).foregroundStyle(Theme.textBody).labelStyle(IconLabelStyle())
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
            }
            .safeAreaInset(edge: .bottom) {
                StickyBar {
                    VStack(alignment: .leading) {
                        Text(e.isOnSale ? "From \(Money.usd(e.priceFrom))" : "Coming soon").font(.ltHeadline)
                        Text(e.isOnSale ? "per ticket + fees" : "On sale \(e.onSale!.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                            .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if e.isOnSale {
                        PillButton(title: "Select seats", fullWidth: false) { app.push(.eventSeats(e.id)) }
                    } else {
                        PillButton(title: app.eventAlerts.contains(e.id) ? "Reminder set" : "Notify me",
                                   kind: app.eventAlerts.contains(e.id) ? .secondary : .primary, fullWidth: false) {
                            app.toggleAlert(e)
                        }
                    }
                }
            }
        }
    }

    private func alertCard(_ e: Event) -> some View {
        let on = app.eventAlerts.contains(e.id)
        return Toggle(isOn: Binding(get: { on }, set: { _ in app.toggleAlert(e) })) {
            HStack(spacing: 12) {
                Image(systemName: on ? "bell.fill" : "bell").foregroundStyle(Theme.icon).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.isOnSale ? "Price drop alerts" : "On-sale reminder").font(.ltBody)
                    Text(e.isOnSale ? "Get a notification if tickets get cheaper." : "We'll notify you the moment tickets go on sale.")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .tint(Theme.button)
        .padding(Theme.cardPadding).card()
    }

    private func resaleRow(_ e: Event, _ l: ResaleListing) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Sec \(l.section) · Row \(l.row)").font(.ltHeadline)
                Text("\(l.count) seats together · \(e.section(l.section)?.name ?? "")")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Money.usd(l.price)).font(.ltHeadline)
                Text("each").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            PillButton(title: "Buy", kind: .secondary, fullWidth: false) {
                app.eventCart = EventCart(eventID: e.id, seats: l.seats, resalePrice: l.price)
                app.push(.eventCheckout)
            }
        }
        .padding(Theme.cardPadding)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Seat map

/// Interactive seat map: tap a section, then pick seats (or best available).
struct SeatMapView: View {
    @EnvironmentObject var app: AppState
    let eventID: String

    @State private var sectionID = "104"
    @State private var quantity = 2
    @State private var picked: [Seat] = []

    private var event: Event? { Sample.event(eventID) }
    private var section: EventSection? { event?.section(sectionID) }

    var body: some View {
        if let e = event {
            Screen(title: "Select seats") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(e.title).font(.ltHeadline)
                    Text("\(e.dateText) · \(e.venue)").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }

                venueMap(e)

                VStack(spacing: 12) {
                    CounterRow(title: "Tickets", subtitle: "Up to \(EventCart.maxTickets) per order",
                               value: $quantity, range: 1...EventCart.maxTickets)
                        .onChange(of: quantity) { if picked.count > quantity { picked.removeFirst(picked.count - quantity) } }
                    PillButton(title: "Pick best available", kind: .secondary) { bestAvailable(e) }
                }
                .padding(Theme.cardPadding).card()

                if let s = section { seatGrid(e, s) }
            }
            .safeAreaInset(edge: .bottom) {
                StickyBar {
                    VStack(alignment: .leading) {
                        Text(picked.isEmpty ? "No seats selected" : "\(picked.count) ticket\(picked.count == 1 ? "" : "s") · \(Money.usd(picked.reduce(0) { $0 + (e.section($1.section)?.price ?? 0) }))")
                            .font(.ltHeadline)
                        Text(picked.isEmpty ? "Tap seats on the map" : "+ fees at checkout")
                            .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    PillButton(title: "Continue", enabled: !picked.isEmpty, fullWidth: false) {
                        app.eventCart = EventCart(eventID: e.id, seats: picked)
                        app.push(.eventCheckout)
                    }
                }
            }
        }
    }

    // MARK: Venue map

    private func venueMap(_ e: Event) -> some View {
        let s = e.sections
        return VStack(spacing: 10) {
            Text(e.category.stageLabel)
                .font(.caption.weight(.bold)).tracking(2).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Theme.textPrimary.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 40)
            sectionBox(e, s[0]).padding(.horizontal, 60)
            HStack(spacing: 8) { ForEach(s[1...3]) { sectionBox(e, $0) } }
            HStack(spacing: 8) { ForEach(s[4...6]) { sectionBox(e, $0) } }
            TierLegend().padding(.top, 4)
        }
        .padding(Theme.cardPadding).card()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Venue map")
    }

    private func sectionBox(_ e: Event, _ s: EventSection) -> some View {
        let selected = s.id == sectionID
        return Button {
            sectionID = s.id
        } label: {
            VStack(spacing: 2) {
                Text(s.id == "FLR" ? s.name : s.id).font(.subheadline.weight(.semibold))
                Text(Money.usd(s.price)).font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(s.tier.color.opacity(selected ? 1 : 0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(selected ? Theme.textPrimary : .clear, lineWidth: 3))
            .scaleEffect(selected ? 1.03 : 1)
            .animation(.easeOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Section \(s.name), \(Money.usd(s.price)) per ticket")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Seats

    private func seatGrid(_ e: Event, _ s: EventSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.id == "FLR" ? s.name : "Section \(s.id) · \(s.name)").font(.ltHeadline)
                    Text("\(Money.usd(s.price)) per ticket").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(picked.count)/\(quantity) picked").font(.ltCaptionBold).foregroundStyle(Theme.textBody)
            }
            HStack(alignment: .top, spacing: 6) {
                // Row letters stay put while the seats scroll sideways.
                VStack(spacing: 6) {
                    ForEach(0..<s.rows, id: \.self) { r in
                        Text(String(UnicodeScalar(65 + r)!))
                            .font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                            .frame(width: 16, height: 34)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityHidden(true)
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(0..<s.rows, id: \.self) { r in
                            let row = String(UnicodeScalar(65 + r)!)
                            HStack(spacing: 6) {
                                ForEach(1...s.seatsPerRow, id: \.self) { n in
                                    seatButton(e, s, Seat(section: s.id, row: row, number: n))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .defaultScrollAnchor(.center)      // middle seats first
            }
            Text("Front of section is row A. Scroll sideways for more seats.")
                .font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.cardPadding).card()
    }

    private func seatButton(_ e: Event, _ s: EventSection, _ seat: Seat) -> some View {
        let taken = e.isTaken(seat)
        let selected = picked.contains(seat)
        return Button { toggle(seat) } label: {
            ZStack {
                Circle().fill(taken ? Theme.hairline : selected ? s.tier.color : Color.white)
                Circle().strokeBorder(taken ? .clear : s.tier.color, lineWidth: 1.5)
                if selected { Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(.white) }
            }
            .frame(width: 26, height: 26)
            .frame(width: 30, height: 34)        // larger tap target
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(taken)
        .accessibilityLabel("Row \(seat.row), seat \(seat.number)")
        .accessibilityValue(taken ? "Taken" : selected ? "Selected" : "Available, \(Money.usd(s.price))")
    }

    private func toggle(_ seat: Seat) {
        if let i = picked.firstIndex(of: seat) { picked.remove(at: i); return }
        if picked.count >= quantity { picked.removeFirst() }
        picked.append(seat)
    }

    /// First run of `quantity` free seats together, front rows first, centered.
    private func bestAvailable(_ e: Event) {
        let order = ["104", "FLR", "101", "107", "304", "301", "307"]
        for id in [sectionID] + order {
            guard let s = e.section(id) else { continue }
            for r in 0..<s.rows {
                let row = String(UnicodeScalar(65 + r)!)
                let middle = s.seatsPerRow / 2
                let starts = (1...max(1, s.seatsPerRow - quantity + 1)).sorted { abs($0 - middle) < abs($1 - middle) }
                for start in starts {
                    let seats = (0..<quantity).map { Seat(section: s.id, row: row, number: start + $0) }
                    if seats.allSatisfy({ $0.number <= s.seatsPerRow && !e.isTaken($0) }) {
                        sectionID = s.id
                        picked = seats
                        return
                    }
                }
            }
        }
        app.show("No \(quantity) seats together right now")
    }
}
