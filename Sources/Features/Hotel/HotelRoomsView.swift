import SwiftUI

/// Day 2 – Hotel details, room & rate selection. Sticky glass bar → Reserve.
struct HotelRoomsView: View {
    @EnvironmentObject var app: AppState
    let hotelID: String

    /// Look the hotel up by id (the route only carries a String).
    private var hotel: Hotel { Sample.hotels.first { $0.id == hotelID } ?? Sample.hotels[0] }

    var body: some View {
        Screen(title: hotel.name) {
            HotelPhoto(hotel: hotel, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("\(hotel.area) · ★ \(String(format: "%.1f", hotel.rating))").font(.ltBody)
                Text("\(Sample.dates) · \(Sample.guests) guests").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            SectionTitle(text: "Choose a room")
            ForEach(Sample.rooms) { r in
                Button { app.room = r } label: { roomRow(r) }.buttonStyle(.plain)
            }
        }
        .onAppear { app.hotel = hotel }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                VStack(alignment: .leading) {
                    Text(Money.usd(Money.total(nightly: hotel.dealPrice(app.room.nightly)))).font(.ltHeadline)
                    Text("total incl. taxes").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button { app.push(.hotelPay) } label: {
                    Text("Reserve").font(.ltHeadline).foregroundStyle(.white)
                        .padding(.horizontal, 28).frame(height: 48)
                        .background(Theme.red, in: Capsule())
                }
            }
        }
    }

    /// Radio-style room card.
    private func roomRow(_ r: Room) -> some View {
        let selected = app.room.id == r.id
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(selected ? Theme.red : Theme.textSecondary).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 4) {
                Text(r.name).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(r.bed).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text("Free cancellation until Dec 30").font(.ltCaptionBold).foregroundStyle(Theme.success)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(Money.usd(hotel.dealPrice(r.nightly))).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                if hotel.percentOff > 0 {
                    Text(Money.usd(r.nightly)).font(.ltCaption).strikethrough().foregroundStyle(Theme.textSecondary)
                }
                Text("per night").font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .card()
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .stroke(selected ? Theme.red : .clear, lineWidth: 1.5))
    }
}
