import Foundation

// MARK: - Dining models
// Everything the "Reserve a table" flow needs: restaurants with menus, the
// search (where, when, party size), filters, time-slot availability and the
// guest's occasion / dietary notes.

enum Cuisine: String, CaseIterable, Identifiable, Hashable {
    case italian, japanese, mexican, seafood, steakhouse

    var id: String { rawValue }
    var title: String {
        switch self {
        case .italian:    return "Italian"
        case .japanese:   return "Japanese"
        case .mexican:    return "Mexican"
        case .seafood:    return "Seafood"
        case .steakhouse: return "Steakhouse"
        }
    }
}

/// What a restaurant offers (filters + details page).
enum DiningFeature: String, CaseIterable, Identifiable, Hashable {
    case outdoorSeating, fullBar, privateDining, waterView, liveMusic, kidFriendly, vegetarianOptions, valet

    var id: String { rawValue }
    var title: String {
        switch self {
        case .outdoorSeating:    return "Outdoor seating"
        case .fullBar:           return "Full bar"
        case .privateDining:     return "Private dining"
        case .waterView:         return "Waterfront views"
        case .liveMusic:         return "Live music"
        case .kidFriendly:       return "Kid friendly"
        case .vegetarianOptions: return "Vegetarian options"
        case .valet:             return "Valet parking"
        }
    }
    /// Short label for quick-filter chips.
    var chipTitle: String {
        switch self {
        case .outdoorSeating:    return "Outdoor"
        case .vegetarianOptions: return "Vegetarian"
        case .waterView:         return "Waterfront"
        default:                 return title
        }
    }
    var icon: String {
        switch self {
        case .outdoorSeating:    return "sun.max"
        case .fullBar:           return "wineglass"
        case .privateDining:     return "door.left.hand.closed"
        case .waterView:         return "water.waves"
        case .liveMusic:         return "music.note"
        case .kidFriendly:       return "figure.and.child.holdinghands"
        case .vegetarianOptions: return "leaf"
        case .valet:             return "car"
        }
    }
}

/// Where the party would like to sit.
enum Seating: String, CaseIterable, Identifiable, Hashable {
    case any, indoor, outdoor, bar, counter, privateRoom

    var id: String { rawValue }
    var title: String {
        switch self {
        case .any:         return "No preference"
        case .indoor:      return "Dining room"
        case .outdoor:     return "Patio"
        case .bar:         return "Bar"
        case .counter:     return "Chef's counter"
        case .privateRoom: return "Private room"
        }
    }
    var detail: String {
        switch self {
        case .any:         return "First available table"
        case .indoor:      return "Main dining room"
        case .outdoor:     return "Outdoor, weather permitting"
        case .bar:         return "High-top seats at the bar"
        case .counter:     return "Watch the chefs at work · up to 4"
        case .privateRoom: return "Groups of 6 or more"
        }
    }
    var icon: String {
        switch self {
        case .any:         return "checkmark.circle"
        case .indoor:      return "house"
        case .outdoor:     return "sun.max"
        case .bar:         return "wineglass"
        case .counter:     return "flame"
        case .privateRoom: return "door.left.hand.closed"
        }
    }
    /// Party sizes this seating can take.
    func fits(_ party: Int) -> Bool {
        switch self {
        case .bar:         return party <= 3
        case .counter:     return party <= 4
        case .privateRoom: return party >= 6
        default:           return true
        }
    }
}

enum Occasion: String, CaseIterable, Identifiable {
    case none = "None", birthday = "Birthday", anniversary = "Anniversary", date = "Date night",
         business = "Business meal", celebration = "Special celebration"
    var id: String { rawValue }
}

/// Dietary badges shown on menu items.
enum DietTag: String, CaseIterable, Identifiable, Hashable {
    case vegetarian, vegan, glutenFree, spicy

