import SwiftUI

// MARK: - Events: discovery, seats, orders and tickets
// Sample events at fictional Houston venues. Teams are named by city only.

enum EventCategory: String, CaseIterable, Identifiable, Hashable {
    case concerts, football, basketball, soccer, comedy, theater, festivals

    var id: String { rawValue }
    var title: String {
        switch self {
        case .concerts:   return "Concerts"
        case .football:   return "NFL"
        case .basketball: return "NBA"
        case .soccer:     return "Soccer"
        case .comedy:     return "Comedy"
        case .theater:    return "Theater"
        case .festivals:  return "Festivals"
        }
    }
    var icon: String {
        switch self {
        case .concerts:   return "music.mic"
        case .football:   return "football"
        case .basketball: return "basketball"
        case .soccer:     return "soccerball"
        case .comedy:     return "theatermask.and.paintbrush"
        case .theater:    return "theatermasks"
        case .festivals:  return "music.note.list"
        }
    }
    /// What sits at the front of the seat map.
    var stageLabel: String {
        switch self {
        case .football, .soccer: return "FIELD"
        case .basketball:        return "COURT"
        default:                 return "STAGE"
        }
    }
    var isSport: Bool { [.football, .basketball, .soccer].contains(self) }
}

/// Price tier for a section: drives the color on the seat map.
enum SeatTier: Int, CaseIterable, Hashable {
    case premium, lower, upper

    var color: Color {
        switch self {
        case .premium: return Color(hex: 0x463D3A)
        case .lower:   return Color(hex: 0x8A6A2E)
        case .upper:   return Color(hex: 0x4F6D8A)
        }
    }
}

struct EventSection: Identifiable, Hashable {
    let id: String          // "104"
    let name: String        // "Lower Center"
    let tier: SeatTier
    let price: Int          // per ticket, before fees
    let rows: Int
    let seatsPerRow: Int
}

struct Seat: Identifiable, Hashable {
    let section: String
    let row: String
    let number: Int
    var id: String { "\(section)-\(row)-\(number)" }
    var label: String { "Sec \(section) · Row \(row) · Seat \(number)" }
}

/// A verified resale listing (secondary market).
struct ResaleListing: Identifiable, Hashable {
    let id: String
    let section: String
    let row: String
    let firstSeat: Int
    let count: Int
    let price: Int          // per ticket

    var seats: [Seat] { (0..<count).map { Seat(section: section, row: row, number: firstSeat + $0) } }
}

struct Event: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: EventCategory
    let venue: String
    let city: String
    let date: Date
    let photo: String
    let about: String
    let basePrice: Int
    /// nil = on sale now.
    var onSale: Date? = nil
    var sellingFast = false
    var popularity = 50

    static func == (a: Event, b: Event) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    var isOnSale: Bool { onSale.map { $0 <= .now } ?? true }
    var isPast: Bool { date < .now }

    var sections: [EventSection] {
        let names: [(String, String, SeatTier, Double, Int, Int)] = [
            ("FLR", category.isSport ? (category == .basketball ? "Courtside" : "Field Club") : category == .theater ? "Orchestra" : "Floor",
             .premium, 3.2, 6, 12),
            ("101", "Lower Left", .lower, 1.7, 8, 14),
            ("104", "Lower Center", .lower, 2.0, 8, 16),
            ("107", "Lower Right", .lower, 1.7, 8, 14),
            ("301", "Upper Left", .upper, 1.0, 9, 16),
            ("304", "Upper Center", .upper, 1.2, 9, 18),
            ("307", "Upper Right", .upper, 1.0, 9, 16)
        ]
        return names.map { EventSection(id: $0.0, name: $0.1, tier: $0.2, price: Int(Double(basePrice) * $0.3), rows: $0.4, seatsPerRow: $0.5) }
    }
    var priceFrom: Int { sections.map(\.price).min() ?? basePrice }

    func section(_ id: String) -> EventSection? { sections.first { $0.id == id } }

    /// Deterministic "taken" seats so the map looks the same every time.
    func isTaken(_ seat: Seat) -> Bool {
        // FNV-1a hash: scatters taken seats instead of whole rows.
        var h: UInt64 = 0xcbf29ce484222325
        for b in (id + "|" + seat.id).utf8 { h ^= UInt64(b); h &*= 0x100000001b3 }
        return Int(h % 100) < (sellingFast ? 55 : 32)
    }

    var resale: [ResaleListing] {
        guard isOnSale else { return [] }
        return [
            ResaleListing(id: "\(id)-r1", section: "FLR", row: "B", firstSeat: 5, count: 2, price: Int(Double(basePrice) * 3.6)),
            ResaleListing(id: "\(id)-r2", section: "104", row: "H", firstSeat: 9, count: 4, price: Int(Double(basePrice) * 2.1)),
            ResaleListing(id: "\(id)-r3", section: "304", row: "C", firstSeat: 2, count: 2, price: Int(Double(basePrice) * 1.05))
        ]
    }

    /// "Sat, Dec 12 · 8:00 PM"
    var dateText: String { date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · " + date.formatted(.dateTime.hour().minute()) }
    var dayBadge: (month: String, day: String) {
        (date.formatted(.dateTime.month(.abbreviated)).uppercased(), date.formatted(.dateTime.day()))
    }
}

