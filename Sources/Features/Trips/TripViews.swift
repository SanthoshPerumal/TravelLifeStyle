import SwiftUI

// MARK: - Shared rows

/// Trip summary row: photo, city, dates and what's booked.
struct TripCard: View {
    let trip: Trip
    var body: some View {
        HStack(spacing: 14) {
            FillPhoto(name: trip.photo, width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .saturation(trip.isPast ? 0.4 : 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.city).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                Text(trip.datesText).font(.ltCaption).foregroundStyle(Theme.textBody)
                Text(trip.summary).font(.ltCaption).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// One reservation: kind icon, title, details, date and status.
struct BookingRow: View {
    let booking: Booking
    var showsDate = true

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: booking.kind.icon)
                .font(.headline).foregroundStyle(Theme.icon)
                .frame(width: 44, height: 44)
                .background(Theme.background, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                    .strikethrough(booking.cancelled)
                Text(showsDate ? "\(booking.dateText) · \(booking.kind.title)" : booking.detail)
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                BookingStatusTag(status: booking.status).padding(.top, 2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .opacity(booking.status == .confirmed ? 1 : 0.85)
        .accessibilityElement(children: .combine)
    }
}

/// Confirmed (green) · Completed (grey) · Cancelled (gold).
struct BookingStatusTag: View {
    let status: BookingStatus
    var body: some View {
        let (fg, bg): (Color, Color) = switch status {
        case .confirmed: (Theme.success, Theme.success.opacity(0.12))
        case .completed: (Theme.textBody, Theme.background)
        case .cancelled: (Theme.goldText, Theme.goldSoft)
        }
        Text(status.title)
            .font(.ltCaptionBold)
            .foregroundStyle(fg)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(bg, in: Capsule())
            .fixedSize()
    }
}

// MARK: - Trip details

struct TripDetailView: View {
    @EnvironmentObject var app: AppState
    let tripID: String

    var body: some View {
        if let trip = Sample.trip(tripID) {
            Screen(title: trip.city) {
                FillPhoto(name: trip.photo, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.datesText).font(.ltHeadline)
                    Text(trip.region).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    Text(trip.isPast ? "Completed trip · \(Money.usd(trip.total)) spent"
                                     : "\(trip.bookings.count) bookings confirmed · \(Money.usd(trip.total))")
                        .font(.ltCaption).foregroundStyle(trip.isPast ? Theme.textSecondary : Theme.success)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

                SectionTitle(text: "Bookings")
                ForEach(trip.bookings) { b in
                    Button { app.push(.booking(b.id)) } label: { BookingRow(booking: b, showsDate: false) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Booking details

struct BookingDetailView: View {
    let bookingID: String

    var body: some View {
        if let b = Sample.booking(bookingID) {
            Screen(title: b.kind.title) {
                if let photo = b.photo {
                    FillPhoto(name: photo, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(b.title, systemImage: b.kind.icon).font(.ltHeadline)
                        Text(b.detail).font(.ltBody).foregroundStyle(Theme.textBody)
                    }
                    Spacer()
                    BookingStatusTag(status: b.status)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()

                VStack(spacing: 10) {
                    KeyValueRow(key: "Confirmation", value: b.confirmation)
                    KeyValueRow(key: "Date", value: b.dateText)
                    ForEach(Array(b.facts.enumerated()), id: \.offset) { _, f in
                        KeyValueRow(key: f.0, value: f.1)
                    }
                    if b.pointsUsed > 0 { KeyValueRow(key: "Points used", value: Money.pts(b.pointsUsed)) }
                    Divider()
                    KeyValueRow(key: b.cancelled ? "Refunded" : "Total paid", value: Money.usd(b.total), bold: true)
                }
                .padding(Theme.cardPadding).card()

                if let trip = Sample.trip(containing: b) {
                    Label("Part of your \(trip.city) trip · \(trip.datesText)", systemImage: "suitcase")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                        .labelStyle(IconLabelStyle())
                }
            }
        }
    }
}

// MARK: - Past trips

struct PastTripsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Screen(title: "Past trips") {
            ForEach(Sample.pastTrips) { t in
                Button { app.push(.trip(t.id)) } label: { TripCard(trip: t) }
                    .buttonStyle(.plain)
            }
        }
    }
}
