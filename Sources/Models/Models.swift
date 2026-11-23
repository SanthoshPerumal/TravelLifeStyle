import Foundation

// MARK: - Models
// Plain value types. Sample data is below – in a real app it would come from a
// service layer (see README "Improvements").

struct Hotel: Identifiable, Hashable {
    let id: String
    let name: String
    let area: String
    let rating: Double
    let reviews: Int
    let nightly: Int          // starting nightly price in USD
    let freeCancel: Bool
    let scene: SceneKind
    let photo: String         // asset name (Unsplash photo, credited in the README)
    let percentOff: Int       // current offer; 0 = no discount

    /// Applies this hotel's current offer to a nightly rate.
    func dealPrice(_ nightly: Int) -> Int { nightly * (100 - percentOff) / 100 }
    /// Starting nightly price after the offer.
    var dealNightly: Int { dealPrice(nightly) }
}

struct Room: Identifiable, Hashable {
    let id: String
    let name: String
    let bed: String
    let nightly: Int          // USD per night
}

struct TimeSlot: Identifiable, Hashable {
    let id: String
    let time: String
    let tableSize: Int        // seats at the table
    let tablesLeft: Int
}

struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let cuisine: String
    let area: String
}

struct Suggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let scene: SceneKind
}

// MARK: - Sample data

enum Sample {
    /// Trip context shared by every screen.
    static let city = "Houston"
    static let dates = "Jan 1 – Jan 3, 2027"
    static let nights = 2
    static let guests = 2
    static let taxRate = 0.13
    /// Price change shown on the "reprice" alert (+$5 per night).
    static let repricePerNight = 5

    static let hotels: [Hotel] = [
        Hotel(id: "caribbean", name: "Caribbean Beach Hotel", area: "Galveston Bay", rating: 4.7, reviews: 1820, nightly: 250, freeCancel: true,  scene: .beach,  photo: "HotelCaribbean", percentOff: 20),
        Hotel(id: "bayou",     name: "Bayou City Suites",     area: "Downtown",      rating: 4.5, reviews: 960,  nightly: 189, freeCancel: true,  scene: .city,   photo: "HotelBayou",     percentOff: 10),
        Hotel(id: "garden",    name: "The Garden House",      area: "Montrose",      rating: 4.6, reviews: 540,  nightly: 215, freeCancel: false, scene: .garden, photo: "HotelGarden",    percentOff: 25),
        Hotel(id: "sunset",    name: "Sunset Terrace",        area: "Uptown",        rating: 4.4, reviews: 1210, nightly: 175, freeCancel: true,  scene: .sunset, photo: "HotelSunset",    percentOff: 30),
        Hotel(id: "modern",    name: "Modern Loft Hotel",     area: "Museum District", rating: 4.8, reviews: 320, nightly: 289, freeCancel: false, scene: .modern, photo: "HotelModern",    percentOff: 15)
    ]

    static let rooms: [Room] = [
        Room(id: "queen", name: "Standard Queen", bed: "1 Queen bed", nightly: 210),
        Room(id: "king",  name: "Deluxe King",    bed: "1 King bed",  nightly: 250),
        Room(id: "suite", name: "Junior Suite",   bed: "1 King bed + sofa", nightly: 340)
    ]

    static let restaurant = Restaurant(id: "trattoria", name: "Trattoria Verde", cuisine: "Italian", area: "Montrose")

    /// Sizes/tables match the design: a slot is SOLD OUT if party > tableSize.
    static let slots: [TimeSlot] = [
        TimeSlot(id: "t1", time: "6:00 PM", tableSize: 4, tablesLeft: 5),
        TimeSlot(id: "t2", time: "6:30 PM", tableSize: 6, tablesLeft: 4),
        TimeSlot(id: "t3", time: "7:00 PM", tableSize: 2, tablesLeft: 5),
        TimeSlot(id: "t4", time: "7:30 PM", tableSize: 4, tablesLeft: 3),
        TimeSlot(id: "t5", time: "8:00 PM", tableSize: 6, tablesLeft: 5),
        TimeSlot(id: "t6", time: "8:30 PM", tableSize: 2, tablesLeft: 2)
    ]

    static let hotelBrands  = ["Hyatt", "Marriott", "Hilton", "Four Seasons", "IHG"]
    static let airlines     = ["United", "Delta", "American", "ANA", "Southwest"]
    static let venues       = ["Trattoria Verde", "Harbor & Vine", "Sol y Mar"]
    static let cuisines     = ["Italian", "Japanese", "Mexican", "Seafood", "Steakhouse"]
    static let dietary      = ["Vegetarian", "Vegan", "Gluten-free", "Halal", "Nut allergy"]

    static let inspire: [[Suggestion]] = [
        [
            Suggestion(id: "i1", title: "Park Hyatt Tokyo", subtitle: "Shinjuku", detail: "$485 / night", scene: .modern),
            Suggestion(id: "i2", title: "Four Seasons Ravello", subtitle: "Amalfi Coast", detail: "$620 / night", scene: .sunset)
        ],
        [
            Suggestion(id: "i3", title: "Park Hyatt Kyoto", subtitle: "Higashiyama", detail: "$540 / night", scene: .garden),
            Suggestion(id: "i4", title: "Hotel Il Pellicano", subtitle: "Tuscany", detail: "$710 / night", scene: .beach)
        ]
    ]
}

// MARK: - Money helpers

enum Money {
    /// Whole-dollar total for N nights including taxes (matches the design: 250 → $565).
    static func total(nightly: Int) -> Int {
        Int((Double(nightly * Sample.nights) * (1 + Sample.taxRate)).rounded())
    }
    static func usd(_ v: Int) -> String { "$\(v.formatted())" }
    static func pts(_ v: Int) -> String { "\(v.formatted()) pts" }
}