    var id: String { rawValue }
    var short: String {
        switch self {
        case .vegetarian: return "V"
        case .vegan:      return "VG"
        case .glutenFree: return "GF"
        case .spicy:      return "Spicy"
        }
    }
    var title: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan:      return "Vegan"
        case .glutenFree: return "Gluten-free"
        case .spicy:      return "Spicy"
        }
    }
    var icon: String {
        switch self {
        case .vegetarian: return "leaf"
        case .vegan:      return "leaf.fill"
        case .glutenFree: return "checkmark.seal"
        case .spicy:      return "flame"
        }
    }
}

enum Allergen: String, CaseIterable, Hashable {
    case dairy = "Dairy", gluten = "Gluten", egg = "Egg", fish = "Fish", shellfish = "Shellfish",
         soy = "Soy", nuts = "Tree nuts", sesame = "Sesame"
}

struct MenuItem: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let ingredients: [String]
    let price: Int
    let calories: Int
    var tags: [DietTag] = []
    var allergens: [Allergen] = []
    var popular = false
    /// Asset name (Unsplash photo, credited in the README).
    let photo: String
}

struct MenuSection: Identifiable, Hashable {
    let title: String
    let items: [MenuItem]
    var id: String { title }
}

struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let cuisine: Cuisine
    let area: String
    let address: String
    let rating: Double
    let reviews: Int
    /// 1–4 ($ – $$$$).
    let priceLevel: Int
    let photo: String
    let about: String
    /// First and last seating, in minutes after midnight.
    let firstSeating: Int
    let lastSeating: Int
    let features: [DiningFeature]
    let seating: [Seating]
    let depositPerGuest: Int
    let maxParty: Int
    let menu: [MenuSection]

    var priceText: String { String(repeating: "$", count: priceLevel) }
    var hoursText: String { "Open daily · \(DiningSearch.timeText(firstSeating)) – \(DiningSearch.timeText(lastSeating + 60))" }
    var popularItems: [MenuItem] { menu.flatMap(\.items).filter(\.popular) }
    var allItems: [MenuItem] { menu.flatMap(\.items) }
}

/// One bookable time at a restaurant on a given day.
struct TimeSlot: Identifiable, Hashable {
    /// Minutes after midnight.
    let minutes: Int
    let available: Bool
    /// Tables left at this time (shown when it's 1–2).
    let tablesLeft: Int

    var id: Int { minutes }
    var time: String { DiningSearch.timeText(minutes) }
}

/// Where, when and how many – the dining search.
struct DiningSearch: Equatable {
    var location: Destination
    var date: Date
    /// Preferred time, in minutes after midnight.
    var time: Int
    var party: Int

    static let maxParty = 12
    /// Times offered in the search form (5:00 PM – 10:00 PM, every 30 minutes).
    static let times = Array(stride(from: 17 * 60, through: 22 * 60, by: 30))

    var dateText: String { HotelSearch.dayText(date) }
    var timeText: String { Self.timeText(time) }
    var partyText: String { "\(party) guest\(party == 1 ? "" : "s")" }
    /// "Fri, Jan 1 · 7:00 PM · 2 guests"
    var summary: String { "\(dateText) · \(timeText) · \(partyText)" }

    static func timeText(_ minutes: Int) -> String {
        let h = (minutes / 60) % 24, m = minutes % 60
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, h < 12 ? "AM" : "PM")
    }

    /// Matches the sample trip: dinner on Jan 1, 2027 at 7 PM for two.
    static let initial: DiningSearch = {
        let date = Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1)) ?? .now
        return DiningSearch(location: Sample.destinations[0], date: date, time: 19 * 60, party: 2)
    }()
}

/// Filters on the restaurant results page.
struct DiningFilters: Equatable {
    var cuisines: Set<Cuisine> = []
    var features: Set<DiningFeature> = []
    /// Highest price level to show; nil = any.
    var maxPrice: Int?
    var minRating: Double?

    static let priceSteps = [2, 3, 4]
    static let ratingSteps = [4.5, 4.8]

    var activeCount: Int {
        cuisines.count + features.count + (maxPrice == nil ? 0 : 1) + (minRating == nil ? 0 : 1)
    }

