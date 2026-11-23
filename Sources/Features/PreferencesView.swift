import SwiftUI

/// Profile tab: customer details, travel documents, travel preferences
/// (auto-saved, no Save button) and account settings.
struct PreferencesView: View {
    @EnvironmentObject var app: AppState

    // Locally-added custom entries (brand / venue "Add" fields).
    @State private var newBrand = ""
    @State private var newVenue = ""

    var body: some View {
        Screen(title: "Profile") {
            header

            SectionTitle(text: "Personal details")
            listCard {
                ProfileRow(icon: "person", label: "Name", value: app.guest.fullName)
                ProfileRow(icon: "envelope", label: "Email", value: app.guest.email)
                ProfileRow(icon: "phone", label: "Mobile", value: Sample.customer.phone)
                ProfileRow(icon: "house", label: "Home address", value: Sample.customer.address)
                ProfileRow(icon: "calendar", label: "Date of birth", value: Sample.customer.birthday, last: true)
            }

            SectionTitle(text: "Travel documents")
            listCard {
                ProfileRow(icon: "person.text.rectangle", label: "Passport", value: "•••• 7781 · exp. Aug 2031")
                ProfileRow(icon: "checkmark.shield", label: "Known Traveler #", value: "•••• 9384")
                ProfileRow(icon: "airplane", label: "United MileagePlus", value: "•••• 4410")
                ProfileRow(icon: "building.2", label: "World of Hyatt", value: "•••• 2208", last: true)
            }

            HStack(alignment: .firstTextBaseline) {
                SectionTitle(text: "Travel preferences")
                Spacer()
                Label("Auto-saved", systemImage: "checkmark.circle")
                    .font(.ltCaption).foregroundStyle(Theme.success)
            }

            group("Hotel brands", icon: "building.2") {
                chipFlow(Sample.hotelBrands)
                addField(placeholder: "Add a brand", text: $newBrand)
            }
            group("Airlines", icon: "airplane") { chipFlow(Sample.airlines) }
            group("Seat & room", icon: "chair") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seat").font(.ltCaption).foregroundStyle(Theme.textSecondary)
                    Picker("Seat", selection: $app.seatPreference) {
                        ForEach(["Window", "Aisle", "No preference"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("Room").font(.ltCaption).foregroundStyle(Theme.textSecondary).padding(.top, 4)
                    Picker("Room", selection: $app.roomPreference) {
                        ForEach(["High floor", "Quiet", "Near elevator"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            group("Favorite venues", icon: "fork.knife") {
                chipFlow(Sample.venues)
                addField(placeholder: "Add a venue", text: $newVenue)
            }
            group("Cuisines", icon: "takeoutbag.and.cup.and.straw") { chipFlow(Sample.cuisines) }
            group("Dietary needs", icon: "leaf") { chipFlow(Sample.dietary) }
            group("Price range", icon: "dollarsign.circle") {
                Picker("Price", selection: $app.priceLevel) {
                    ForEach(1...4, id: \.self) { Text(String(repeating: "$", count: $0)).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            SectionTitle(text: "Settings")
            listCard {
                ProfileRow(icon: "bell", label: "Notifications", value: nil)
                ProfileRow(icon: "creditcard", label: "Payment methods", value: "Visa •••• 4821")
                ProfileRow(icon: "lock", label: "Privacy & security", value: nil)
                ProfileRow(icon: "questionmark.circle", label: "Help & support", value: nil, last: true)
            }

            PillButton(title: "Opt out of travel profile", kind: .secondary) {}
                .padding(.top, 4)
            Text("Opting out deletes your saved preferences. Bookings and rewards stay on your account.")
                .font(.ltCaption).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(initials)
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Theme.button, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.guest.fullName).font(.ltTitle).foregroundStyle(Theme.textPrimary)
                    Text("Member since \(Sample.customer.memberSince) · \(Sample.customer.city)")
                        .font(.ltCaption).foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Image(systemName: "star").font(.callout)
                Text("\(app.points.formatted()) rewards points").font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14).frame(minHeight: 44)
            .background(Theme.rewardsStrip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .combine)
    }

    private var initials: String {
        [app.guest.firstName, app.guest.lastName].compactMap { $0.trimmingCharacters(in: .whitespaces).first }
            .map(String.init).joined()
    }

    // MARK: Helpers

    /// Rows in one white card, divided like a settings list.
    private func listCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }.card()
    }

    /// A titled white card group for a preference.
    private func group<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.ltHeadline).labelStyle(IconLabelStyle())
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.cardPadding).card()
    }

    private func chipFlow(_ items: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Chip(title: item, selected: app.selected.contains(item)) { app.toggle(item) }
            }
        }
    }

    /// "Add a brand  (+)" field inside a preference card.
    private func addField(placeholder: String, text: Binding<String>) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .font(.ltBody)
                .submitLabel(.done)
                .onSubmit { add(text) }
            Button { add(text) } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Theme.button)
            }
            .accessibilityLabel("Add")
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func add(_ text: Binding<String>) {
        let v = text.wrappedValue.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        app.selected.insert(v)
        text.wrappedValue = ""
    }
}

/// Icon, label and value; a divider unless it's the last row in its card.
struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String?
    var last = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.body).foregroundStyle(Theme.icon).frame(width: 24)
                if let value {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(.ltCaption).foregroundStyle(Theme.textSecondary)
                        Text(value).font(.ltBody).foregroundStyle(Theme.textPrimary)
                    }
                } else {
                    Text(label).font(.ltBody).foregroundStyle(Theme.textPrimary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.cardPadding)
            .frame(minHeight: 56)
            .padding(.vertical, 6)
            if !last { Divider().padding(.leading, Theme.cardPadding + 38) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The signed-in customer's details (sample).
struct Customer {
    let phone: String
    let address: String
    let birthday: String
    let memberSince: String
    let city: String
}

extension Sample {
    static let customer = Customer(phone: "(713) 555-0142", address: "1200 Main St, Houston, TX 77002",
                                   birthday: "Apr 12, 1985", memberSince: "2019", city: "Houston, TX")
}

// MARK: - FlowLayout

/// A minimal wrapping layout so chips flow to the next line (iOS 16+ Layout API).
/// Improvement: extract to the design system if reused elsewhere.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
