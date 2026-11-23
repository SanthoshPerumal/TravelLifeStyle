import SwiftUI
import Combine

// MARK: - Navigation

/// Every destination in the app. Using one enum + a single NavigationStack path
/// keeps navigation type-safe and lets us jump back to Home in one line.
enum Route: Hashable {
    case concierge, inspire, itinerary, preferences
    case hotelSearch, hotelResults, hotelRooms(String), hotelGuest, hotelPay, hotelConfirm, hotelBooked
    case diningSearch, diningResults, diningRestaurant, diningMenu, diningGuest, diningPay, diningReview, diningConfirmed
    case trip(String), booking(String), pastTrips
}

// MARK: - Shared state

/// App-wide state: rewards balance, the booking in progress and preferences.
/// Marked @MainActor because it drives UI.
@MainActor
final class AppState: ObservableObject {

    // Navigation stack
    @Published var path: [Route] = []

    // Rewards
    @Published var points = 12_450

    // Hotel flow
    @Published var search = HotelSearch.initial
    @Published var filters = HotelFilters()
    @Published var hotel: Hotel = Sample.hotels[0]
    @Published var room: Room = Sample.rooms[1]           // Deluxe King
    @Published var rate: RateOption = .flexible
    @Published var guest = GuestDetails()
    @Published var hotelPointsUsed = 5_000
    @Published var hotelBooked = false

    // Dining flow
    @Published var dining = DiningSearch.initial
    @Published var diningFilters = DiningFilters()
    @Published var restaurant: Restaurant = Sample.restaurant
    @Published var slot: TimeSlot?
    @Published var seating: Seating = .any
    @Published var diningRequests = DiningRequests()
    @Published var diningPointsUsed = 0
    @Published var diningBooked = false

    // Preferences (auto-saved: simply published state)
    @Published var selected: Set<String> = ["Hyatt", "United", "Italian"]
    @Published var priceLevel = 2
    @Published var seatPreference = "Aisle"
    @Published var roomPreference = "High floor"

    // Derived values --------------------------------------------------------

    /// Selected room's nightly rate after the hotel's offer and the chosen rate.
    var roomNightly: Int { rate.price(hotel.dealPrice(room.nightly)) }
    /// Stay total (all nights and rooms, incl. taxes) for a per-room nightly rate.
    func stayTotal(nightly: Int) -> Int {
        Money.total(nightly: nightly, nights: search.nights, rooms: search.roomCount)
    }
    /// Hotel total after the offer, rate and the +$5/night reprice the user accepted.
    var hotelTotal: Int { stayTotal(nightly: roomNightly + Sample.repricePerNight) }
    /// Cash due after applying points (100 pts = $1).
    var hotelCash: Int { max(hotelTotal - hotelPointsUsed / Theme.pointsPerDollar, 0) }
    /// Guests at the table.
    var party: Int { dining.party }
    /// Refundable deposit that holds the table (credited to the final bill).
    var diningDeposit: Int { restaurant.depositPerGuest * dining.party }
    var diningCash: Int { max(diningDeposit - diningPointsUsed / Theme.pointsPerDollar, 0) }

    func toggle(_ key: String) {
        if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
    }

    func push(_ r: Route) { path.append(r) }
    func goHome() { path.removeAll() }

    /// Commit points when the user finishes a booking.
    func finishHotel() {
        guard !hotelBooked else { return }          // blocks repeat taps
        points -= hotelPointsUsed
        hotelBooked = true
    }
    func finishDining() {
        guard !diningBooked else { return }
        points -= diningPointsUsed
        diningBooked = true
    }
}

// MARK: - App entry

@main
struct LifestyleTravelApp: App {
    @StateObject private var app = AppState()

    init() {
        // Large page titles in the regular weight, like the Wells Fargo app.
        // The text-style font keeps Dynamic Type scaling.
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .largeTitle),
            .foregroundColor: UIColor(Theme.textPrimary)
        ]
        bar.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $app.path) {
                LandingView()
                    .navigationDestination(for: Route.self) { route in
                        destination(for: route)
                    }
            }
            .environmentObject(app)
            .tint(Theme.button)   // nav bar & toolbar buttons (Back, Cancel, Done)
            .preferredColorScheme(.light)   // light mode only (per design brief)
        }
    }

    /// Maps a Route to its screen.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .concierge:        ConciergeView()
        case .inspire:          InspireView()
        case .itinerary:        ItineraryView()
        case .preferences:      PreferencesView()
        case .hotelSearch:      HotelSearchView()
        case .hotelResults:     HotelResultsView()
        case .hotelRooms(let id): HotelRoomsView(hotelID: id)
        case .hotelGuest:       HotelGuestView()
        case .hotelPay:         HotelPayView()
        case .hotelConfirm:     HotelConfirmView()
        case .hotelBooked:      HotelBookedView()
        case .diningSearch:     DiningSearchView()
        case .diningResults:    DiningResultsView()
        case .diningRestaurant: DiningRestaurantView()
        case .diningMenu:       DiningMenuView()
        case .diningGuest:      DiningGuestView()
        case .diningPay:        DiningPayView()
        case .diningReview:     DiningReviewView()
        case .diningConfirmed:  DiningConfirmedView()
        case .trip(let id):     TripDetailView(tripID: id)
        case .booking(let id):  BookingDetailView(bookingID: id)
        case .pastTrips:        PastTripsView()
        }
    }
}
