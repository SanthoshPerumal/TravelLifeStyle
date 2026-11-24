import SwiftUI

/// Explore tab: ask Fargo, get trip ideas, and browse what to book.
struct ExploreView: View {
    @EnvironmentObject var app: AppState

    private struct Idea: Identifiable {
        let id: String; let subtitle: String; let photo: String; let route: Route
    }
    private let ideas = [
        Idea(id: "Live events", subtitle: "Concerts, games & shows", photo: "EventConcert", route: .events),
        Idea(id: "Dining", subtitle: "Reserve a table", photo: "RestaurantHarbor", route: .diningSearch),
        Idea(id: "Hotels", subtitle: "Stays & member offers", photo: "HotelSunset", route: .hotelSearch),
        Idea(id: "My tickets", subtitle: "Your event passes", photo: "EventTheater", route: .myTickets)
    ]

    var body: some View {
        Screen(title: "Explore") {
            // Fargo
            Button { app.push(.fargo) } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.title3).foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Theme.button, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ask Fargo").font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                        Text("Plan a trip, find a table or get ideas").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .buttonStyle(.plain)

            // Inspire me
            SectionTitle(text: "Get inspired")
            Button { app.push(.inspire) } label: {
                FillPhoto(name: "HotelGarden", height: 200)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Inspire me", systemImage: "sparkles").font(.ltHeadline)
                            Text("Trip ideas picked for your preferences").font(.ltCaption)
                        }
                        .foregroundStyle(.white)
                        .padding(Theme.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Inspire me. Trip ideas picked for your preferences")

            // Browse
            SectionTitle(text: "Things to do")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ideas) { idea in
                    Button { app.push(idea.route) } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            FillPhoto(name: idea.photo, height: 110)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(idea.id).font(.ltHeadline).foregroundStyle(Theme.textPrimary)
                                Text(idea.subtitle).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1).minimumScaleFactor(0.85)
                            }
                            .padding(12)
                        }
                        .card()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
