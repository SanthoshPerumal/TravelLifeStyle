import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Event cards

/// Large photo card for lists: full-width photo with date badge and favorite.
struct EventCard: View {
    @EnvironmentObject var app: AppState
    let event: Event
    var photoHeight: CGFloat = 210

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FillPhoto(name: event.photo, height: photoHeight)
                .overlay(alignment: .topLeading) { DateBadge(event: event).padding(12) }
                .overlay(alignment: .topTrailing) { FavoriteButton(eventID: event.id).padding(10) }
                .overlay(alignment: .bottomLeading) {
                    if !event.isOnSale {
                        PhotoTag(text: "On sale \(event.onSale!.formatted(.dateTime.month(.abbreviated).day()))", icon: "bell")
                            .padding(12)
                    } else if event.sellingFast {
                        PhotoTag(text: "Selling fast", icon: "flame").padding(12)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.ltHeadline).foregroundStyle(Theme.textPrimary).lineLimit(2)
                Text(event.subtitle).font(.ltCaption).foregroundStyle(Theme.textBody).lineLimit(1)
                HStack {
                    Text("\(event.dateText) · \(event.venue)").font(.ltCaption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(event.isOnSale ? "From \(Money.usd(event.priceFrom))" : "Coming soon")
                        .font(.ltCaptionBold).foregroundStyle(Theme.textPrimary).fixedSize()
                }
            }
            .padding(Theme.cardPadding)
        }
        .card()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(event.dateText), \(event.venue), \(event.isOnSale ? "from \(Money.usd(event.priceFrom))" : "not on sale yet")")
    }
}

/// "DEC / 12" badge on event photos.
struct DateBadge: View {
    let event: Event
    var body: some View {
        VStack(spacing: 0) {
            Text(event.dayBadge.month).font(.caption2.weight(.bold)).foregroundStyle(Theme.red)
            Text(event.dayBadge.day).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
        }
        .frame(width: 48, height: 52)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// Dark pill on a photo ("Selling fast").
struct PhotoTag: View {
    let text: String
    let icon: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold)).foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.photoBadge, in: Capsule())
    }
}

struct FavoriteButton: View {
    @EnvironmentObject var app: AppState
    let eventID: String
    var body: some View {
        let on = app.favoriteEvents.contains(eventID)
        Button { app.toggleFavorite(eventID) } label: {
            Image(systemName: on ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(on ? Theme.red : Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(on ? "Remove from favorites" : "Add to favorites")
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: String?
    var body: some View {
        if let message {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.ltCaptionBold).foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Theme.button, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - Tickets

/// QR code for a ticket barcode (rendered with Core Image).
struct QRCodeView: View {
    let payload: String
    var body: some View {
        if let image = Self.make(payload) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                .accessibilityLabel("Ticket barcode")
        }
    }
    static func make(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = CIContext().createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// Black "Add to Apple Wallet" / "Save to Google Wallet" style buttons.
struct WalletButton: View {
    enum Kind { case apple, google }
    let kind: Kind
    var added = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: added ? "checkmark" : (kind == .apple ? "wallet.pass.fill" : "g.circle.fill"))
                Text(added ? "Added to \(kind == .apple ? "Apple" : "Google") Wallet"
                           : kind == .apple ? "Add to Apple Wallet" : "Save to Google Wallet")
            }
            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(added)
    }
}

/// Seat map color legend.
struct TierLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legend(SeatTier.premium.color, "Premium")
            legend(SeatTier.lower.color, "Lower")
            legend(SeatTier.upper.color, "Upper")
            legend(Theme.hairline, "Taken")
        }
        .font(.caption).foregroundStyle(Theme.textBody)
    }
    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) { Circle().fill(c).frame(width: 10, height: 10); Text(t) }
    }
}
