import SwiftUI

/// Day 1 – Concierge chat. Scripted replies (no backend) with tappable picks.
struct ConciergeView: View {
    @EnvironmentObject var app: AppState

    private struct Message: Identifiable {
        let id = UUID()
        let fromUser: Bool
        let text: String
        var route: Route? = nil        // optional "pick" the assistant links to
        var routeLabel: String? = nil
    }

    @State private var messages: [Message] = [
        Message(fromUser: false, text: "Hi Alex! I can help you find a hotel or a table. What are you planning?")
    ]
    @State private var input = ""
    private let prompts = ["Hotel in Houston", "Dinner for 4", "Inspire me"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { m in bubble(m) }
                }
                .padding(Theme.screenPadding)
            }
            // Quick prompts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { ForEach(prompts, id: \.self) { p in Chip(title: p) { send(p) } } }
                    .padding(.horizontal, Theme.screenPadding)
            }
            // Input bar (glass control layer)
            HStack {
                TextField("Message Concierge", text: $input).padding(.leading, 6)
                    .submitLabel(.send).onSubmit { send(input) }
                Button { send(input) } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title).foregroundStyle(Theme.red)
                }
            }
            .padding(10).glass(in: Capsule()).padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Concierge")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func bubble(_ m: Message) -> some View {
        HStack {
            if m.fromUser { Spacer(minLength: 50) }
            VStack(alignment: .leading, spacing: 10) {
                Text(m.text).font(.ltBody).foregroundStyle(m.fromUser ? .white : Theme.textPrimary)
                if let r = m.route, let label = m.routeLabel {
                    Button { app.push(r) } label: {
                        Text(label).font(.ltCaptionBold).foregroundStyle(Theme.red)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Theme.redSoft, in: Capsule())
                    }
                }
            }
            .padding(14)
            .background(m.fromUser ? Theme.red : Color.white,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !m.fromUser { Spacer(minLength: 50) }
        }
    }

    /// Adds the user's message and a canned assistant reply.
    private func send(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        messages.append(Message(fromUser: true, text: t))
        input = ""
        let lower = t.lowercased()
        if lower.contains("hotel") {
            messages.append(Message(fromUser: false, text: "Great pick: Caribbean Beach Hotel is free to cancel.",
                                    route: .hotelRooms("caribbean"), routeLabel: "View Caribbean Beach Hotel"))
        } else if lower.contains("dinner") || lower.contains("table") {
            messages.append(Message(fromUser: false, text: "Trattoria Verde has tables tonight.",
                                    route: .diningRestaurant, routeLabel: "Reserve Trattoria Verde"))
        } else if lower.contains("inspire") {
            messages.append(Message(fromUser: false, text: "Here are trips picked from your preferences.",
                                    route: .inspire, routeLabel: "Inspire me"))
        } else {
            messages.append(Message(fromUser: false, text: "I can help with hotels and dining right now."))
        }
    }
}
