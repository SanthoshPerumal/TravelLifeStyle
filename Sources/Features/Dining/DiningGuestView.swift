import SwiftUI

/// Day 3 – Guest details (prefilled from the profile) + optional requests.
struct DiningGuestView: View {
    @EnvironmentObject var app: AppState

    @State private var name = "Alex Morgan"
    @State private var email = "alex.morgan@example.com"
    @State private var phone = "(555) 010-2030"
    @State private var requests = ""

    var body: some View {
        Screen(title: "Guest details") {
            VStack(alignment: .leading, spacing: 4) {
                Text(Sample.restaurant.name).font(.ltHeadline)
                Text("01/01/2027 · \(app.slot?.time ?? "–") · party of \(app.party)")
                    .font(.ltBody).foregroundStyle(Theme.textBody)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(18).card()

            VStack(spacing: 0) {
                field("Name", $name)
                Divider()
                field("Email", $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                Divider()
                field("Phone", $phone).keyboardType(.phonePad)
            }
            .card()

            VStack(alignment: .leading, spacing: 8) {
                Text("Special requests / dietary notes").font(.ltCaptionBold).foregroundStyle(Theme.textSecondary)
                TextField("Optional", text: $requests, axis: .vertical).lineLimit(3...5)
            }
            .padding(18).card()
        }
        .safeAreaInset(edge: .bottom) {
            // Basic validation: name + email must not be empty.
            StickyBar {
                PillButton(title: "Continue",
                           enabled: !name.isEmpty && email.contains("@")) { app.push(.diningPay) }
            }
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label).font(.ltBody).foregroundStyle(Theme.textSecondary).frame(width: 70, alignment: .leading)
            TextField(label, text: text)
        }
        .padding(16)
    }
}
