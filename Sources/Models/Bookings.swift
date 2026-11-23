import Foundation

// MARK: - Trips & booking history
// Sample trips with their reservations, before and after today. The Houston
// trip (Jan 1 – 3, 2027) is the live one the app books into; it isn't listed
// here because its entries come from `AppState`.

enum BookingKind: String, Hashable {
    case flight, hotel, dining, car, event

    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .hotel:  return "bed.double"
        case .dining: return "fork.knife"
        case .car:    return "car"
        case .event:  return "ticket"
        }
    }
    var title: String {
        switch self {
        case .flight: return "Flight"
        case .hotel:  return "Hotel stay"
        case .dining: return "Dinner"
        case .car:    return "Car rental"
        case .event:  return "Experience"
        }
    }
}

enum BookingStatus: String, Hashable {
    case confirmed, completed, cancelled

    var title: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct Booking: Identifiable, Hashable {
    let id: String
    let kind: BookingKind
    let title: String
    /// One line, e.g. "Fri, Feb 12 · 8:05 AM · Economy Plus".
    let detail: String
    let start: Date
    var end: Date? = nil
    let confirmation: String
    /// Total paid in USD.
    let total: Int
    var pointsUsed = 0
    var cancelled = false
    /// Optional photo asset.
    var photo: String? = nil
    /// Extra rows for the detail page.
    var facts: [(String, String)] = []

    /// Past once it has ended (or started, if it has no end).
    var isPast: Bool { isPast(at: .now) }
    func isPast(at now: Date) -> Bool { (end ?? start) < now }
    var status: BookingStatus { cancelled ? .cancelled : isPast ? .completed : .confirmed }

    /// "Feb 12 – 15, 2027" or "Feb 13, 2027".
    var dateText: String { Trip.rangeText(start, end) }

    static func == (a: Booking, b: Booking) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

struct Trip: Identifiable, Hashable {
    let id: String
    let city: String
    let region: String
    let start: Date
    let end: Date
    let photo: String
    let bookings: [Booking]

    var isPast: Bool { end < Date.now }
    /// Started but not yet over.
    var isInProgress: Bool { (start...end).contains(Date.now) }
    var datesText: String { Self.rangeText(start, end) }
    /// "3 bookings · Flight, Hotel stay, Dinner"
    var summary: String {
        let kinds = bookings.map(\.kind.title)
        var seen = Set<String>()
        let unique = kinds.filter { seen.insert($0).inserted }
        return "\(bookings.count) booking\(bookings.count == 1 ? "" : "s") · " + unique.joined(separator: ", ")
    }
    var total: Int { bookings.filter { !$0.cancelled }.reduce(0) { $0 + $1.total } }

    static func == (a: Trip, b: Trip) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    /// "Feb 13, 2027" · "Feb 12 – 15, 2027" · "Sep 30 – Oct 2, 2026"
    static func rangeText(_ start: Date, _ end: Date?) -> String {
        let cal = Calendar.current
        let monthDay = start.formatted(.dateTime.month(.abbreviated).day())
        let year = start.formatted(.dateTime.year())
        guard let end, !cal.isDate(start, inSameDayAs: end) else { return "\(monthDay), \(year)" }
        let endDay = cal.isDate(start, equalTo: end, toGranularity: .month)
            ? end.formatted(.dateTime.day())
            : end.formatted(.dateTime.month(.abbreviated).day())
        return "\(monthDay) – \(endDay), \(end.formatted(.dateTime.year()))"
    }
}

// MARK: - Sample trips

extension Sample {
    static func day(_ y: Int, _ m: Int, _ d: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour, minute: minute)) ?? .now
    }

