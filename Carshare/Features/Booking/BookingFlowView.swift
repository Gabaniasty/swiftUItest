import SwiftUI

// MARK: - Booking flow
//
// Five steps, one bottom bar, one running total. The total is visible on every step
// because the single worst thing a booking flow can do is reveal the real price at
// the end.

struct BookingFlowView: View {
    let car: Car

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BookingDraft
    @State private var step: Step = .dates
    @State private var isAdvancing = true
    @State private var isSubmitting = false
    @State private var confirmedTrip: Trip?

    init(car: Car) {
        self.car = car
        _draft = State(initialValue: BookingDraft(car: car, start: Date(), end: Date()))
    }

    enum Step: Int, CaseIterable {
        case dates, handoff, protection, extras, review

        var title: String {
            switch self {
            case .dates: "When do you need it?"
            case .handoff: "How do you want it?"
            case .protection: "Choose your cover"
            case .extras: "Anything else?"
            case .review: "Check and confirm"
            }
        }

        var eyebrow: String {
            "Step \(rawValue + 1) of \(Step.allCases.count)"
        }
    }

    private var quote: PriceQuote {
        state.quote(
            car: car,
            start: draft.startDate,
            end: draft.endDate,
            protection: draft.protection,
            extras: draft.selectedExtras,
            handoff: draft.handoff
        )
    }

    /// Blocked days that fall inside the chosen range. Blocks progress rather than
    /// failing later at checkout.
    private var conflictingDates: [Date] {
        let calendar = Calendar.current
        return car.blockedDates.filter { blocked in
            blocked >= calendar.startOfDay(for: draft.startDate)
                && blocked <= calendar.startOfDay(for: draft.endDate)
        }.sorted()
    }

    private var canAdvance: Bool {
        switch step {
        case .dates:
            return draft.days >= car.minTripDays && conflictingDates.isEmpty && draft.endDate > draft.startDate
        case .handoff:
            return draft.handoff == .hostLocation || !draft.deliveryAddress.trimmingCharacters(in: .whitespaces).isEmpty
        case .protection, .extras:
            return true
        case .review:
            return draft.agreedToTerms && state.defaultPaymentMethod != nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg) {
                        headerBlock

                        Group {
                            switch step {
                            case .dates: DatesStep(car: car, draft: draft, conflicts: conflictingDates)
                            case .handoff: HandoffStep(car: car, draft: draft)
                            case .protection: ProtectionStep(draft: draft, quote: quote)
                            case .extras: ExtrasStep(draft: draft)
                            case .review: ReviewStep(car: car, draft: draft, quote: quote)
                            }
                        }
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: isAdvancing ? .trailing : .leading).combined(with: .opacity),
                                removal: .move(edge: isAdvancing ? .leading : .trailing).combined(with: .opacity)
                            )
                        )
                    }
                    .pageGutter()
                    .padding(.top, Space.xs)
                    .padding(.bottom, Space.xxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(car.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(step == .dates ? "Cancel" : "Back") {
                        Haptics.tap()
                        if step == .dates {
                            dismiss()
                        } else {
                            goBack()
                        }
                    }
                    .font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .fullScreenCover(item: $confirmedTrip) { trip in
                ConfirmationView(trip: trip) { dismiss() }
            }
        }
        .onAppear {
            draft.startDate = state.query.startDate
            draft.endDate = state.query.endDate
            // Respect the listing's minimum trip length rather than silently failing.
            if draft.days < car.minTripDays,
               let corrected = Calendar.current.date(byAdding: .day, value: car.minTripDays, to: draft.startDate) {
                draft.endDate = corrected
            }
        }
        .animation(Motion.move, value: step)
    }

    // MARK: Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            ProgressTrack(current: step.rawValue, total: Step.allCases.count)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.eyebrow.uppercased())
                    .font(Typo.eyebrow)
                    .tracking(1.2)
                    .foregroundStyle(Palette.inkTertiary)
                Text(step.title)
                    .font(Typo.display(27))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Hairline()

            VStack(spacing: Space.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Money.full(quote.total))
                            .font(Typo.numeric(19))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                        Text("\(quote.days) day\(quote.days == 1 ? "" : "s") · all in")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    Spacer()
                    if step != .review {
                        Text("\(Money.short(car.dailyPrice))/day")
                            .font(Typo.numeric(13, weight: .medium))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }

                PrimaryButton(
                    title: step == .review
                        ? (car.isInstantBook ? "Confirm and pay" : "Send request")
                        : "Continue",
                    icon: step == .review ? "lock.fill" : nil,
                    isEnabled: canAdvance,
                    isLoading: isSubmitting
                ) {
                    if step == .review { submit() } else { goForward() }
                }

                if step == .review {
                    Text(car.isInstantBook
                         ? "You'll be charged \(Money.full(quote.total)) now."
                         : "You won't be charged until \(car.title.split(separator: " ").first.map(String.init) ?? "the host") accepts.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.sm)
        }
        .background(.regularMaterial)
        .animation(Motion.snap, value: quote.total)
    }

    // MARK: Navigation

    private func goForward() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        isAdvancing = true
        withAnimation(Motion.move) { step = next }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        isAdvancing = false
        withAnimation(Motion.move) { step = previous }
    }

    private func submit() {
        isSubmitting = true
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            await MainActor.run {
                let trip = state.book(draft)
                isSubmitting = false
                confirmedTrip = trip
            }
        }
    }
}

