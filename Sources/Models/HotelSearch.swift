import Foundation

// MARK: - Hotel search models
// Everything the hotel flow needs beyond the base `Hotel` / `Room` types:
// what the user searched for, filters, rate choice and guest details.

/// A place the user can search hotels in.
struct Destination: Identifiable, Hashable {
    enum Kind { case city, neighborhood, landmark, airport, custom }

    let id: String
    let name: String
    let detail: String
    let kind: Kind
    /// Hotel areas (`Hotel.area`) that count as "in or near" this destination.
    let areas: [String]

    var icon: String {
        switch self.kind {
        case .city:         return "building.2"
        case .neighborhood: return "mappin.circle"
        case .landmark:     return "star"
        case .airport:      return "airplane"
        case .custom:       return "magnifyingglass"
        }
    }

    /// A free-text search that doesn't match a known place.
    static func custom(_ text: String) -> Destination {
        Destination(id: "custom-\(text.lowercased())", name: text, detail: "Search", kind: .custom, areas: [])
    }
}

/// Guests staying in one room.
struct RoomOccupancy: Identifiable, Hashable {
    let id = UUID()
    var adults = 2
    /// One entry per child; the value is the child's age (0 = under 1).
    var childAges: [Int] = []

    var guests: Int { adults + childAges.count }
}

/// What the user is searching for: where, when, and who.
struct HotelSearch: Equatable {
    var destination: Destination?
    var checkIn: Date
    var checkOut: Date
    var rooms: [RoomOccupancy]

    static let maxRooms = 5
    static let maxNights = 30

    var nights: Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: checkIn), to: cal.startOfDay(for: checkOut)).day ?? 1
        return max(days, 1)
    }
    var roomCount: Int { rooms.count }
    var travelers: Int { rooms.reduce(0) { $0 + $1.guests } }
    /// The fullest room decides which room types fit.
    var maxGuestsPerRoom: Int { rooms.map(\.guests).max() ?? 1 }

    /// "Fri, Jan 1 – Sun, Jan 3"
    var datesText: String { "\(Self.dayText(checkIn)) – \(Self.dayText(checkOut))" }
    /// "2 travelers, 1 room"
    var travelersText: String {
        "\(travelers) traveler\(travelers == 1 ? "" : "s"), \(roomCount) room\(roomCount == 1 ? "" : "s")"
    }
    var nightsText: String { "\(nights) night\(nights == 1 ? "" : "s")" }

    /// Free cancellation ends two days before check-in.
    var freeCancellationText: String {
        let date = Calendar.current.date(byAdding: .day, value: -2, to: checkIn) ?? checkIn
        return "Free cancellation until \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    static func dayText(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// Matches the sample trip: Jan 1 – Jan 3, 2027, one room for two adults.
    static let initial: HotelSearch = {
        let cal = Calendar.current
        let checkIn = cal.date(from: DateComponents(year: 2027, month: 1, day: 1)) ?? .now
        let checkOut = cal.date(byAdding: .day, value: 2, to: checkIn) ?? .now
        return HotelSearch(destination: nil, checkIn: checkIn, checkOut: checkOut, rooms: [RoomOccupancy()])
    }()
}

/// Hotel amenities, used for filters and the hotel details page.
enum Amenity: String, CaseIterable, Identifiable, Hashable {
    case breakfast, freeParking, petFriendly, pool, wifi, gym, spa, airportShuttle, evCharging, accessible

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast:      return "Breakfast included"
        case .freeParking:    return "Free parking"
        case .petFriendly:    return "Pet friendly"
        case .pool:           return "Pool"
        case .wifi:           return "Free Wi-Fi"
        case .gym:            return "Fitness center"
        case .spa:            return "Spa"
        case .airportShuttle: return "Airport shuttle"
        case .evCharging:     return "EV charging"
        case .accessible:     return "Accessible rooms"
        }
    }

    /// Short label for filter chips.
    var chipTitle: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .freeParking: return "Parking"
        case .accessible: return "Accessible"
        default: return title
        }
    }

    var icon: String {
        switch self {
        case .breakfast:      return "cup.and.saucer"
        case .freeParking:    return "parkingsign"
        case .petFriendly:    return "pawprint"
        case .pool:           return "figure.pool.swim"
        case .wifi:           return "wifi"
        case .gym:            return "dumbbell"
        case .spa:            return "leaf"
        case .airportShuttle: return "bus"
        case .evCharging:     return "bolt.car"
        case .accessible:     return "figure.roll"
        }
    }
}

/// Filters on the hotel results page.
struct HotelFilters: Equatable {
    var amenities: Set<Amenity> = []
    var freeCancellation = false
    /// Highest deal price per night to show; nil = any price.
    var maxNightly: Int?
    /// Lowest guest rating to show; nil = any rating.
    var minRating: Double?

