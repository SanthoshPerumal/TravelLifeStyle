import SwiftUI

/// Horizontal card carousel with a page indicator below it, matching the
/// landing page's "Hotel offers": swipes settle on a card, the dots follow
/// the scroll, and tapping a dot scrolls to that card.
struct CardCarousel<Item: Identifiable, Content: View>: View where Item.ID: Sendable {
    let items: [Item]
    /// Fixed card width, used to work out which card is current.
    let itemWidth: CGFloat
    var spacing: CGFloat = 16
    /// VoiceOver name for one card, e.g. "Restaurant" → "Restaurant 2 of 5".
    var itemLabel = "Item"
    @ViewBuilder let content: (Item) -> Content

    @State private var position = ScrollPosition(idType: Item.ID.self)
    @State private var index = 0

    var body: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(items) { content($0) }
                }
                .scrollTargetLayout()
                .padding(.vertical, 12)   // room for the card shadows
            }
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition($position)
            // Current card: by offset, and the last one once scrolled to the end.
            .onScrollGeometryChange(for: Int.self) { geo in
                let maxX = geo.contentSize.width - geo.containerSize.width
                if geo.contentOffset.x >= maxX - 4 { return items.count - 1 }
                let step = itemWidth + spacing
                return min(max(Int((geo.contentOffset.x / step).rounded()), 0), items.count - 1)
            } action: { _, new in
                index = new
            }

            if items.count > 1 {
                PageIndicator(count: items.count, current: index, label: itemLabel) { i in
                    withAnimation { position.scrollTo(id: items[i].id, anchor: .leading) }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