// MARK: - Orders & tickets

enum TicketStatus: Hashable {
    case active
    case transferred(to: String)
    case listed(price: Int)
    case sold(price: Int)

    var title: String {
        switch self {
        case .active:            return "Ready"
        case .transferred:       return "Transferred"
        case .listed:            return "Listed for resale"
        case .sold:              return "Sold"
        }
    }
}

struct Ticket: Identifiable, Hashable {
    let id: String
    let eventID: String
    let seat: Seat
    let price: Int
    let orderID: String
    var status: TicketStatus = .active
    var inWallet = false

    var event: Event? { Sample.event(eventID) }
    /// Payload for the QR code.
    var barcode: String { "TLS|\(orderID)|\(id)|\(seat.id)" }
}

enum EventPayment: String, CaseIterable, Identifiable {
    case card, applePay, points
    var id: String { rawValue }
    var title: String {
        switch self {
        case .card:     return "Autograph Journey Visa •••• 4821"
        case .applePay: return "Apple Pay"
        case .points:   return "Points + card"
        }
    }
    var icon: String {
        switch self {
        case .card:     return "creditcard"
        case .applePay: return "apple.logo"
        case .points:   return "star.circle"
        }
    }
}

/// Seats being bought: from the seat map or a resale listing.
struct EventCart: Equatable {
    var eventID: String
    var seats: [Seat] = []
    /// Per-ticket price when buying a resale listing; nil = section prices.
    var resalePrice: Int? = nil
    var protection = false
    var payment: EventPayment = .card
    var pointsUsed = 0
    var holdUntil = Date.now.addingTimeInterval(600)

    static let serviceFeeRate = 0.15
    static let facilityFee = 5
    static let taxRate = 0.0825
    static let protectionPerTicket = 9
    static let maxTickets = 8

    func price(of seat: Seat) -> Int {
        resalePrice ?? Sample.event(eventID)?.section(seat.section)?.price ?? 0
    }
    var subtotal: Int { seats.reduce(0) { $0 + price(of: $1) } }
    var fees: Int { Int((Double(subtotal) * Self.serviceFeeRate).rounded()) + Self.facilityFee * seats.count }
    var tax: Int { Int((Double(subtotal + fees) * Self.taxRate).rounded()) }
    var protectionCost: Int { protection ? Self.protectionPerTicket * seats.count : 0 }
    var total: Int { subtotal + fees + tax + protectionCost }
    var cardDue: Int { max(total - pointsUsed / Theme.pointsPerDollar, 0) }
}

/// Discover filters.
struct EventFilters: Equatable {
    enum When: String, CaseIterable { case any = "Any date", week = "This week", month = "This month", quarter = "Next 3 months" }
    enum Sort: String, CaseIterable { case date = "Date", price = "Price", popular = "Popular" }

    var category: EventCategory?
    var when: When = .any
    var maxPrice: Int?
    var onSaleOnly = false
    var favoritesOnly = false
    var sort: Sort = .date

    static let priceSteps = [75, 150, 300]

    var activeCount: Int {
        (when == .any ? 0 : 1) + (maxPrice == nil ? 0 : 1) + (onSaleOnly ? 1 : 0) + (favoritesOnly ? 1 : 0)
    }
}

// MARK: - Sample events