    static let priceSteps = [150, 200, 250]
    static let ratingSteps = [4.0, 4.5]

    var activeCount: Int {
        amenities.count + (freeCancellation ? 1 : 0) + (maxNightly == nil ? 0 : 1) + (minRating == nil ? 0 : 1)
    }

    func matches(_ hotel: Hotel) -> Bool {
        if freeCancellation && !hotel.freeCancel { return false }
        if !amenities.isSubset(of: hotel.amenities) { return false }
        if let maxNightly, hotel.dealNightly > maxNightly { return false }
        if let minRating, hotel.rating < minRating { return false }
        return true
    }
}

/// How the user pays for the room: flexible or a cheaper non-refundable rate.
enum RateOption: String, CaseIterable, Identifiable {
    case flexible, nonRefundable

    var id: String { rawValue }
    var title: String { self == .flexible ? "Free cancellation" : "Non-refundable" }

    /// Non-refundable saves 10%.
    func price(_ nightly: Int) -> Int { self == .nonRefundable ? nightly * 90 / 100 : nightly }
}

/// The primary guest on the reservation.
struct GuestDetails: Equatable {
    var firstName = "Alex"
    var lastName = "Morgan"
    var email = "alex.morgan@example.com"
    var phone = ""
    var arrival = "Not sure"
    var requests = ""

    static let arrivalOptions = ["Not sure", "Before 3 PM", "3 – 6 PM", "6 – 9 PM", "After 9 PM"]

    var fullName: String { "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))" }

    var emailValid: Bool {
        email.trimmingCharacters(in: .whitespaces)
            .wholeMatch(of: /[^@\s]+@[^@\s]+\.[A-Za-z]{2,}/) != nil
    }
    /// Optional, but if given it needs at least 10 digits.
    var phoneValid: Bool { phone.isEmpty || phone.filter(\.isNumber).count >= 10 }

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        emailValid && phoneValid
    }
}

// MARK: - Sample data for search

extension Sample {
    static let houstonAreas = ["Galveston Bay", "Downtown", "Montrose", "Uptown", "Museum District"]

    static let destinations: [Destination] = [
        Destination(id: "houston", name: "Houston", detail: "Texas, United States", kind: .city, areas: houstonAreas),
        Destination(id: "downtown", name: "Downtown", detail: "Houston, Texas", kind: .neighborhood, areas: ["Downtown"]),
        Destination(id: "museum", name: "Museum District", detail: "Houston, Texas", kind: .neighborhood, areas: ["Museum District"]),
        Destination(id: "montrose", name: "Montrose", detail: "Houston, Texas", kind: .neighborhood, areas: ["Montrose"]),
        Destination(id: "uptown", name: "Uptown", detail: "Houston, Texas", kind: .neighborhood, areas: ["Uptown"]),
        Destination(id: "galveston", name: "Galveston Bay", detail: "Houston area, Texas", kind: .neighborhood, areas: ["Galveston Bay"]),
        Destination(id: "mfah", name: "Museum of Fine Arts", detail: "Museum District, Houston", kind: .landmark, areas: ["Museum District", "Montrose"]),
        Destination(id: "space", name: "Space Center Houston", detail: "Clear Lake, Houston", kind: .landmark, areas: ["Galveston Bay"]),
        Destination(id: "nrg", name: "NRG Stadium", detail: "Houston, Texas", kind: .landmark, areas: ["Museum District", "Uptown"]),
        Destination(id: "galleria", name: "The Galleria", detail: "Uptown, Houston", kind: .landmark, areas: ["Uptown"]),
        Destination(id: "iah", name: "George Bush Intercontinental (IAH)", detail: "Airport · Houston", kind: .airport, areas: ["Downtown", "Uptown"])
    ]

    static let hotelAmenities: [String: Set<Amenity>] = [
        "caribbean": [.pool, .breakfast, .wifi, .spa, .freeParking, .accessible],
        "bayou":     [.wifi, .gym, .petFriendly, .airportShuttle, .accessible],
        "garden":    [.breakfast, .wifi, .petFriendly, .freeParking],
        "sunset":    [.pool, .wifi, .gym, .freeParking, .evCharging],
        "modern":    [.wifi, .gym, .spa, .petFriendly, .evCharging, .accessible]
    ]

    /// Hotels for a search, before filters.
    static func hotels(for destination: Destination?) -> [Hotel] {
        guard let destination else { return hotels }
        return hotels.filter { destination.areas.contains($0.area) }
    }
}

extension Hotel {
    var amenities: Set<Amenity> { Sample.hotelAmenities[id] ?? [] }
    /// Amenities in a stable display order.
    var amenityList: [Amenity] { Amenity.allCases.filter(amenities.contains) }
}

extension Room {
    /// Most guests (adults + children) the room sleeps.
    var maxGuests: Int { id == "suite" ? 4 : 2 }
}