// MARK: - Progress track

struct ProgressTrack: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Palette.ink : Palette.surfaceSunken)
                    .frame(height: 3)
            }
        }
        .animation(Motion.move, value: current)
    }
}

// MARK: - Step 1 · Dates

private struct DatesStep: View {
    let car: Car
    let draft: BookingDraft
    let conflicts: [Date]

    var body: some View {
        @Bindable var draft = draft

        VStack(alignment: .leading, spacing: Space.md) {
            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DatePicker("Pick up", selection: $draft.startDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .font(Typo.bodyMedium)
                        .onChange(of: draft.startDate) { _, newValue in
                            if draft.endDate <= newValue {
                                draft.endDate = Calendar.current.date(byAdding: .day, value: max(1, car.minTripDays), to: newValue) ?? newValue
                            }
                        }

                    Hairline()

                    DatePicker(
                        "Return",
                        selection: $draft.endDate,
                        in: (Calendar.current.date(byAdding: .day, value: max(1, car.minTripDays), to: draft.startDate) ?? draft.startDate)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(Typo.bodyMedium)
                }
            }

            if car.minTripDays > 1 {
                InlineNote(
                    icon: "info.circle.fill",
                    text: "This host asks for a minimum of \(car.minTripDays) days.",
                    tint: Palette.info
                )
            }

            if !conflicts.isEmpty {
                InlineNote(
                    icon: "exclamationmark.triangle.fill",
                    text: conflicts.count == 1
                        ? "\(DateText.short(conflicts[0])) is already booked. Pick different dates."
                        : "\(conflicts.count) days in that range are already booked, starting \(DateText.short(conflicts[0])).",
                    tint: Palette.danger
                )
            }

            if draft.days >= 3 {
                InlineNote(
                    icon: "tag.fill",
                    text: draft.days >= 7
                        ? "Weekly rate applied — 15% off the daily price."
                        : "3+ day rate applied — 7% off the daily price.",
                    tint: Palette.success
                )
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                SectionHeader(title: "Already booked")
                AvailabilityCalendar(
                    blockedDates: car.blockedDates,
                    selectedRange: draft.startDate...max(draft.endDate, draft.startDate)
                )
            }
            .padding(.top, Space.xs)
        }
    }
}

// MARK: - Step 2 · Handoff

private struct HandoffStep: View {
    let car: Car
    let draft: BookingDraft