extension Sample {
    static let events: [Event] = [
        Event(id: "jazz", title: "Bayou Jazz Nights", subtitle: "Marcus Hale Quartet · Lena Brooks",
              category: .concerts, venue: "Blue Room Hall", city: "Houston", date: day(2026, 12, 5, 20), photo: "EventJazz",
              about: "An intimate evening of modern jazz with two of Houston's finest bands, small plates and a full cocktail bar.",
              basePrice: 45, popularity: 61),
        Event(id: "neon", title: "Neon Harbor — Skyline Tour", subtitle: "With special guest Aria Vale",
              category: .concerts, venue: "Downtown Arena", city: "Houston", date: day(2026, 12, 12, 20), photo: "EventConcert",
              about: "The synth-pop duo brings their Skyline Tour to Houston with a full light show and songs from the new album.",
              basePrice: 65, sellingFast: true, popularity: 95),
        Event(id: "nfl-hou-dal", title: "Houston vs Dallas", subtitle: "Pro football · Week 16",
              category: .football, venue: "Bayou Stadium", city: "Houston", date: day(2026, 12, 20, 15, 25), photo: "EventFootball",
              about: "The in-state rivalry with playoff seeding on the line. Gates open 2 hours before kickoff.",
              basePrice: 85, sellingFast: true, popularity: 99),
        Event(id: "rock", title: "The Midnight Static", subtitle: "Live in concert",
              category: .concerts, venue: "Warehouse 9", city: "Houston", date: day(2027, 1, 2, 21), photo: "EventRock",
              about: "Loud guitars and a career-spanning set from the alt-rock favorites. During your Houston trip.",
              basePrice: 55, popularity: 78),
        Event(id: "symphony", title: "Riverside Symphony: New World", subtitle: "Dvořák Symphony No. 9",
              category: .theater, venue: "Riverside Concert Hall", city: "Houston", date: day(2027, 1, 3, 19, 30), photo: "EventOrchestra",
              about: "The full orchestra and chorus perform Dvořák's New World Symphony, with a pre-concert talk at 6:30 PM.",
              basePrice: 40, popularity: 55),
        Event(id: "nba-hou-la", title: "Houston vs Los Angeles", subtitle: "Pro basketball · Regular season",
              category: .basketball, venue: "Downtown Arena", city: "Houston", date: day(2027, 1, 8, 19), photo: "EventBasketball",
              about: "Two West contenders meet in a Friday night showdown. Free poster night for the first 5,000 fans.",
              basePrice: 70, popularity: 90),
        Event(id: "comedy", title: "Laugh Track Live", subtitle: "Dana Ruiz · Theo Park · Sam Ellis",
              category: .comedy, venue: "The Punchline Club", city: "Houston", date: day(2027, 1, 15, 20), photo: "EventComedy",
              about: "Three headliners, one night. 18+ show; two-drink minimum at tables.",
              basePrice: 35, popularity: 48),
        Event(id: "soccer", title: "Houston vs Austin", subtitle: "Pro soccer · Texas derby",
              category: .soccer, venue: "Eastside Stadium", city: "Houston", date: day(2027, 2, 27, 19, 30), photo: "EventSoccer",
              about: "The Texas derby opens the season. Supporters' section on the north end.",
              basePrice: 38, popularity: 70),
        Event(id: "musical", title: "The Phantom Hours", subtitle: "Broadway touring musical",
              category: .theater, venue: "Grand Theater", city: "Houston", date: day(2027, 2, 13, 19, 30), photo: "EventTheater",
              about: "The award-winning musical arrives for a two-week run. Running time 2 hrs 40 min with one intermission.",
              basePrice: 60, popularity: 74),
        Event(id: "festival", title: "Gulf Coast Music Festival", subtitle: "3 days · 40+ artists",
              category: .festivals, venue: "Eleanor Park", city: "Houston", date: day(2027, 3, 19, 12), photo: "EventFestival",
              about: "Three stages across three days of indie, hip-hop and electronic music, plus local food trucks.",
              basePrice: 110, onSale: day(2026, 12, 1, 10), popularity: 88),
        // Past event (for My Tickets history)
        Event(id: "fall-fest", title: "Fall Lights Concert", subtitle: "Neon Harbor · Aria Vale",
              category: .concerts, venue: "Downtown Arena", city: "Houston", date: day(2026, 10, 10, 20), photo: "EventConcert",
              about: "Fall concert series.", basePrice: 55, popularity: 60)
    ]

    static func event(_ id: String) -> Event? { events.first { $0.id == id } }

    /// Tickets the customer already owns.
    static let seedTickets: [Ticket] = [
        Ticket(id: "t-jazz-1", eventID: "jazz", seat: Seat(section: "104", row: "D", number: 7), price: 90, orderID: "EV-48217"),
        Ticket(id: "t-jazz-2", eventID: "jazz", seat: Seat(section: "104", row: "D", number: 8), price: 90, orderID: "EV-48217"),
        Ticket(id: "t-fall-1", eventID: "fall-fest", seat: Seat(section: "FLR", row: "C", number: 3), price: 176, orderID: "EV-39104"),
        Ticket(id: "t-fall-2", eventID: "fall-fest", seat: Seat(section: "FLR", row: "C", number: 4), price: 176, orderID: "EV-39104")
    ]
}
