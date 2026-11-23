import SwiftUI

// MARK: - Card

/// Soft white card: large radius + two layered, very light shadows.
struct CardStyle: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
            .shadow(color: Color(hex: 0x14142B).opacity(0.05), radius: 15, y: 12)
    }
}

extension View {
    /// `.card()` – wrap any view in the standard soft card.
    func card(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(CardStyle(radius: radius))
    }
}

// MARK: - Screen scaffold

/// Every inner screen uses this so spacing, background and the large title match.
struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content() }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Buttons

/// Primary or secondary pill button (min height 52 → comfortable 44pt+ touch target).
/// Primary: solid dark fill, white text. Secondary: white fill, thin dark outline.
struct PillButton: View {
    enum Kind { case primary, secondary }

    let title: String
    var kind: Kind = .primary
    var enabled: Bool = true
    /// `false` sizes the button to its title (e.g. "Reserve" beside a price).
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ltHeadline)
                .foregroundStyle(kind == .primary ? Color.white : Theme.button)
                .padding(.horizontal, fullWidth ? 0 : 28)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
                .background(kind == .primary ? Theme.button : Color.white, in: Capsule())
                .overlay {
                    if kind == .secondary { Capsule().strokeBorder(Theme.button, lineWidth: 1) }
                }
                .opacity(enabled ? 1 : 0.35)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)   // disabled state doubles as form validation
    }
}

/// Sticky bottom action bar (Liquid Glass) – used for "Reserve", "Book now", etc.
struct StickyBar<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 14) { content() }
            .padding(14)
            .glass(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Chips & badges

/// Selectable chip used for filters, cuisines, brands, etc.
struct Chip: View {
    let title: String
    var selected: Bool = false
    var tint: Color = Theme.red
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? tint : Theme.textBody)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(selected ? tint.opacity(0.10) : Color.white, in: Capsule())
                .overlay(Capsule().stroke(selected ? tint : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Small gold label such as "Fav Brand".
struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.ltCaptionBold)
            .foregroundStyle(Theme.goldText)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Theme.goldSoft, in: Capsule())
    }
}

/// Title row above a group of cards.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text).font(.ltTitle).foregroundStyle(Theme.textPrimary).padding(.top, 8)
    }
}

/// Label + value row used in summaries and breakdowns.
struct KeyValueRow: View {
    let key: String
    let value: String
    var bold: Bool = false
    var body: some View {
        HStack {
            Text(key).foregroundStyle(Theme.textBody)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).fontWeight(bold ? .bold : .regular)
        }
        .font(.ltBody)
    }
}

// MARK: - Illustrations (no third-party photos)

enum SceneKind: String { case beach, city, garden, sunset, modern, restaurant }

/// Original gradient "photo" placeholders drawn with pure SwiftUI shapes.
/// Improvement idea: swap for `AsyncImage` once real image URLs exist.
struct SceneArt: View {
    let kind: SceneKind

    private var colors: [Color] {
        switch kind {
        case .beach:      return [Color(hex: 0x7FD1E8), Color(hex: 0xFCE9B8)]
        case .city:       return [Color(hex: 0x2E3A59), Color(hex: 0xE6A3B4)]
        case .garden:     return [Color(hex: 0xA8D5A2), Color(hex: 0xF3F0D0)]
        case .sunset:     return [Color(hex: 0xFF8A65), Color(hex: 0xFFD180)]
        case .modern:     return [Color(hex: 0x9FB3C8), Color(hex: 0xE8EEF4)]
        case .restaurant: return [Color(hex: 0x6B3E2E), Color(hex: 0xF2C48D)]
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            Circle().fill(.white.opacity(0.55)).frame(width: 46, height: 46)
                .offset(x: 50, y: -34).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // simple skyline / dunes silhouette
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.black.opacity(0.14))
                        .frame(width: 22, height: CGFloat([34, 52, 28, 64, 40, 30][i]))
                }
            }.padding(.bottom, 0)
        }
        .clipped()
    }
}

/// Round icon button (back / bell / search) styled as glass.
struct GlassIconButton: View {
    let systemName: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 44, height: 44)
                .glass(in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// A hotel's photo with its "% OFF" offer badge in the top-leading corner.
/// Callers set the corner shape (cards clip it, the details hero rounds it).
struct HotelPhoto: View {
    let hotel: Hotel
    var width: CGFloat? = nil
    let height: CGFloat
    /// Off for small thumbnails where the badge would cover the photo.
    var showBadge = true

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay { Image(hotel.photo).resizable().scaledToFill() }
            .clipped()
            .overlay(alignment: .topLeading) {
                if showBadge && hotel.percentOff > 0 {
                    Text("\(hotel.percentOff)% OFF")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.photoBadge, in: Capsule())
                        .padding(12)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Star rating used on every hotel surface: gold star, rating, optional review count.
/// Inherits the caller's font.
struct RatingView: View {
    let rating: Double
    var reviews: Int? = nil

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").foregroundStyle(Theme.gold).imageScale(.small)
            Text(String(format: "%.1f", rating)).foregroundStyle(Theme.textPrimary)
            if let reviews {
                Text("(\(reviews.formatted()))").foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "Rated %.1f", rating) + (reviews.map { ", \($0) reviews" } ?? ""))
    }
}

/// Carousel page indicator: one dot per item, the current one drawn as a
/// wider capsule. Tapping a dot jumps to that item.
struct PageIndicator: View {
    let count: Int
    let current: Int
    var onSelect: (Int) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Theme.textPrimary : Theme.textSecondary.opacity(0.35))
                    .frame(width: i == current ? 18 : 7, height: 7)
                    .padding(.vertical, 8)                 // larger tap target
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(i) }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel("Offer \(current + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if current < count - 1 { onSelect(current + 1) }
            case .decrement: if current > 0 { onSelect(current - 1) }
            @unknown default: break
            }
        }
    }
}
