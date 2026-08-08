import SwiftUI

// MARK: - Profile
//
// Identity, verification progress, and the switch into host mode. Verification is
// surfaced at the top because an unverified guest cannot complete a booking, and
// finding that out at checkout is the worst possible moment.

struct ProfileView: View {
    @Environment(AppState.self) private var state

    @State private var showPayments = false
    @State private var showSettings = false
    @State private var showVerification = false

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl) {
                        identity

                        if state.profile.verificationProgress < 1 {
                            verificationPrompt
                        }

                        stats
                        hostSwitch
                        accountSection
                        supportSection
                        footer
                    }
                    .pageGutter()
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
            }
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPayments) { PaymentMethodsView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showVerification) { VerificationView() }
        }
    }

    // MARK: Identity

    private var identity: some View {
        HStack(spacing: Space.md) {
            Avatar(
                initials: state.profile.initials,
                seed: 5,
                size: 68,
                isVerified: state.profile.verificationProgress == 1
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(state.profile.name)
                    .font(Typo.title)
                    .foregroundStyle(Palette.ink)
                Text("Joined \(String(state.profile.joinedYear)) · \(state.profile.city)")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)
                if state.profile.tripCount > 0 {
                    RatingLabel(rating: state.profile.rating, tripCount: state.profile.tripCount, size: 12, showsWord: true)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var verificationPrompt: some View {
        Button {
            Haptics.tap()
            showVerification = true
        } label: {
            Card(padding: Space.md, fill: Palette.star.opacity(0.08)) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack(spacing: Space.sm) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.star)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Finish verifying your account")
                                .font(Typo.bodySemibold)
                                .foregroundStyle(Palette.ink)
                            Text("One step left. You'll need it before your first booking goes through.")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.surfaceSunken)
                            Capsule()
                                .fill(Palette.star)
                                .frame(width: max(6, geo.size.width * state.profile.verificationProgress))
                        }
                    }
                    .frame(height: 5)
                    .animation(Motion.move, value: state.profile.verificationProgress)
                }
            }
        }
        .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
    }

    private var stats: some View {
        HStack(spacing: Space.sm) {
            statTile("\(state.profile.tripCount)", label: "Trips", icon: "car.side.fill")
            statTile("\(state.favourites.count)", label: "Saved", icon: "heart.fill")
            statTile("\(state.myListings.count)", label: "Listed", icon: "key.fill")
        }
    }

    private func statTile(_ value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: Symbols.resolve(icon, fallback: "circle.fill"))
                .font(.system(size: 13))
                .foregroundStyle(Palette.accent)
            Text(value)
                .font(Typo.numeric(19))
                .foregroundStyle(Palette.ink)
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.7)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    // MARK: Host switch

    private var hostSwitch: some View {
        Button {
            Haptics.tap()
            withAnimation(Motion.drawer) {
                state.mode = .host
                state.hostTab = .dashboard
            }
        } label: {
            HStack(spacing: Space.sm) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.inkInverted)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Palette.accent))

                VStack(alignment: .leading, spacing: 1) {
                    Text(state.profile.isHost ? "Switch to hosting" : "Become a host")
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                    Text(state.profile.isHost
                         ? "\(state.myListings.count) car\(state.myListings.count == 1 ? "" : "s") · \(state.hostRequests.count) request\(state.hostRequests.count == 1 ? "" : "s") waiting"
                         : "List a car and start earning")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(Space.md)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
    }

    // MARK: Lists

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            SectionHeader(title: "Account")

            VStack(spacing: 0) {
                Button { showVerification = true } label: {
                    NavRow(
                        title: "Verification",
                        subtitle: state.profile.verificationProgress == 1 ? "All done" : "1 step remaining",
                        icon: "checkmark.shield.fill",
                        badgeText: state.profile.verificationProgress < 1 ? "1" : nil
                    )
                }
                Hairline(inset: 34)

                Button { showPayments = true } label: {
                    NavRow(
                        title: "Payment methods",
                        subtitle: state.defaultPaymentMethod.map { "\($0.brand) •••• \($0.last4)" } ?? "None added",
                        icon: "creditcard.fill"
                    )
                }
                Hairline(inset: 34)

                Button { state.show(Toast(message: "Nothing here in the prototype", style: .info)) } label: {
                    NavRow(title: "Driving licence", subtitle: state.profile.isLicenseVerified ? "Verified" : "Not verified", icon: "person.text.rectangle.fill")
                }
                Hairline(inset: 34)

                Button { showSettings = true } label: {
                    NavRow(title: "Settings", icon: "gearshape.fill")
                }
            }
            .buttonStyle(PressableStyle(scale: 0.995, dimsOnPress: true))
            .padding(.horizontal, Space.md)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            SectionHeader(title: "Support")

            VStack(spacing: 0) {
                ForEach([
                    ("How it works", "questionmark.circle.fill"),
                    ("Insurance and protection", "shield.lefthalf.filled"),
                    ("Contact support", "bubble.left.and.text.bubble.right.fill"),
                    ("Legal", "doc.text.fill")
                ], id: \.0) { title, icon in
                    Button {
                        state.show(Toast(message: "\(title) — not wired up in the prototype", style: .info))
                    } label: {
                        NavRow(title: title, icon: icon)
                    }
                    if title != "Legal" { Hairline(inset: 34) }
                }
            }
            .buttonStyle(PressableStyle(scale: 0.995))
            .padding(.horizontal, Space.md)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
        }
    }

    private var footer: some View {
        VStack(spacing: Space.xxs) {
            Text("carshare prototype")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.inkTertiary)
            Text("Version 1.0 · No branding, no backend")
                .font(Typo.micro)
                .foregroundStyle(Palette.inkTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Space.md)
    }
}

