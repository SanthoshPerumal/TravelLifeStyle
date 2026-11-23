import SwiftUI

/// My Tickets: upcoming and past events the customer has tickets for.
struct MyTicketsView: View {
    @EnvironmentObject var app: AppState
    @State private var past = false

    /// Event IDs with tickets, in date order.
    private var eventIDs: [String] {
        let ids = Array(Set(app.tickets.map(\.eventID)))
        return ids.compactMap(Sample.event).filter { $0.isPast == past }
            .sorted { past ? $0.date > $1.date : $0.date < $1.date }.map(\.id)
    }

    var body: some View {
        Screen(title: "My Tickets") {
            Picker("Tickets", selection: $past) {
                Text("Upcoming").tag(false)
                Text("Past").tag(true)
            }
            .pickerStyle(.segmented)

            if eventIDs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket").font(.title).foregroundStyle(Theme.icon)
                    Text(past ? "No past events" : "No upcoming tickets").font(.ltHeadline)
                    if !past {
                        PillButton(title: "Find events", kind: .secondary) { app.path = [.events] }
                    }
                }
                .frame(maxWidth: .infinity).padding(24).card()
            }

            ForEach(eventIDs, id: \.self) { id in
                if let e = Sample.event(id) {
                    let tickets = app.tickets.filter { $0.eventID == id }
                    Button { app.push(.eventTickets(id)) } label: { ticketCard(e, tickets) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func ticketCard(_ e: Event, _ tickets: [Ticket]) -> some View {
        let seats = tickets.map { "\($0.seat.row)\($0.seat.number)" }.joined(separator: ", ")
        let statuses = Set(tickets.map(\.status.title))
        return VStack(alignment: .leading, spacing: 0) {
            FillPhoto(name: e.photo, height: 250)
                .saturation(e.isPast ? 0.3 : 1)
                .overlay(alignment: .topLeading) { DateBadge(event: e).padding(12) }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(e.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    Text("\(e.dateText) · \(e.venue)").font(.ltCaption).foregroundStyle(Theme.textBody)
                    Text("\(tickets.count) ticket\(tickets.count == 1 ? "" : "s") · Sec \(tickets.first?.seat.section ?? "") · \(seats)")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(e.isPast ? "Attended" : statuses.count == 1 ? statuses.first! : "Mixed")
                    .font(.ltCaptionBold)
                    .foregroundStyle(e.isPast ? Theme.textBody : Theme.success)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(e.isPast ? Theme.background : Theme.success.opacity(0.12), in: Capsule())
                    .fixedSize()
            }
            .padding(Theme.cardPadding)
        }
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Tickets for one event: swipeable mobile tickets with QR code, wallet,
/// transfer and resale.
struct EventTicketsView: View {
    @EnvironmentObject var app: AppState
    let eventID: String

    @State private var page = 0
    @State private var transferring: Ticket?
    @State private var selling: Ticket?

    private var tickets: [Ticket] { app.tickets.filter { $0.eventID == eventID } }

    var body: some View {
        if let e = Sample.event(eventID) {
            Screen(title: "Tickets") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(e.title).font(.ltHeadline)
                    Text("\(e.dateText) · \(e.venue)").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }

                TabView(selection: $page) {
                    ForEach(Array(tickets.enumerated()), id: \.element.id) { i, t in
                        ticketPass(e, t, index: i).tag(i).padding(.horizontal, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 570)

                PageIndicator(count: tickets.count, current: page, label: "Ticket") { i in withAnimation { page = i } }
                    .frame(maxWidth: .infinity)

                if let t = tickets[safe: page], !e.isPast {
                    actions(t)
                }
            }
            .sheet(item: $transferring) { TransferSheet(ticket: $0) }
            .sheet(item: $selling) { ResellSheet(ticket: $0) }
        }
    }

    /// The mobile ticket itself.
    private func ticketPass(_ e: Event, _ t: Ticket, index: Int) -> some View {
        VStack(spacing: 0) {
            FillPhoto(name: e.photo, height: 200)
                .overlay(alignment: .bottomLeading) {
                    Text(e.title).font(.ltHeadline).foregroundStyle(.white)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                }
            HStack {
                seatField("Section", t.seat.section)
                seatField("Row", t.seat.row)
                seatField("Seat", "\(t.seat.number)")
            }
            .padding(.horizontal, Theme.cardPadding).padding(.top, 14)

            Group {
                switch t.status {
                case .active:
                    QRCodeView(payload: t.barcode).frame(width: 200, height: 200).padding(.vertical, 12)
                        .opacity(e.isPast ? 0.25 : 1)
                    Text(e.isPast ? "Used · \(e.date.formatted(.dateTime.month().day()))" : "Show this code at the gate. Turn up your screen brightness for scanning.")
                        .font(.caption).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                case .transferred(let to):
                    statusBlock("arrow.right.circle", "Transferred to \(to)", "This ticket is now in their account.")
                case .listed(let price):
                    statusBlock("tag", "Listed for \(Money.usd(price))", "You'll be paid out when it sells.")
                case .sold(let price):
                    statusBlock("checkmark.circle", "Sold for \(Money.usd(price))", "Payout is on its way.")
                }
            }
            .padding(.horizontal, Theme.cardPadding)
            Spacer(minLength: 12)
            Text("Ticket \(index + 1) of \(tickets.count) · Order \(t.orderID)")
                .font(.caption).foregroundStyle(Theme.textSecondary).padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .shadow(color: Color(hex: 0x14142B).opacity(0.08), radius: 12, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ticket \(index + 1), \(t.seat.label), \(t.status.title)")
    }

    private func seatField(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text(value).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusBlock(_ icon: String, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(Theme.icon)
            Text(title).font(.ltHeadline)
            Text(detail).font(.ltCaption).foregroundStyle(Theme.textSecondary)
        }
        .frame(height: 224)
    }

    private func actions(_ t: Ticket) -> some View {
        VStack(spacing: 12) {
            if t.status == .active {
                WalletButton(kind: .apple, added: t.inWallet) {
                    if let i = app.tickets.firstIndex(of: t) { app.tickets[i].inWallet = true }
                    app.show("Added to Apple Wallet")
                }
                WalletButton(kind: .google) { app.show("Saved to Google Wallet") }
                HStack(spacing: 12) {
                    PillButton(title: "Transfer", kind: .secondary) { transferring = t }
                    PillButton(title: "Sell", kind: .secondary) { selling = t }
                }
            } else if case .listed = t.status {
                PillButton(title: "Remove listing", kind: .secondary) {
                    update(t) { $0.status = .active }
                    app.show("Listing removed")
                }
            }
        }
    }

    private func update(_ t: Ticket, _ change: (inout Ticket) -> Void) {
        if let i = app.tickets.firstIndex(of: t) { change(&app.tickets[i]) }
    }
}

// MARK: - Transfer & resale

struct TransferSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let ticket: Ticket
    @State private var name = ""
    @State private var email = ""

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.wholeMatch(of: /[^@\s]+@[^@\s]+\.[A-Za-z]{2,}/) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(ticket.seat.label).font(.ltHeadline)
                } footer: {
                    Text("They'll get an email to accept the ticket. Once accepted, it leaves your account and the barcode changes.")
                }
                Section("Recipient") {
                    TextField("Full name", text: $name).textContentType(.name)
                    TextField("Email", text: $email).textContentType(.emailAddress)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Transfer ticket").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                PillButton(title: "Transfer ticket", enabled: valid) {
                    if let i = app.tickets.firstIndex(of: ticket) { app.tickets[i].status = .transferred(to: name) }
                    app.show("Ticket sent to \(name)")
                    dismiss()
                }
                .padding(.horizontal, Theme.screenPadding).padding(.vertical, 10).background(.bar)
            }
        }
        .tint(Theme.button)
        .presentationDetents([.medium, .large])
    }
}

struct ResellSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let ticket: Ticket
    @State private var price: Int

    init(ticket: Ticket) {
        self.ticket = ticket
        _price = State(initialValue: Int(Double(ticket.price) * 1.1))
    }

    private var payout: Int { Int(Double(price) * 0.9) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(ticket.seat.label).font(.ltHeadline)
                    KeyValueRow(key: "You paid", value: Money.usd(ticket.price))
                }
                Section {
                    Stepper(value: $price, in: max(10, ticket.price / 2)...(ticket.price * 3), step: 5) {
                        KeyValueRow(key: "List price", value: Money.usd(price), bold: true)
                    }
                    KeyValueRow(key: "Seller fee (10%)", value: "−\(Money.usd(price - payout))")
                    KeyValueRow(key: "Your payout", value: Money.usd(payout), bold: true)
                } header: { Text("Price per ticket") } footer: {
                    Text("Similar seats are listed between \(Money.usd(ticket.price)) and \(Money.usd(ticket.price * 2)). Payout goes to your Autograph Journey card when it sells.")
                }
            }
            .navigationTitle("Sell ticket").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                PillButton(title: "List for \(Money.usd(price))") {
                    if let i = app.tickets.firstIndex(of: ticket) { app.tickets[i].status = .listed(price: price) }
                    app.show("Listed on verified resale")
                    dismiss()
                }
                .padding(.horizontal, Theme.screenPadding).padding(.vertical, 10).background(.bar)
            }
        }
        .tint(Theme.button)
        .presentationDetents([.medium, .large])
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
