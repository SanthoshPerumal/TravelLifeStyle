import SwiftUI

/// Day 5 – AI "Inspire me": a suggested trip hero plus hotel/flight picks.
struct InspireView: View {
    @EnvironmentObject var app: AppState

    /// Flips between the two sample suggestion sets to simulate "refresh".
    @State private var setIndex = 0
    private var suggestions: [Suggestion] { Sample.inspire[setIndex % Sample.inspire.count] }

    var body: some View {
        Screen(title: "Inspire me") {
            // AI banner with refresh
            HStack {
                Label("Inspire me · AI", systemImage: "sparkles").font(.ltHeadline).foregroundStyle(Theme.red)
                Spacer()
                Button { withAnimation { setIndex += 1 } } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(Theme.red)
                }
            }
            .padding(18).background(Theme.redSoft.opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            // Suggested trip hero
            SectionTitle(text: "Suggested trip")
            VStack(alignment: .leading, spacing: 0) {
                SceneArt(kind: .garden).frame(height: 170)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kyoto 5-Night Escape").font(.ltTitle)
                    HStack { Badge(text: "Fav Brand"); Text("Park Hyatt Kyoto").font(.ltBody) }
                    HStack { Badge(text: "Fav Airline"); Text("ANA · SFO → KIX").font(.ltBody) }
                    Text("Package from $3,420").font(.ltHeadline).foregroundStyle(Theme.red)
                }
                .padding(18)
            }
            .card().clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            // Hotel picks
            SectionTitle(text: "Hotels you'll love")
            ForEach(suggestions) { s in suggestionRow(s) }

            // Flight picks
            SectionTitle(text: "Flights")
            flightRow("ANA", "SFO → KIX", "$980")
            flightRow("Delta", "JFK → NAP", "$1,120")
        }
    }

    private func suggestionRow(_ s: Suggestion) -> some View {
        HStack(spacing: 14) {
            SceneArt(kind: s.scene).frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(s.title).font(.ltHeadline)
                Text(s.subtitle).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text(s.detail).font(.ltBody).foregroundStyle(Theme.red)
            }
            Spacer()
        }
        .padding(14).card()
    }

    private func flightRow(_ airline: String, _ route: String, _ price: String) -> some View {
        HStack {
            Image(systemName: "airplane").foregroundStyle(Theme.red)
            VStack(alignment: .leading) {
                Text(airline).font(.ltHeadline)
                Text(route).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(price).font(.ltHeadline)
        }
        .padding(16).card()
    }
}
