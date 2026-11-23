import SwiftUI

/// Reservation: who is staying, contact details and requests. Validated before payment.
struct HotelGuestView: View {
    @EnvironmentObject var app: AppState

    private enum Field: Hashable { case first, last, email, phone, requests }
    @FocusState private var focus: Field?

    var body: some View {
        Screen(title: "Guest details") {
            StaySummary()

            VStack(alignment: .leading, spacing: 14) {
                Text("Primary guest").font(.ltHeadline)
                Text(app.search.roomCount == 2 ? "This guest checks in for both rooms."
                     : app.search.roomCount > 2 ? "This guest checks in for all \(app.search.roomCount) rooms."
                     : "The name must match the ID shown at check-in.")
                    .font(.ltCaption).foregroundStyle(Theme.textSecondary)

                HStack(spacing: 12) {
                    FormField(title: "First name", text: $app.guest.firstName,
                              error: app.guest.firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "Required" : nil,
                              contentType: .givenName, focus: $focus, field: .first)
                        .submitLabel(.next)
                        .onSubmit { focus = .last }
                    FormField(title: "Last name", text: $app.guest.lastName,
                              error: app.guest.lastName.trimmingCharacters(in: .whitespaces).isEmpty ? "Required" : nil,
                              contentType: .familyName, focus: $focus, field: .last)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }
                }
                FormField(title: "Email", text: $app.guest.email,
                          error: app.guest.emailValid ? nil : "Enter a valid email for your confirmation",
                          contentType: .emailAddress, keyboard: .emailAddress, focus: $focus, field: .email)
                    .submitLabel(.next)
                    .onSubmit { focus = .phone }
                FormField(title: "Mobile phone (optional)", text: $app.guest.phone,
                          error: app.guest.phoneValid ? nil : "Enter at least 10 digits",
                          contentType: .telephoneNumber, keyboard: .phonePad, focus: $focus, field: .phone)
            }
            .padding(Theme.cardPadding).card()

            VStack(alignment: .leading, spacing: 14) {
                Text("Arrival & requests").font(.ltHeadline)
                HStack {
                    Text("Estimated arrival").font(.ltBody).foregroundStyle(Theme.textBody)
                    Spacer()
                    Picker("Estimated arrival", selection: $app.guest.arrival) {
                        ForEach(GuestDetails.arrivalOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textPrimary)
                }
                FormField(title: "Special requests (optional)", text: $app.guest.requests, axis: .vertical,
                          focus: $focus, field: .requests)
                Text("Requests aren't guaranteed and depend on availability.")
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
                    app.push(.hotelPay)
                }
            }
        }
    }
}

/// Hotel, room, rate, dates and travelers – shown at the top of checkout screens.
struct StaySummary: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            HotelPhoto(hotel: app.hotel, width: 72, height: 72, showBadge: false)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(app.hotel.name).font(.ltHeadline)
                Text("\(app.room.name) · \(app.rate.title)").font(.ltCaption).foregroundStyle(Theme.textBody)
                Text("\(app.search.datesText) · \(app.search.nightsText)").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                Text(app.search.travelersText).font(.ltCaption).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16).card()
        .accessibilityElement(children: .combine)
    }
}

/// Labelled text field with an inline validation message.
struct FormField<Field: Hashable>: View {
    let title: String
    @Binding var text: String
    var error: String? = nil
    var axis: Axis = .horizontal
    var contentType: UITextContentType? = nil
    var keyboard: UIKeyboardType = .default
    var focus: FocusState<Field?>.Binding
    let field: Field

    /// Errors show once the user has edited the field.
    @State private var touched = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
            TextField(title, text: $text, axis: axis)
                .font(.ltBody)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard != .default)
                .focused(focus, equals: field)
                .padding(.horizontal, 12).padding(.vertical, 11)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(showError ? Theme.red : Theme.hairline, lineWidth: 1))
                .onChange(of: text) { touched = true }
                .accessibilityHint(showError ? (error ?? "") : "")
            if showError, let error {
                Text(error).font(.ltCaption).foregroundStyle(Theme.red)
            }
        }
    }

    private var showError: Bool { touched && error != nil }
}