    func matches(_ r: Restaurant) -> Bool {
        if !cuisines.isEmpty && !cuisines.contains(r.cuisine) { return false }
        if !features.isSubset(of: Set(r.features)) { return false }
        if let maxPrice, r.priceLevel > maxPrice { return false }
        if let minRating, r.rating < minRating { return false }
        return true
    }
}

/// Extra reservation details on top of the shared contact details.
struct DiningRequests: Equatable {
    var occasion: Occasion = .none
    var dietary: Set<String> = []
    var notes = ""

    static let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Nut allergy", "Shellfish allergy"]
}

// MARK: - Availability

extension Restaurant {
    /// Every seating time on a day with simulated availability for the party.
    /// Deterministic, so the same day always shows the same tables.
    func slots(on date: Date, party: Int) -> [TimeSlot] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let seed = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return stride(from: firstSeating, through: lastSeating, by: 30).enumerated().map { i, minutes in
            let roll = (seed * 7 + day * 13 + i * 29 + party * 3) % 11
            // Bigger parties find fewer tables; prime time (7–8 PM) fills up first.
            let primeTime = (19 * 60...20 * 60).contains(minutes)
            var open = roll > (party > 6 ? 5 : party > 4 ? 3 : 1)
            if primeTime && roll % 3 == 0 { open = false }
            if party > maxParty { open = false }
            return TimeSlot(minutes: minutes, available: open, tablesLeft: open ? roll % 5 + 1 : 0)
        }
    }

    /// Available slots closest to the preferred time (for result cards).
    func nearbySlots(_ search: DiningSearch, limit: Int = 5) -> [TimeSlot] {
        slots(on: search.date, party: search.party)
            .filter { $0.available && abs($0.minutes - search.time) <= 90 }
            .sorted { abs($0.minutes - search.time) < abs($1.minutes - search.time) }
            .prefix(limit)
            .sorted { $0.minutes < $1.minutes }
    }

    var seatingForSearch: [Seating] { [.any] + seating }
}

// MARK: - Sample restaurants & menus

extension Sample {
    static let restaurants: [Restaurant] = [trattoria, kuro, solYMar, harbor, prime]

    /// Kept for screens that show the default (trip) restaurant.
    static var restaurant: Restaurant { restaurants[0] }

    static func restaurants(for location: Destination) -> [Restaurant] {
        location.kind == .city || location.areas.isEmpty
            ? restaurants
            : restaurants.filter { location.areas.contains($0.area) }
    }

