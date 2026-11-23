import SwiftUI

/// Hotel details, room & rate selection. Sticky glass bar → Reserve.
struct HotelRoomsView: View {
    @EnvironmentObject var app: AppState
    let hotelID: String

    /// Look the hotel up by id (the route only carries a String).
    private var hotel: Hotel { Sample.hotels.first { $0.id == hotelID } ?? Sample.hotels[0] }

    /// Room types that sleep the fullest room in the search.
    private func fits(_ r: Room) -> Bool { r.maxGuests >= app.search.maxGuestsPerRoom }
    private var anyRoomFits: Bool { Sample.rooms.contains(where: fits) }
    /// Rates this hotel offers (flexible only where free cancellation exists).
    private var rates: [RateOption] { hotel.freeCancel ? RateOption.allCases : [.nonRefundable] }

    /// Per-room nightly price for a room type and rate at this hotel.
    private func nightly(_ r: Room, _ rate: RateOption) -> Int { rate.price(hotel.dealPrice(r.nightly)) }

    var body: some View {
        Screen(title: hotel.name) {
            HotelPhoto(hotel: hotel, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("\(hotel.area) ·")
                    RatingView(rating: hotel.rating, reviews: hotel.reviews)
                }
                .font(.ltBody)
                Text("\(app.search.datesText) · \(app.search.nightsText)")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text(app.search.travelersText).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            if !hotel.amenityList.isEmpty {
                SectionTitle(text: "Amenities")
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                          alignment: .leading, spacing: 12) {
                    ForEach(hotel.amenityList) { a in
                        Label(a.title, systemImage: a.icon)
                            .font(.ltCaption)
                            .foregroundStyle(Theme.textPrimary)
                            .labelStyle(AmenityLabelStyle())
                    }
                }
                .padding(18).card()
            }

            SectionTitle(text: "Choose a room")
            if !anyRoomFits {
                Label("No room sleeps \(app.search.maxGuestsPerRoom) guests. Split your group across more rooms.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.ltBody).foregroundStyle(Theme.goldText)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.goldSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
            ForEach(Sample.rooms) { r in
                Button { app.room = r } label: { roomRow(r) }
                    .buttonStyle(.plain)
                    .disabled(!fits(r))
            }

            SectionTitle(text: "Choose a rate")
            ForEach(RateOption.allCases) { rate in
                Button { app.rate = rate } label: { rateRow(rate) }
                    .buttonStyle(.plain)
                    .disabled(!rates.contains(rate))
            }
        }
        .onAppear(perform: syncSelection)
        .onChange(of: app.search) { syncSelection() }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                VStack(alignment: .leading) {
                    Text(Money.usd(app.stayTotal(nightly: nightly(app.room, app.rate)))).font(.ltHeadline)
                    Text("\(app.search.nightsText), \(app.search.roomCount) room\(app.search.roomCount == 1 ? "" : "s") incl. taxes")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button { app.push(.hotelGuest) } label: {
                    Text("Reserve").font(.ltHeadline).foregroundStyle(.white)
                        .padding(.horizontal, 28).frame(height: 48)
                        .background(anyRoomFits ? Theme.red : Theme.red.opacity(0.35), in: Capsule())
                }
                .disabled(!anyRoomFits)
            }
        }
    }

    /// Keeps the chosen hotel, room and rate valid for this hotel and search.
    private func syncSelection() {
        app.hotel = hotel
        if !fits(app.room), let first = Sample.rooms.first(where: fits) { app.room = first }
        if !rates.contains(app.rate) { app.rate = rates[0] }
    }

    /// Radio-style room card.
    private func roomRow(_ r: Room) -> some View {
        let selected = app.room.id == r.id && fits(r)
        let price = nightly(r, rates.contains(app.rate) ? app.rate : rates[0])
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(selected ? Theme.red : Theme.textSecondary).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(r.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text("\(r.bed) · Sleeps \(r.maxGuests)").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                if !fits(r) {
                    Text("Too small for \(app.search.maxGuestsPerRoom) guests").font(.ltCaptionBold).foregroundStyle(Theme.goldText)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(Money.usd(price)).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                if price < r.nightly {
                    Text(Money.usd(r.nightly)).font(.ltCaption).strikethrough().foregroundStyle(Theme.textSecondary)
                }
                Text("per night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .card()
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .stroke(selected ? Theme.red : .clear, lineWidth: 1.5))
        .opacity(fits(r) ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func rateRow(_ rate: RateOption) -> some View {
        let offered = rates.contains(rate)
        let selected = offered && app.rate == rate
        let detail: String = switch rate {
        case .flexible: offered ? app.search.freeCancellationText : "Not offered by this hotel"
        case .nonRefundable: "Save 10% · no refund if you cancel"
        }
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(selected ? Theme.red : Theme.textSecondary).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.ltCaption)
                    .foregroundStyle(rate == .flexible && offered ? Theme.success : Theme.textSecondary)
            }
            Spacer()
            Text(Money.usd(nightly(app.room, rate))).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
        }
        .padding(16)
        .card()
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .stroke(selected ? Theme.red : .clear, lineWidth: 1.5))
        .opacity(offered ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct AmenityLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(Theme.icon).frame(width: 22)
            configuration.title
        }
    }
}