    var body: some View {
        @Bindable var draft = draft

        VStack(alignment: .leading, spacing: Space.md) {
            SelectableRow(
                title: "Pick up from the host",
                subtitle: "\(car.location.name) · \(car.location.detail)",
                icon: "figure.walk",
                isSelected: draft.handoff == .hostLocation,
                trailing: {
                    Text("Free")
                        .font(Typo.captionMedium)
                        .foregroundStyle(Palette.success)
                }
            ) {
                withAnimation(Motion.snap) { draft.handoff = .hostLocation }
            }

            if let fee = car.deliveryFee {
                SelectableRow(
                    title: "Delivered to you",
                    subtitle: "The host brings it to an address you choose.",
                    icon: "shippingbox.fill",
                    isSelected: draft.handoff == .delivery,
                    trailing: {
                        Text("+\(Money.short(fee))")
                            .font(Typo.numeric(13, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                    }
                ) {
                    withAnimation(Motion.snap) { draft.handoff = .delivery }
                }

                if draft.handoff == .delivery {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Delivery address")
                            .font(Typo.eyebrow)
                            .tracking(1.2)
                            .foregroundStyle(Palette.inkTertiary)

                        TextField("Street, city", text: $draft.deliveryAddress, axis: .vertical)
                            .font(Typo.body)
                            .padding(Space.sm)
                            .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                    .stroke(Palette.hairlineStrong, lineWidth: 1)
                            )

                        Text("Airport pickups and hotel drop-offs are both fine — just be specific about the terminal or entrance.")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                InlineNote(
                    icon: "info.circle.fill",
                    text: "This host doesn't offer delivery — you'll collect it in \(car.location.name).",
                    tint: Palette.info
                )
            }
        }
    }
}

// MARK: - Step 3 · Protection

private struct ProtectionStep: View {
    let draft: BookingDraft
    let quote: PriceQuote

    var body: some View {
        @Bindable var draft = draft

        VStack(alignment: .leading, spacing: Space.md) {
            ForEach(ProtectionPlan.allCases) { plan in
                let cost = (quote.subtotal - quote.discountAmount) * plan.rate

                SelectableRow(
                    title: plan.label,
                    subtitle: plan.summary,
                    isSelected: draft.protection == plan,
                    trailing: {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(Money.short(cost))
                                .font(Typo.numeric(15))
                                .foregroundStyle(Palette.ink)
                            Text("total")
                                .font(Typo.micro)
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }
                ) {
                    withAnimation(Motion.snap) { draft.protection = plan }
                }

                if draft.protection == plan {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(plan.inclusions, id: \.self) { item in
                            HStack(spacing: Space.xs) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Palette.accent)
                                Text(item)
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.inkSecondary)
                            }
                        }
                    }
                    .padding(.leading, Space.xl)
                    .padding(.bottom, Space.xs)
                    .transition(.opacity)
                }
            }

            InlineNote(
                icon: "shield.lefthalf.filled",
                text: "Every plan includes 24/7 roadside assistance. Your own insurance isn't used unless you ask us to.",
                tint: Palette.inkSecondary
            )
        }
    }
}

// MARK: - Step 4 · Extras

private struct ExtrasStep: View {
    let draft: BookingDraft
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            ForEach(state.extras) { extra in
                ExtraRow(extra: extra, draft: draft, days: draft.days)
            }

            if draft.selectedExtras.isEmpty {
                Text("Nothing selected — that's completely fine. You can add extras later from your trip.")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .padding(.top, Space.xs)
            }
        }
    }
}

private struct ExtraRow: View {
    let extra: Extra
    let draft: BookingDraft
    let days: Int

    @State private var quantity: Int = 0