    static let trattoria = Restaurant(
        id: "trattoria", name: "Trattoria Verde", cuisine: .italian, area: "Montrose",
        address: "1402 Westheimer Rd, Houston, TX 77006", rating: 4.7, reviews: 1284, priceLevel: 3,
        photo: "RestaurantTrattoria",
        about: "Handmade pasta, wood-fired pizza and a 300-bottle Italian wine list in a candle-lit Montrose bungalow with a garden patio.",
        firstSeating: 17 * 60, lastSeating: 21 * 60 + 30,
        features: [.outdoorSeating, .fullBar, .vegetarianOptions, .privateDining],
        seating: [.indoor, .outdoor, .bar], depositPerGuest: 25, maxParty: 10,
        menu: [
            MenuSection(title: "Antipasti", items: [
                MenuItem(id: "burrata", name: "Burrata & Heirloom Tomato",
                         detail: "Creamy Puglian burrata over heirloom tomatoes with basil oil and 12-year balsamic.",
                         ingredients: ["Burrata", "Heirloom tomatoes", "Basil", "Aged balsamic", "Extra-virgin olive oil", "Sea salt"],
                         price: 16, calories: 420, tags: [.vegetarian, .glutenFree], allergens: [.dairy], popular: true, photo: "DishBurrata"),
                MenuItem(id: "arancini", name: "Saffron Arancini",
                         detail: "Crisp risotto balls with a molten mozzarella center, served with San Marzano marinara.",
                         ingredients: ["Arborio rice", "Saffron", "Mozzarella", "Peas", "Parmigiano", "Marinara"],
                         price: 13, calories: 560, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], photo: "DishArancini")
            ]),
            MenuSection(title: "Pasta & Pizza", items: [
                MenuItem(id: "cacio", name: "Cacio e Pepe",
                         detail: "Hand-rolled tonnarelli tossed tableside with Pecorino Romano and toasted black pepper.",
                         ingredients: ["Tonnarelli pasta", "Pecorino Romano", "Black pepper", "Butter"],
                         price: 22, calories: 780, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], popular: true, photo: "DishCacioEPepe"),
                MenuItem(id: "risotto", name: "Wild Mushroom Risotto",
                         detail: "Carnaroli rice with porcini and chanterelles, thyme and aged Parmigiano.",
                         ingredients: ["Carnaroli rice", "Porcini", "Chanterelles", "Thyme", "Parmigiano-Reggiano", "White wine"],
                         price: 26, calories: 690, tags: [.vegetarian, .glutenFree], allergens: [.dairy], photo: "DishRisotto"),
                MenuItem(id: "margherita", name: "Pizza Margherita",
                         detail: "Neapolitan crust from our wood-fired oven with San Marzano tomato and fior di latte.",
                         ingredients: ["00 flour dough", "San Marzano tomatoes", "Fior di latte", "Basil", "Olive oil"],
                         price: 18, calories: 880, tags: [.vegetarian], allergens: [.dairy, .gluten], popular: true, photo: "DishMargherita")
            ]),
            MenuSection(title: "Secondi", items: [
                MenuItem(id: "branzino", name: "Branzino al Forno",
                         detail: "Whole roasted Mediterranean sea bass with lemon, capers and shaved fennel salad.",
                         ingredients: ["Mediterranean sea bass", "Lemon", "Capers", "Fennel", "Parsley", "Olive oil"],
                         price: 36, calories: 610, tags: [.glutenFree], allergens: [.fish], photo: "DishBranzino")
            ]),
            MenuSection(title: "Dolci", items: [
                MenuItem(id: "tiramisu", name: "Tiramisu",
                         detail: "Espresso-soaked ladyfingers layered with mascarpone cream and Valrhona cocoa.",
                         ingredients: ["Mascarpone", "Espresso", "Savoiardi", "Cocoa", "Marsala"],
                         price: 12, calories: 470, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], popular: true, photo: "DishTiramisu"),
                MenuItem(id: "pannacotta", name: "Vanilla Panna Cotta",
                         detail: "Silky vanilla bean cream with a warm mixed-berry compote.",
                         ingredients: ["Cream", "Vanilla bean", "Strawberries", "Raspberries", "Honey"],
                         price: 11, calories: 380, tags: [.vegetarian, .glutenFree], allergens: [.dairy], photo: "DishPannaCotta")
            ]),
            MenuSection(title: "Drinks", items: [
                MenuItem(id: "aperol", name: "Aperol Spritz",
                         detail: "Aperol, Prosecco and a splash of soda with an orange wheel.",
                         ingredients: ["Aperol", "Prosecco", "Soda water", "Orange"],
                         price: 14, calories: 160, tags: [.vegan, .glutenFree], photo: "DishAperolSpritz")
            ])
        ])

    static let kuro = Restaurant(
        id: "kuro", name: "Kuro Omakase", cuisine: .japanese, area: "Downtown",
        address: "710 Main St, Houston, TX 77002", rating: 4.9, reviews: 612, priceLevel: 4,
        photo: "RestaurantKuro",
        about: "An intimate 14-seat counter serving Edomae-style sushi with fish flown in daily from Tokyo's Toyosu market.",
        firstSeating: 17 * 60 + 30, lastSeating: 21 * 60 + 30,
        features: [.fullBar, .privateDining, .valet],
        seating: [.counter, .indoor, .privateRoom], depositPerGuest: 50, maxParty: 8,
        menu: [
            MenuSection(title: "Small Plates", items: [
                MenuItem(id: "edamame", name: "Yuzu Salt Edamame",
                         detail: "Steamed young soybeans finished with yuzu kosho salt.",
                         ingredients: ["Edamame", "Yuzu kosho", "Flaky salt"],
                         price: 8, calories: 190, tags: [.vegan, .glutenFree], allergens: [.soy], photo: "DishEdamame"),
                MenuItem(id: "miso", name: "Red Miso Soup",
                         detail: "Dashi with aka miso, silken tofu, wakame and scallion.",
                         ingredients: ["Dashi", "Red miso", "Silken tofu", "Wakame", "Scallion"],
                         price: 7, calories: 90, allergens: [.soy, .fish], photo: "DishMisoSoup")
            ]),
            MenuSection(title: "Sushi & Sashimi", items: [
                MenuItem(id: "nigiri", name: "King Salmon Nigiri",
                         detail: "Two pieces of New Zealand king salmon over seasoned rice, lightly torched.",
                         ingredients: ["King salmon", "Sushi rice", "Rice vinegar", "Wasabi", "Nikiri soy"],
                         price: 14, calories: 140, tags: [.glutenFree], allergens: [.fish, .soy], popular: true, photo: "DishSalmonNigiri"),
                MenuItem(id: "sashimi", name: "Chef's Sashimi Moriawase",
                         detail: "Twelve slices of the day's best fish – bluefin, hamachi, madai and more.",
                         ingredients: ["Bluefin tuna", "Hamachi", "Madai", "Salmon", "Shiso", "Daikon"],
                         price: 38, calories: 320, tags: [.glutenFree], allergens: [.fish], popular: true, photo: "DishSashimi"),
                MenuItem(id: "dragon", name: "Spicy Salmon Roll",
                         detail: "Salmon, cucumber and avocado inside, topped with spicy mayo and tobiko.",
                         ingredients: ["Salmon", "Cucumber", "Avocado", "Spicy mayo", "Tobiko", "Sesame"],
                         price: 19, calories: 510, tags: [.spicy], allergens: [.fish, .egg, .sesame, .soy], photo: "DishDragonRoll")
            ]),
            MenuSection(title: "Hot Dishes", items: [
                MenuItem(id: "ramen", name: "Tonkotsu Ramen",
                         detail: "18-hour pork bone broth, chashu pork belly, ajitama egg and fresh noodles.",
                         ingredients: ["Pork bone broth", "Chashu pork", "Soft egg", "Ramen noodles", "Nori", "Scallion"],
                         price: 21, calories: 890, allergens: [.gluten, .egg, .soy, .sesame], popular: true, photo: "DishRamen")
            ]),
            MenuSection(title: "Dessert", items: [
                MenuItem(id: "matcha", name: "Matcha Soft Serve",
                         detail: "Uji matcha soft serve with kuromitsu syrup.",
                         ingredients: ["Uji matcha", "Milk", "Cream", "Kuromitsu"],
                         price: 9, calories: 280, tags: [.vegetarian, .glutenFree], allergens: [.dairy], photo: "DishMatchaIceCream"),
                MenuItem(id: "mochi", name: "Mochi Trio",
                         detail: "Strawberry, matcha and black sesame mochi.",
                         ingredients: ["Glutinous rice", "Strawberry", "Matcha", "Black sesame", "Red bean"],
                         price: 10, calories: 300, tags: [.vegetarian, .glutenFree], allergens: [.sesame], photo: "DishMochi")
            ])
        ])

    static let solYMar = Restaurant(
        id: "solymar", name: "Sol y Mar", cuisine: .mexican, area: "Museum District",
        address: "5115 Main St, Houston, TX 77004", rating: 4.6, reviews: 1940, priceLevel: 2,
        photo: "RestaurantSolYMar",
        about: "Colorful cantina with Oaxacan-inspired plates, tortillas pressed to order and mezcal flights on the patio.",
        firstSeating: 17 * 60, lastSeating: 22 * 60,
        features: [.outdoorSeating, .fullBar, .liveMusic, .kidFriendly, .vegetarianOptions],
        seating: [.indoor, .outdoor, .bar], depositPerGuest: 15, maxParty: 12,
        menu: [
            MenuSection(title: "Para Empezar", items: [
                MenuItem(id: "guac", name: "Guacamole & Totopos",
                         detail: "Avocado smashed to order with lime, serrano and cilantro, with warm tortilla chips.",
                         ingredients: ["Hass avocado", "Lime", "Serrano chile", "Cilantro", "White onion", "Corn tortilla chips"],
                         price: 12, calories: 540, tags: [.vegan, .glutenFree], popular: true, photo: "DishGuacamole"),
                MenuItem(id: "elote", name: "Elote Asado",
                         detail: "Charred street corn with chipotle crema, cotija and tajín.",
                         ingredients: ["Sweet corn", "Chipotle crema", "Cotija", "Tajín", "Lime"],
                         price: 8, calories: 310, tags: [.vegetarian, .glutenFree, .spicy], allergens: [.dairy], photo: "DishElote")
            ]),
            MenuSection(title: "Tacos & Platos", items: [
                MenuItem(id: "pastor", name: "Tacos al Pastor",
                         detail: "Three tacos of achiote-marinated pork from the trompo with roasted pineapple.",
                         ingredients: ["Pork shoulder", "Achiote", "Pineapple", "Corn tortillas", "Onion", "Salsa verde"],
                         price: 17, calories: 620, tags: [.glutenFree, .spicy], popular: true, photo: "DishTacosAlPastor"),
                MenuItem(id: "fishtaco", name: "Baja Fish Tacos",
                         detail: "Beer-battered Gulf red snapper, cabbage slaw and lime crema.",
                         ingredients: ["Red snapper", "Beer batter", "Cabbage slaw", "Lime crema", "Pico de gallo", "Flour tortillas"],
                         price: 18, calories: 690, allergens: [.fish, .gluten, .dairy], photo: "DishFishTacos"),
                MenuItem(id: "enchiladas", name: "Enchiladas Verdes",
                         detail: "Pulled chicken enchiladas baked in tomatillo salsa with Oaxaca cheese.",
                         ingredients: ["Chicken", "Corn tortillas", "Tomatillo salsa", "Oaxaca cheese", "Crema", "Cilantro"],
                         price: 19, calories: 760, tags: [.glutenFree], allergens: [.dairy], photo: "DishEnchiladas")
            ]),
            MenuSection(title: "Postres", items: [
                MenuItem(id: "churros", name: "Churros con Chocolate",
                         detail: "Cinnamon-sugar churros with Mexican hot-chocolate dip.",
                         ingredients: ["Choux dough", "Cinnamon", "Sugar", "Mexican chocolate"],
                         price: 9, calories: 520, tags: [.vegetarian], allergens: [.gluten, .egg, .dairy], popular: true, photo: "DishChurros"),
                MenuItem(id: "tresleches", name: "Pastel Tres Leches",
                         detail: "Sponge cake soaked in three milks with whipped cream and berries.",
                         ingredients: ["Sponge cake", "Evaporated milk", "Condensed milk", "Cream", "Raspberries"],
                         price: 10, calories: 480, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], photo: "DishTresLeches")
            ]),
            MenuSection(title: "Bebidas", items: [
                MenuItem(id: "margarita", name: "Classic Margarita",
                         detail: "Blanco tequila, Cointreau and fresh lime, salted rim.",
                         ingredients: ["Blanco tequila", "Cointreau", "Lime juice", "Agave", "Sea salt"],
                         price: 13, calories: 200, tags: [.vegan, .glutenFree], photo: "DishMargarita")
            ])
        ])

    static let harbor = Restaurant(
        id: "harbor", name: "Harbor & Vine", cuisine: .seafood, area: "Galveston Bay",
        address: "2000 Harborside Dr, Galveston, TX 77550", rating: 4.8, reviews: 873, priceLevel: 3,
        photo: "RestaurantHarbor",
        about: "Gulf seafood and a raw bar on a restored 1920s pier, with sunset views across Galveston Bay.",
        firstSeating: 17 * 60, lastSeating: 21 * 60 + 30,
        features: [.waterView, .outdoorSeating, .fullBar, .valet, .kidFriendly],
        seating: [.indoor, .outdoor, .bar], depositPerGuest: 30, maxParty: 10,
        menu: [
            MenuSection(title: "Raw Bar", items: [
                MenuItem(id: "oysters", name: "Gulf Oysters (half dozen)",
                         detail: "Freshly shucked on ice with mignonette, cocktail sauce and lemon.",
                         ingredients: ["Gulf oysters", "Shallot mignonette", "Cocktail sauce", "Lemon", "Horseradish"],
                         price: 24, calories: 120, tags: [.glutenFree], allergens: [.shellfish], popular: true, photo: "DishOysters"),
                MenuItem(id: "shrimp", name: "Jumbo Shrimp Cocktail",
                         detail: "Six poached Gulf shrimp with spicy cocktail sauce.",
                         ingredients: ["Gulf shrimp", "Cocktail sauce", "Horseradish", "Lemon"],
                         price: 18, calories: 210, tags: [.glutenFree], allergens: [.shellfish], photo: "DishShrimpCocktail")
            ]),
            MenuSection(title: "Starters", items: [
                MenuItem(id: "chowder", name: "New England Clam Chowder",
                         detail: "Creamy chowder with littleneck clams, smoked bacon and potato.",
                         ingredients: ["Littleneck clams", "Cream", "Potato", "Smoked bacon", "Celery", "Thyme"],
                         price: 12, calories: 430, allergens: [.shellfish, .dairy, .gluten], photo: "DishClamChowder")
            ]),
            MenuSection(title: "Mains", items: [
                MenuItem(id: "salmon", name: "Cedar-Grilled Salmon",
                         detail: "Atlantic salmon with lemon-herb butter, roasted potatoes and seasonal vegetables.",
                         ingredients: ["Atlantic salmon", "Lemon-herb butter", "Fingerling potatoes", "Carrots", "Broccolini"],
                         price: 32, calories: 720, tags: [.glutenFree], allergens: [.fish, .dairy], photo: "DishGrilledSalmon"),
                MenuItem(id: "scallops", name: "Seared Diver Scallops",
                         detail: "Pan-seared scallops over roasted red pepper purée with charred broccolini.",
                         ingredients: ["Diver scallops", "Red pepper purée", "Broccolini", "Brown butter", "Chili oil"],
                         price: 38, calories: 540, tags: [.glutenFree], allergens: [.shellfish, .dairy], popular: true, photo: "DishScallops"),
                MenuItem(id: "lobster", name: "Maine Lobster Roll",
                         detail: "Chilled lobster with lemon aioli on a toasted brioche roll, with fries.",
                         ingredients: ["Maine lobster", "Lemon aioli", "Brioche roll", "Chives", "Celery"],
                         price: 34, calories: 810, allergens: [.shellfish, .gluten, .egg, .dairy], photo: "DishLobsterRoll")
            ]),
            MenuSection(title: "Dessert", items: [
                MenuItem(id: "keylime", name: "Key Lime Pie",
                         detail: "Tart key lime custard in a graham cracker crust.",
                         ingredients: ["Key limes", "Condensed milk", "Egg yolk", "Graham crust", "Whipped cream"],
                         price: 11, calories: 450, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], photo: "DishKeyLimePie")
            ]),
            MenuSection(title: "Wine", items: [
                MenuItem(id: "wine", name: "Sancerre, Loire Valley",
                         detail: "Crisp Sauvignon Blanc with citrus and mineral notes. By the glass.",
                         ingredients: ["Sauvignon Blanc"],
                         price: 16, calories: 125, tags: [.vegan, .glutenFree], photo: "DishWhiteWine")
            ])
        ])

    static let prime = Restaurant(
        id: "prime", name: "Prime 1836", cuisine: .steakhouse, area: "Uptown",
        address: "5000 Westheimer Rd, Houston, TX 77056", rating: 4.7, reviews: 1102, priceLevel: 4,
        photo: "RestaurantPrime",
        about: "USDA Prime steaks dry-aged in house for 28 days, classic sides and a bourbon list of over 120 bottles.",
        firstSeating: 17 * 60, lastSeating: 22 * 60,
        features: [.privateDining, .fullBar, .valet],
        seating: [.indoor, .bar, .privateRoom], depositPerGuest: 40, maxParty: 12,
        menu: [
            MenuSection(title: "Starters", items: [
                MenuItem(id: "caesar", name: "Classic Caesar",
                         detail: "Romaine hearts, garlic croutons, white anchovy and shaved Parmigiano.",
                         ingredients: ["Romaine", "Caesar dressing", "Croutons", "White anchovy", "Parmigiano"],
                         price: 15, calories: 390, allergens: [.dairy, .gluten, .egg, .fish], photo: "DishCaesarSalad"),
                MenuItem(id: "tartare", name: "Ahi Tuna Tartare",
                         detail: "Sushi-grade ahi with avocado, citrus soy and crispy wontons.",
                         ingredients: ["Ahi tuna", "Avocado", "Citrus soy", "Sesame", "Wonton crisps"],
                         price: 21, calories: 330, tags: [.spicy], allergens: [.fish, .soy, .sesame, .gluten], photo: "DishTunaTartare")
            ]),
            MenuSection(title: "Steaks", items: [
                MenuItem(id: "filet", name: "Filet Mignon, 8 oz",
                         detail: "Center-cut tenderloin with crispy shallots and béarnaise.",
                         ingredients: ["USDA Prime tenderloin", "Béarnaise", "Crispy shallots", "Sea salt"],
                         price: 58, calories: 640, tags: [.glutenFree], allergens: [.dairy, .egg], popular: true, photo: "DishFiletMignon"),
                MenuItem(id: "ribeye", name: "Dry-Aged Ribeye, 16 oz",
                         detail: "28-day dry-aged bone-in ribeye with roasted garlic and grilled asparagus.",
                         ingredients: ["Dry-aged ribeye", "Roasted garlic", "Asparagus", "Rosemary", "Butter"],
                         price: 64, calories: 1180, tags: [.glutenFree], allergens: [.dairy], popular: true, photo: "DishRibeye")
            ]),
            MenuSection(title: "Sides", items: [
                MenuItem(id: "mash", name: "Whipped Yukon Potatoes",
                         detail: "Buttery whipped potatoes with chives.",
                         ingredients: ["Yukon Gold potatoes", "Butter", "Cream", "Chives"],
                         price: 12, calories: 420, tags: [.vegetarian, .glutenFree], allergens: [.dairy], photo: "DishMashedPotatoes")
            ]),
            MenuSection(title: "Dessert", items: [
                MenuItem(id: "lava", name: "Chocolate Lava Cake",
                         detail: "Warm dark-chocolate cake with a molten center and vanilla ice cream.",
                         ingredients: ["Dark chocolate", "Butter", "Eggs", "Flour", "Vanilla ice cream"],
                         price: 14, calories: 690, tags: [.vegetarian], allergens: [.dairy, .gluten, .egg], popular: true, photo: "DishLavaCake")
            ]),
            MenuSection(title: "Cocktails", items: [
                MenuItem(id: "oldfashioned", name: "Smoked Old Fashioned",
                         detail: "Texas bourbon, demerara and Angostura, smoked with cherrywood.",
                         ingredients: ["Bourbon", "Demerara syrup", "Angostura bitters", "Orange peel"],
                         price: 17, calories: 180, tags: [.vegan, .glutenFree], photo: "DishOldFashioned")
            ])
        ])
}