    static let trips: [Trip] = [
        Trip(id: "nyc", city: "New York", region: "New York, United States",
             start: day(2027, 2, 12), end: day(2027, 2, 15), photo: "HotelModern", bookings: [
                Booking(id: "nyc-flight", kind: .flight, title: "UA 1458 · IAH → JFK",
                        detail: "Fri, Feb 12 · 8:05 AM · Economy Plus", start: day(2027, 2, 12, 8, 5),
                        confirmation: "UA-7QK2LM", total: 389,
                        facts: [("Flight", "UA 1458"), ("Route", "IAH → JFK"), ("Departs", "8:05 AM"), ("Seat", "14C")]),
                Booking(id: "nyc-hotel", kind: .hotel, title: "The Hudson Park Hotel",
                        detail: "3 nights · Deluxe King · 2 guests", start: day(2027, 2, 12, 15), end: day(2027, 2, 15, 11),
                        confirmation: "HP-5520913", total: 1_284, pointsUsed: 20_000, photo: "HotelModern",
                        facts: [("Room", "Deluxe King"), ("Check-in", "Feb 12 · 3:00 PM"), ("Check-out", "Feb 15 · 11:00 AM")]),
                Booking(id: "nyc-dinner", kind: .dining, title: "Osteria Lucca",
                        detail: "Sat, Feb 13 · 7:30 PM · party of 2", start: day(2027, 2, 13, 19, 30),
                        confirmation: "RSV-3MX81P", total: 50, photo: "DishCacioEPepe",
                        facts: [("Seating", "Dining room"), ("Deposit", "$50")]),
                Booking(id: "nyc-show", kind: .event, title: "Evening at the Philharmonic",
                        detail: "Sun, Feb 14 · 7:00 PM · 2 orchestra seats", start: day(2027, 2, 14, 19),
                        confirmation: "TKT-904221", total: 236,
                        facts: [("Seats", "Orchestra, row K 11–12"), ("Doors", "6:15 PM")])
             ]),
        Trip(id: "napa", city: "Napa Valley", region: "California, United States",
             start: day(2027, 4, 9), end: day(2027, 4, 11), photo: "HotelGarden", bookings: [
                Booking(id: "napa-car", kind: .car, title: "Midsize SUV · SFO pickup",
                        detail: "Apr 9 – 11 · Unlimited miles", start: day(2027, 4, 9, 10), end: day(2027, 4, 11, 16),
                        confirmation: "CR-55190Q", total: 214,
                        facts: [("Pick-up", "SFO · Apr 9, 10:00 AM"), ("Drop-off", "SFO · Apr 11, 4:00 PM")]),
                Booking(id: "napa-hotel", kind: .hotel, title: "Vineyard Terrace Inn",
                        detail: "2 nights · Garden Suite · 2 guests", start: day(2027, 4, 9, 15), end: day(2027, 4, 11, 11),
                        confirmation: "VT-2208731", total: 912, photo: "HotelGarden",
                        facts: [("Room", "Garden Suite"), ("Breakfast", "Included")]),
                Booking(id: "napa-tour", kind: .event, title: "Wine country tasting tour",
                        detail: "Sat, Apr 10 · 11:00 AM · 2 guests", start: day(2027, 4, 10, 11),
                        confirmation: "EXP-61733", total: 290, photo: "DishWhiteWine",
                        facts: [("Duration", "5 hours"), ("Pick-up", "Hotel lobby")])
             ]),
        Trip(id: "chicago", city: "Chicago", region: "Illinois, United States",
             start: day(2026, 10, 16), end: day(2026, 10, 18), photo: "HotelBayou", bookings: [
                Booking(id: "chi-flight", kind: .flight, title: "AA 2231 · IAH → ORD",
                        detail: "Fri, Oct 16 · 6:40 AM · Main Cabin", start: day(2026, 10, 16, 6, 40),
                        confirmation: "AA-K39XZE", total: 276,
                        facts: [("Flight", "AA 2231"), ("Route", "IAH → ORD"), ("Seat", "22A")]),
                Booking(id: "chi-hotel", kind: .hotel, title: "Lakeshore Grand",
                        detail: "2 nights · Lake View King", start: day(2026, 10, 16, 15), end: day(2026, 10, 18, 11),
                        confirmation: "LG-7730115", total: 648, pointsUsed: 12_000, photo: "HotelBayou",
                        facts: [("Room", "Lake View King")]),
                Booking(id: "chi-dinner", kind: .dining, title: "Lakefront Steakhouse",
                        detail: "Sat, Oct 17 · 8:00 PM · party of 4", start: day(2026, 10, 17, 20),
                        confirmation: "RSV-8QL20D", total: 160, photo: "DishRibeye",
                        facts: [("Seating", "Private room")])
             ]),
        Trip(id: "miami", city: "Miami", region: "Florida, United States",
             start: day(2026, 8, 7), end: day(2026, 8, 10), photo: "HotelSunset", bookings: [
                Booking(id: "mia-flight", kind: .flight, title: "DL 1872 · IAH → MIA",
                        detail: "Fri, Aug 7 · 9:15 AM · Comfort+", start: day(2026, 8, 7, 9, 15),
                        confirmation: "DL-H2W8NP", total: 318,
                        facts: [("Flight", "DL 1872"), ("Route", "IAH → MIA")]),
                Booking(id: "mia-hotel", kind: .hotel, title: "Sunset Terrace Miami",
                        detail: "3 nights · Ocean View Queen", start: day(2026, 8, 7, 15), end: day(2026, 8, 10, 11),
                        confirmation: "ST-4402987", total: 1_056, photo: "HotelSunset",
                        facts: [("Room", "Ocean View Queen")]),
                Booking(id: "mia-dinner", kind: .dining, title: "Sol y Mar Brickell",
                        detail: "Sat, Aug 8 · 7:00 PM · party of 2", start: day(2026, 8, 8, 19),
                        confirmation: "RSV-2BN77K", total: 30, cancelled: true, photo: "DishTacosAlPastor",
                        facts: [("Refund", "$30 deposit refunded")])
             ]),
        Trip(id: "seattle", city: "Seattle", region: "Washington, United States",
             start: day(2026, 5, 22), end: day(2026, 5, 24), photo: "HotelCaribbean", bookings: [
                Booking(id: "sea-hotel", kind: .hotel, title: "Pier 57 Waterfront Hotel",
                        detail: "2 nights · Harbor King", start: day(2026, 5, 22, 15), end: day(2026, 5, 24, 11),
                        confirmation: "PW-1193826", total: 702, photo: "HotelCaribbean",
                        facts: [("Room", "Harbor King")]),
                Booking(id: "sea-cruise", kind: .event, title: "Puget Sound harbor cruise",
                        detail: "Sat, May 23 · 2:00 PM · 2 guests", start: day(2026, 5, 23, 14),
                        confirmation: "EXP-30418", total: 98,
                        facts: [("Duration", "90 minutes"), ("Pier", "Pier 55")]),
                Booking(id: "sea-dinner", kind: .dining, title: "Harbor & Vine",
                        detail: "Sat, May 23 · 6:30 PM · party of 2", start: day(2026, 5, 23, 18, 30),
                        confirmation: "RSV-6TP03A", total: 60, photo: "DishOysters",
                        facts: [("Seating", "Patio")])
             ])
    ]

