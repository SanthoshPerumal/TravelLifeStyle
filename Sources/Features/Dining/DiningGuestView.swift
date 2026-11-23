import SwiftUI

/// Reservation contact details (shared with hotel bookings), occasion,
/// dietary needs and requests. Validated before payment.
struct DiningGuestView: View {
    @EnvironmentObject var app: AppState

    private enum Field: Hashable { case first, last, email, phone, notes }
    @FocusState private var focus: Field?

    var body: some View {
        Screen(title: "Guest details") {
            DiningSummary()

            VStack(alignment: .leading, spacing: 14) {
                Text("Reservation name").font(.ltHeadline)
                Text("We'll send your confirmation and a reminder the day before.")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)

                HStack(spacing: 12) {
                    FormField(title: "First name", text: $app.guest.firstName,
                              error: app.guest.firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "Required" : nil,
                              contentType: .givenName, focus: $focus, field: .first)
                        .submitLabel(.next).onSubmit { focus = .last }
                    FormField(title: "Last name", text: $app.guest.lastName,
                              error: app.guest.lastName.trimmingCharacters(in: .whitespaces).isEmpty ? "Required" : nil,
                              contentType: .familyName, focus: $focus, field: .last)
                        .submitLabel(.next).onSubmit { focus = .email }
                }
                FormField(title: "Email", text: $app.guest.email,
                          error: app.guest.emailValid ? nil : "Enter a valid email for your confirmation",
                          contentType: .emailAddress, keyboard: .emailAddress, focus: $focus, field: .email)
                    .submitLabel(.next).onSubmit { focus = .phone }
                FormField(title: "Mobile phone (optional)", text: $app.guest.phone,
                          error: app.guest.phoneValid ? nil : "Enter at least 10 digits",
                          contentType: .telephoneNumber, keyboard: .phonePad, focus: $focus, field: .phone)
            }
            .padding(Theme.cardPadding).card()

            VStack(alignment: .leading, spacing: 14) {
                Text("Occasion & requests").font(.ltHeadline)
                HStack {
                    Text("Occasion").font(.ltBody).foregroundStyle(Theme.textBody)
                    Spacer()
                    Picker("Occasion", selection: $app.diningRequests.occasion) {
                        ForEach(Occasion.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textPrimary)
                }
                Divider()
                Text("Dietary needs").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                FlowRow(spacing: 8) {
                    ForEach(DiningRequests.dietaryOptions, id: \.self) { d in
                        Chip(title: d, selected: app.diningRequests.dietary.contains(d)) {
                            if app.diningRequests.dietary.contains(d) { app.diningRequests.dietary.remove(d) }
                            else { app.diningRequests.dietary.insert(d) }
                        }
                    }
                }
                FormField(title: "Special requests (optional)", text: $app.diningRequests.notes, axis: .vertical,
                          focus: $focus, field: .notes)
                Text("High chair, quiet table, cake for a birthday… Requests aren't guaranteed.")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.cardPadding).card()
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyBar {
                PillButton(title: "Continue to payment", enabled: app.guest.isValid) {
                    focus = nil
                    app.push(.diningPay)
                }
            }
        }
    }
}
