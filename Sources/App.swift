import SwiftUI
import Combine

// MARK: - Navigation

/// Every destination in the app. Using one enum + a single NavigationStack path
/// keeps navigation type-safe and lets us jump back to Home in one line.
enum Route: Hashable {
    case fargo, inspire, itinerary, preferences
    case hotelSearch, hotelResults, hotelRooms(String), hotelGuest, hotelPay, hotelConfirm, hotelBooked
    case diningSearch, diningResults, diningRestaurant, diningMenu, diningGuest, diningPay, diningReview, diningConfirmed
    case trip(String), booking(String), pastTrips, bookings
    case events, eventDetail(String), eventSeats(String), eventCheckout, eventConfirmed(String), myTickets, eventTickets(String)
}

// MARK: - Shared state

/// App-wide state: rewards balance, the booking in progress and preferences.
/// Marked @MainActor because it drives UI.
@MainActor
final class AppState: ObservableObject {

    // Navigation: the selected root tab and the screens pushed over it
    @Published var tab: AppTab = .home
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

    // Events
    @Published var eventFilters = EventFilters()
    @Published var favoriteEvents: Set<String> = ["nba-hou-la"]
    /// Events with price-drop / on-sale alerts turned on.
    @Published var eventAlerts: Set<String> = []
    @Published var eventCart: EventCart?
    @Published var tickets: [Ticket] = Sample.seedTickets
    /// One-line confirmation toast ("Added to Apple Wallet").
    @Published var toast: String?
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

    func toggleFavorite(_ id: String) {
        if favoriteEvents.contains(id) { favoriteEvents.remove(id) } else { favoriteEvents.insert(id) }
    }
    func toggleAlert(_ e: Event) {
        if eventAlerts.contains(e.id) {
            eventAlerts.remove(e.id)
            show("Alerts off for \(e.title)")
        } else {
            eventAlerts.insert(e.id)
            show(e.isOnSale ? "We'll alert you if prices drop" : "We'll alert you when tickets go on sale")
        }
    }
    func show(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast == message { toast = nil }
        }
    }

    /// Completes the event purchase and returns the order number.
    func finishEventOrder() -> String {
        guard let cart = eventCart else { return "" }
        let order = "EV-\(Int.random(in: 50_000...99_999))"
        points -= cart.payment == .points ? cart.pointsUsed : 0
        tickets += cart.seats.enumerated().map { i, seat in
            Ticket(id: "\(order)-\(i)", eventID: cart.eventID, seat: seat, price: cart.price(of: seat), orderID: order)
        }
        return order
    }
    func goHome() { path.removeAll(); tab = .home }

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
                RootView()
                    .navigationDestination(for: Route.self) { route in
                        destination(for: route)
                    }
            }
            .environmentObject(app)
            .overlay(alignment: .top) { ToastView(message: app.toast) }
            .tint(Theme.button)   // nav bar & toolbar buttons (Back, Cancel, Done)
            .preferredColorScheme(.light)   // light mode only (per design brief)
        }
    }

    /// Maps a Route to its screen.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .fargo:            FargoView()
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
        case .bookings:         BookingsView()
        case .events:           EventsDiscoverView()
        case .eventDetail(let id): EventDetailView(eventID: id)
        case .eventSeats(let id):  SeatMapView(eventID: id)
        case .eventCheckout:    EventCheckoutView()
        case .eventConfirmed(let order): EventConfirmedView(orderID: order)
        case .myTickets:        MyTicketsView()
        case .eventTickets(let id): EventTicketsView(eventID: id)
        }
    }
}