// MARK: - Verification

struct VerificationView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Verify your account")
                            .font(Typo.display(26))
                            .foregroundStyle(Palette.ink)
                        Text("Hosts are trusting you with their car. These checks are what makes that reasonable.")
                            .font(Typo.body)
                            .foregroundStyle(Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: Space.sm) {
                        checkRow(
                            title: "Email address",
                            detail: state.profile.email,
                            isDone: state.profile.isEmailVerified,
                            action: nil
                        )
                        checkRow(
                            title: "Phone number",
                            detail: "+1 ••• ••• 4417",
                            isDone: state.profile.isPhoneVerified,
                            action: nil
                        )
                        let licenceAction: (() -> Void)? = state.profile.isLicenseVerified
                            ? nil
                            : { state.verifyLicense() }

                        checkRow(
                            title: "Driver's licence",
                            detail: state.profile.isLicenseVerified
                                ? "Approved"
                                : "Photograph the front and back",
                            isDone: state.profile.isLicenseVerified,
                            action: licenceAction
                        )
                    }

                    InlineNote(
                        icon: "lock.fill",
                        text: "Your licence is checked once and never shown to hosts. They only see that it passed.",
                        tint: Palette.inkSecondary
                    )
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
    }

    private func checkRow(title: String, detail: String, isDone: Bool, action: (() -> Void)?) -> some View {
        Card(padding: Space.md) {
            HStack(spacing: Space.sm) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 20))
                    .foregroundStyle(isDone ? Palette.success : Palette.inkTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                }

                Spacer(minLength: 0)

                if let action {
                    Button {
                        Haptics.tap()
                        action()
                    } label: {
                        Text("Verify")
                            .font(Typo.captionMedium)
                            .foregroundStyle(Palette.inkInverted)
                            .padding(.horizontal, Space.sm)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Palette.accent))
                    }
                    .buttonStyle(PressableStyle(scale: 0.94, dimsOnPress: false))
                }
            }
        }
        .animation(Motion.move, value: isDone)
    }
}

// MARK: - Payment methods

struct PaymentMethodsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.sm) {
                    ForEach(state.paymentMethods) { method in
                        Card(padding: Space.md) {
                            HStack(spacing: Space.sm) {
                                Image(systemName: Symbols.resolve(method.symbol, fallback: "creditcard.fill"))
                                    .font(.system(size: 18))
                                    .foregroundStyle(Palette.ink)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(method.brand) •••• \(method.last4)")
                                        .font(Typo.bodyMedium)
                                        .foregroundStyle(Palette.ink)
                                    Text(method.expiry == "—" ? "Wallet" : "Expires \(method.expiry)")
                                        .font(Typo.caption)
                                        .foregroundStyle(Palette.inkTertiary)
                                }

                                Spacer(minLength: 0)

                                if method.isDefault {
                                    Badge(text: "Default")
                                } else {
                                    Button("Make default") {
                                        state.makeDefault(method)
                                    }
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.accent)
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                state.removePaymentMethod(method)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }

                    SecondaryButton(title: "Add a card", icon: "plus") {
                        let last4 = String(format: "%04d", Int.random(in: 1000...9999))
                        state.addPaymentMethod(brand: "Mastercard", last4: last4, expiry: "04/29")
                    }
                    .padding(.top, Space.xs)

                    InlineNote(
                        icon: "lock.fill",
                        text: "Card details aren't stored in this prototype — the add button appends a fake card so you can see the flow.",
                        tint: Palette.inkSecondary
                    )
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
        .animation(Motion.content, value: state.paymentMethods.count)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var smsEnabled = false
    @State private var currency = "USD"
    @State private var distanceUnit = "Miles"

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Push notifications", isOn: $pushEnabled)
                    Toggle("Email updates", isOn: $emailEnabled)
                    Toggle("SMS for trip reminders", isOn: $smsEnabled)
                }

                Section("Preferences") {
                    Picker("Currency", selection: $currency) {
                        ForEach(["USD", "EUR", "GBP", "CAD"], id: \.self) { Text($0) }
                    }
                    Picker("Distance", selection: $distanceUnit) {
                        ForEach(["Miles", "Kilometres"], id: \.self) { Text($0) }
                    }
                }

                Section("Prototype") {
                    Button("Reset all filters") {
                        state.filters = SearchFilters()
                        state.show(Toast(message: "Filters reset", style: .info))
                    }
                    Button("Clear saved cars") {
                        state.favouriteIDs.removeAll()
                        state.show(Toast(message: "Saved cars cleared", style: .info))
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        state.show(Toast(message: "Sign out isn't wired up", style: .warning))
                    }
                }
            }
            .tint(Palette.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
    }
}