    var body: some View {
        Card(padding: Space.md) {
            HStack(alignment: .top, spacing: Space.sm) {
                Image(systemName: Symbols.resolve(extra.symbol, fallback: "plus.circle"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(quantity > 0 ? Palette.accent : Palette.inkSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(quantity > 0 ? Palette.accentWash : Palette.surfaceSunken))

                VStack(alignment: .leading, spacing: 3) {
                    Text(extra.name)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                    Text(extra.detail)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(quantity > 0
                         ? "\(extra.priceLabel) · \(Money.full(extra.total(quantity: quantity, days: days))) total"
                         : extra.priceLabel)
                        .font(Typo.numeric(12, weight: .medium))
                        .foregroundStyle(quantity > 0 ? Palette.accent : Palette.inkTertiary)
                }

                Spacer(minLength: Space.xs)

                if extra.maxQuantity > 1 {
                    CounterControl(value: $quantity, range: 0...extra.maxQuantity)
                } else {
                    Toggle("", isOn: Binding(
                        get: { quantity > 0 },
                        set: { quantity = $0 ? 1 : 0 }
                    ))
                    .labelsHidden()
                    .tint(Palette.accent)
                }
            }
        }
        .onAppear { quantity = draft.quantity(for: extra) }
        .onChange(of: quantity) { _, newValue in
            draft.setQuantity(newValue, for: extra)
        }
        .animation(Motion.snap, value: quantity)
    }
}

// MARK: - Step 5 · Review

private struct ReviewStep: View {
    let car: Car
    let draft: BookingDraft
    let quote: PriceQuote

    @Environment(AppState.self) private var state
    @State private var showPaymentPicker = false

    var body: some View {
        @Bindable var draft = draft

        VStack(alignment: .leading, spacing: Space.lg) {
            // Summary
            Card(padding: Space.md) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack(spacing: Space.sm) {
                        CarThumb(car: car, height: 64, radius: Radius.sm)
                            .frame(width: 92)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(car.fullTitle)
                                .font(Typo.bodySemibold)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            RatingLabel(rating: car.rating, tripCount: car.tripCount, size: 12)
                            Text(car.location.name)
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    Hairline()

                    summaryRow("Dates", DateText.rangeWithTimes(draft.startDate, draft.endDate), icon: "calendar")
                    summaryRow(draft.handoff.label, draft.handoff == .delivery ? draft.deliveryAddress : car.location.detail, icon: draft.handoff.symbol)
                    summaryRow("Protection", "\(draft.protection.label) · \(Money.short(draft.protection.deductible)) deductible", icon: "shield.lefthalf.filled")

                    if !draft.selectedExtras.isEmpty {
                        summaryRow(
                            "Extras",
                            draft.selectedExtras.compactMap { selection in
                                guard let extra = state.extra(selection.extraID) else { return nil }
                                return selection.quantity > 1 ? "\(extra.name) ×\(selection.quantity)" : extra.name
                            }.joined(separator: ", "),
                            icon: "plus.circle"
                        )
                    }
                }
            }

            // Licence gate
            if !state.profile.isLicenseVerified {
                VStack(alignment: .leading, spacing: Space.sm) {
                    SectionHeader(title: "Driver's licence")
                    Card(padding: Space.md, fill: Palette.star.opacity(0.08)) {
                        VStack(alignment: .leading, spacing: Space.sm) {
                            HStack(spacing: Space.sm) {
                                Image(systemName: "person.text.rectangle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Palette.star)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("We need to verify your licence")
                                        .font(Typo.bodySemibold)
                                        .foregroundStyle(Palette.ink)
                                    Text("One-off check. Takes about a minute and it's reused for every future trip.")
                                        .font(Typo.caption)
                                        .foregroundStyle(Palette.inkSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            SecondaryButton(title: "Verify now", icon: "camera.fill") {
                                state.verifyLicense()
                            }
                        }
                    }
                }
            }

            // Payment
            let canSwitchCard = state.paymentMethods.count > 1
            let changeTitle: String? = canSwitchCard ? "Change" : nil
            let changeAction: (() -> Void)? = canSwitchCard ? { showPaymentPicker = true } : nil

            VStack(alignment: .leading, spacing: Space.sm) {
                SectionHeader(
                    title: "Payment",
                    actionTitle: changeTitle,
                    action: changeAction
                )

                if let method = state.defaultPaymentMethod {
                    Card(padding: Space.md) {
                        HStack(spacing: Space.sm) {
                            Image(systemName: Symbols.resolve(method.symbol, fallback: "creditcard.fill"))
                                .font(.system(size: 17))
                                .foregroundStyle(Palette.ink)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(method.brand) •••• \(method.last4)")
                                    .font(Typo.bodyMedium)
                                    .foregroundStyle(Palette.ink)
                                Text(method.expiry == "—" ? "Wallet" : "Expires \(method.expiry)")
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.inkTertiary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.success)
                        }
                    }
                } else {
                    SecondaryButton(title: "Add a payment method", icon: "plus") {
                        state.addPaymentMethod(brand: "Visa", last4: "4242", expiry: "08/28")
                    }
                }
            }

            // Message
            VStack(alignment: .leading, spacing: Space.xs) {
                SectionHeader(title: "Message to host", eyebrow: "Optional")
                TextField(
                    "Flight number, rough pickup time, anything they should know…",
                    text: $draft.message,
                    axis: .vertical
                )
                .font(Typo.body)
                .lineLimit(3...6)
                .padding(Space.sm)
                .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .stroke(Palette.hairlineStrong, lineWidth: 1)
                )
            }

            // Full price breakdown
            VStack(alignment: .leading, spacing: Space.sm) {
                SectionHeader(title: "Price detail")
                Card(padding: Space.md) {
                    VStack(spacing: Space.sm) {
                        DetailRow(label: "\(Money.short(quote.nightlyRate)) × \(quote.days) day\(quote.days == 1 ? "" : "s")", value: Money.full(quote.subtotal))
                        if let label = quote.discountLabel {
                            DetailRow(label: label, value: "−\(Money.full(quote.discountAmount))", valueColor: Palette.success)
                        }
                        DetailRow(label: "Protection · \(draft.protection.label)", value: Money.full(quote.protectionCost))
                        if quote.extrasCost > 0 {
                            DetailRow(label: "Extras", value: Money.full(quote.extrasCost))
                        }
                        if quote.deliveryCost > 0 {
                            DetailRow(label: "Delivery", value: Money.full(quote.deliveryCost))
                        }
                        DetailRow(label: "Trip fee", value: Money.full(quote.tripFee))
                        DetailRow(label: "Taxes", value: Money.full(quote.taxes))
                        Hairline()
                        DetailRow(label: "Total", value: Money.full(quote.total), isEmphasised: true)
                    }
                }
            }

            // Terms
            Button {
                Haptics.select()
                withAnimation(Motion.snap) { draft.agreedToTerms.toggle() }
            } label: {
                HStack(alignment: .top, spacing: Space.sm) {
                    Image(systemName: draft.agreedToTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(draft.agreedToTerms ? Palette.accent : Palette.inkTertiary)
                    Text("I agree to the rental terms, the cancellation policy, and the host's house rules.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
        }
        .sheet(isPresented: $showPaymentPicker) {
            PaymentPickerSheet()
        }
    }

    private func summaryRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: Space.sm) {
            Image(systemName: Symbols.resolve(icon, fallback: "circle"))
                .font(.system(size: 13))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Typo.micro)
                    .tracking(0.5)
                    .foregroundStyle(Palette.inkTertiary)
                Text(value)
                    .font(Typo.body)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Shared note

struct InlineNote: View {
    let icon: String
    let text: String
    var tint: Color = Palette.info

    var body: some View {
        HStack(alignment: .top, spacing: Space.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .padding(.top, 1)
            Text(text)
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Space.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(tint.opacity(0.09))
        )
    }
}

// MARK: - Payment picker

struct PaymentPickerSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.xs) {
                    ForEach(state.paymentMethods) { method in
                        SelectableRow(
                            title: "\(method.brand) •••• \(method.last4)",
                            subtitle: method.expiry == "—" ? "Wallet" : "Expires \(method.expiry)",
                            icon: method.symbol,
                            isSelected: method.isDefault
                        ) {
                            state.makeDefault(method)
                            dismiss()
                        }
                    }
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Payment method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
