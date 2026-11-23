import SwiftUI

/// Secure checkout: seat hold timer, price breakdown, ticket protection,
/// payment options (card, Apple Pay, points + card) and terms.
struct EventCheckoutView: View {
    @EnvironmentObject var app: AppState
    @State private var agreed = false
    @State private var paying = false

    var body: some View {
        if let cart = app.eventCart, let e = Sample.event(cart.eventID) {
            Screen(title: "Checkout") {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let left = max(0, Int(cart.holdUntil.timeIntervalSince(ctx.date)))
                    Label("Seats held for \(left / 60):\(String(format: "%02d", left % 60))", systemImage: "timer")
                        .monospacedDigit()
                }
                    .font(.ltCaption).foregroundStyle(Theme.goldText)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.goldSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 14) {
                    FillPhoto(name: e.photo, width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(e.title).font(.ltHeadline)
                        Text(e.dateText).font(.ltCaption).foregroundStyle(Theme.textBody)
                        Text(e.venue).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                        if cart.resalePrice != nil {
                            Label("Verified resale", systemImage: "checkmark.seal").font(.ltCaptionBold).foregroundStyle(Theme.success)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(Theme.cardPadding).card()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your seats").font(.ltHeadline)
                    ForEach(cart.seats) { s in
                        KeyValueRow(key: s.label, value: Money.usd(cart.price(of: s)))
                    }
                }
                .padding(Theme.cardPadding).card()

                Toggle(isOn: binding(\.protection)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ticket protection").font(.ltBody)
                        Text("Refund if you can't attend due to illness or travel delays · \(Money.usd(EventCart.protectionPerTicket))/ticket")
                            .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    }
                }
                .tint(Theme.button).padding(Theme.cardPadding).card()

                SectionTitle(text: "Payment")
                VStack(spacing: 0) {
                    ForEach(Array(EventPayment.allCases.enumerated()), id: \.element) { i, p in
                        if i > 0 { Divider().padding(.leading, 56) }
                        Button { app.eventCart?.payment = p } label: { paymentRow(p, selected: cart.payment == p) }
                            .buttonStyle(.plain)
                    }
                }
                .card()

                if cart.payment == .points {
                    PointsSlider(value: binding(\.pointsUsed),
                                 maxValue: min(app.points, cart.total * Theme.pointsPerDollar),
                                 balance: app.points)
                }

                VStack(spacing: 10) {
                    KeyValueRow(key: "Tickets (\(cart.seats.count))", value: Money.usd(cart.subtotal))
                    KeyValueRow(key: "Service & facility fees", value: Money.usd(cart.fees))
                    KeyValueRow(key: "Tax", value: Money.usd(cart.tax))
                    if cart.protection { KeyValueRow(key: "Ticket protection", value: Money.usd(cart.protectionCost)) }
                    if cart.payment == .points && cart.pointsUsed > 0 {
                        KeyValueRow(key: "Points applied", value: "−\(Money.usd(cart.pointsUsed / Theme.pointsPerDollar))")
                    }
                    Divider()
                    KeyValueRow(key: "Total", value: Money.usd(cart.payment == .points ? cart.cardDue : cart.total), bold: true)
                }
                .padding(Theme.cardPadding).card()

                Label("Mobile tickets · delivered instantly to My Tickets and your Wallet", systemImage: "iphone")
                    .font(.ltCaption).foregroundStyle(Theme.textBody).labelStyle(IconLabelStyle())
                Label("Payments are encrypted. Your card number is never shared with the venue.", systemImage: "lock.shield")
                    .font(.ltCaption).foregroundStyle(Theme.textBody).labelStyle(IconLabelStyle())

                Toggle("I agree to the purchase terms. All sales are final unless protected.", isOn: $agreed)
                    .tint(Theme.button).font(.ltBody).padding(Theme.cardPadding).card()
            }
            .onAppear { if cart.payment != .points { app.eventCart?.pointsUsed = 0 } }
            .safeAreaInset(edge: .bottom) {
                StickyBar {
                    PillButton(title: paying ? "Processing…" : payLabel(cart), enabled: agreed && !paying) {
                        paying = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_300_000_000)   // simulated payment
                            let order = app.finishEventOrder()
                            app.push(.eventConfirmed(order))
                        }
                    }
                }
            }
        }
    }

    private func payLabel(_ cart: EventCart) -> String {
        let amount = Money.usd(cart.payment == .points ? cart.cardDue : cart.total)
        return cart.payment == .applePay ? "Pay \(amount) with Apple Pay" : "Pay \(amount)"
    }

    private func paymentRow(_ p: EventPayment, selected: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: p.icon).font(.body).foregroundStyle(Theme.icon).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(p.title).font(.ltBody).foregroundStyle(Theme.textPrimary)
                if p == .points {
                    Text("Balance \(Money.pts(app.points))").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .font(.title3).foregroundStyle(selected ? Theme.button : Theme.textSecondary)
        }
        .padding(.horizontal, Theme.cardPadding).frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Binding into the cart; keeps the last value once the cart is cleared
    /// (after payment) so the screen can still draw while it leaves.
    private func binding<T>(_ kp: WritableKeyPath<EventCart, T>) -> Binding<T> {
        let fallback = app.eventCart?[keyPath: kp]
        return Binding(get: { app.eventCart?[keyPath: kp] ?? fallback! },
                       set: { app.eventCart?[keyPath: kp] = $0 })
    }
}

/// Purchase confirmation with wallet buttons.
struct EventConfirmedView: View {
    @EnvironmentObject var app: AppState
    let orderID: String

    private var tickets: [Ticket] { app.tickets.filter { $0.orderID == orderID } }

    var body: some View {
        let e = tickets.first?.event
        Screen(title: "You're going!") {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(Theme.success)
                Text("Tickets confirmed").font(.ltTitle)
                Text("Order \(orderID)").font(.ltBody).foregroundStyle(Theme.textBody)
            }
            .frame(maxWidth: .infinity).padding(24).card()

            if let e { EventCard(event: e, photoHeight: 200) }

            VStack(alignment: .leading, spacing: 10) {
                Text("\(tickets.count) mobile ticket\(tickets.count == 1 ? "" : "s")").font(.ltHeadline)
                ForEach(tickets) { t in
                    Label(t.seat.label, systemImage: "ticket").font(.ltBody).foregroundStyle(Theme.textBody)
                        .labelStyle(IconLabelStyle())
                }
                Text("A receipt was sent to \(app.guest.email).").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

            WalletButton(kind: .apple, added: tickets.allSatisfy(\.inWallet)) { addToWallet("Apple") }
            WalletButton(kind: .google) { app.show("Saved to Google Wallet") }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { app.eventCart = nil }      // order placed; start fresh next time
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: "Done", kind: .secondary) { app.goHome() }
                PillButton(title: "My Tickets") { app.path = [.events, .myTickets] }
            }
        }
    }

    private func addToWallet(_ name: String) {
        for i in app.tickets.indices where app.tickets[i].orderID == orderID { app.tickets[i].inWallet = true }
        app.show("Added to \(name) Wallet")
    }
}