    static var upcomingTrips: [Trip] { trips.filter { !$0.isPast }.sorted { $0.start < $1.start } }
    static var pastTrips: [Trip] { trips.filter(\.isPast).sorted { $0.start > $1.start } }

    /// Bookings tab: each trip's reservations split by date. A booking is
    /// upcoming until it ends (cancelled ones follow their date), so a trip that
    /// is under way shows its remaining bookings under Upcoming and the ones
    /// already done under Past. Upcoming runs soonest first; Past newest first.
    static func bookingGroups(_ trips: [Trip], past: Bool, now: Date = .now) -> [BookingGroup] {
        trips.compactMap { trip -> BookingGroup? in
            let list = trip.bookings
                .filter { $0.isPast(at: now) == past }
                .sorted { $0.start < $1.start }
            return list.isEmpty ? nil : BookingGroup(trip: trip, bookings: list)
        }
        .sorted { past ? $0.trip.start > $1.trip.start : $0.trip.start < $1.trip.start }
    }

    static var allBookings: [Booking] { trips.flatMap(\.bookings) }
    static func trip(_ id: String) -> Trip? { trips.first { $0.id == id } }
    static func booking(_ id: String) -> Booking? { allBookings.first { $0.id == id } }
    static func trip(containing booking: Booking) -> Trip? { trips.first { $0.bookings.contains(booking) } }
}

/// One trip's bookings in the Upcoming or Past list.
struct BookingGroup: Identifiable {
    let trip: Trip
    let bookings: [Booking]
    var id: String { trip.id }
}
