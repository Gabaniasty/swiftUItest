import SwiftUI
import MapKit

// MARK: - Trip detail
//
// Reads the trip by id from app state rather than holding a copy, so checking in or
// extending updates this screen in place instead of showing a stale snapshot.

struct TripDetailView: View {
    let tripID: UUID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var showCheckIn = false
    @State private var showExtend = false
    @State private var showCancelDialog = false
    @State private var showReview = false

    private var trip: Trip? { state.trips.first { $0.id == tripID } }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if let trip, let car = state.car(trip.carID) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Space.xl) {
                            hero(trip: trip, car: car)
                            statusBlock(trip: trip, car: car)
                            timeline(trip: trip)
                            handoffBlock(trip: trip, car: car)
                            if let host = state.host(for: car) {
                                hostBlock(host: host, car: car)
                            }
                            includedBlock(trip: trip, car: car)
                            receipt(trip: trip)
                            actions(trip: trip, car: car)
                        }
                        .padding(.bottom, Space.xxl)
                    }
                    .ignoresSafeArea(edges: .top)
                } else {
                    EmptyStateView(
                        icon: "questionmark.circle",
                        title: "Trip not found",
                        message: "This trip is no longer available."
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(Typo.bodyMedium)
                }
            }
            .sheet(isPresented: $showCheckIn) {
                if let trip { CheckInFlowView(trip: trip) }
            }
            .sheet(isPresented: $showExtend) {
                if let trip { ExtendTripSheet(trip: trip) }
            }
            .sheet(isPresented: $showReview) {
                if let trip, let car = state.car(trip.carID) {
                    LeaveReviewSheet(trip: trip, car: car)
                }
            }
            .confirmationDialog(
                "Cancel this trip?",
                isPresented: $showCancelDialog,
                titleVisibility: .visible
            ) {
                Button("Cancel trip", role: .destructive) {
                    if let trip {
                        state.cancelTrip(trip)
                        dismiss()
                    }
                }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text("Free cancellation applies up to 24 hours before pickup. Inside that window you're charged one day or 50% of the trip, whichever is less.")
            }
        }
    }

    // MARK: Sections

    private func hero(trip: Trip, car: Car) -> some View {
        ZStack(alignment: .bottomLeading) {
            CarArtwork(car: car, variant: .hero)
                .frame(height: 240)

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .frame(height: 240)

            VStack(alignment: .leading, spacing: Space.xs) {
                StatusPill(status: trip.status)
                Text(car.fullTitle)
                    .font(Typo.title)
                    .foregroundStyle(.white)
                Text(DateText.range(trip.startDate, trip.endDate) + " · " + "\(trip.dayCount) day\(trip.dayCount == 1 ? "" : "s")")
                    .font(Typo.body)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(Space.gutter)
            .padding(.bottom, Space.xs)
        }
    }

    /// The one thing to do right now, phrased as an instruction.
    @ViewBuilder
    private func statusBlock(trip: Trip, car: Car) -> some View {
        let (icon, title, detail, tint): (String, String, String, Color) = {
            switch trip.status {
            case .requested:
                return ("clock.fill", "Waiting on the host",
                        "\(state.host(for: car)?.name.split(separator: " ").first.map(String.init) ?? "They") usually reply \(state.host(for: car)?.responseTimeLabel ?? "within a day"). You haven't been charged.",
                        Palette.star)
            case .upcoming:
                return ("checkmark.seal.fill", "Confirmed — \(DateText.countdown(to: trip.startDate))",
                        "Check in when you collect the car. You'll photograph it from six angles first.",
                        Palette.accent)
            case .active:
                return ("car.side.fill", "Trip in progress",
                        "Due back \(DateText.withWeekday(trip.endDate)) at \(DateText.clock(trip.endDate)). Need longer? You can extend it.",
                        Palette.info)
            case .completed:
                return ("flag.checkered", "Trip completed",
                        trip.guestReviewLeft ? "Thanks for reviewing this one." : "Leaving a review helps the next guest — and the host.",
                        Palette.inkSecondary)
            case .cancelled:
                return ("xmark.circle.fill", "Trip cancelled", "Any refund due is back with you in 3–5 business days.", Palette.danger)
            case .declined:
                return ("xmark.circle.fill", "Request declined", "The host couldn't take these dates. You weren't charged.", Palette.danger)
            }
        }()

        Card(padding: Space.md, fill: tint.opacity(0.07)) {
            HStack(alignment: .top, spacing: Space.sm) {
                Image(systemName: Symbols.resolve(icon, fallback: "info.circle.fill"))
                    .font(.system(size: 17))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .pageGutter()
    }

    private func timeline(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "Your trip")

            VStack(spacing: 0) {
                timelineRow(
                    title: "Booked",
                    detail: DateText.full(trip.bookedAt),
                    isDone: true,
                    isLast: false
                )
                timelineRow(
                    title: trip.status == .requested ? "Host approval" : "Confirmed",
                    detail: trip.status == .requested ? "Pending" : "Approved",
                    isDone: trip.status != .requested && trip.status != .declined,
                    isLast: false
                )
                timelineRow(
                    title: "Check in",
                    detail: trip.isCheckedIn ? "\(trip.checkInPhotoCount) photos taken" : "At pickup",
                    isDone: trip.isCheckedIn,
                    isLast: false
                )
                timelineRow(
                    title: "Return and check out",
                    detail: DateText.withWeekday(trip.endDate),
                    isDone: trip.status == .completed,
                    isLast: true
                )
            }
        }
        .pageGutter()
    }

    private func timelineRow(title: String, detail: String, isDone: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Space.sm) {
            VStack(spacing: 0) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(isDone ? Palette.accent : Palette.inkTertiary.opacity(0.5))
                if !isLast {
                    Rectangle()
                        .fill(isDone ? Palette.accent.opacity(0.35) : Palette.hairline)
                        .frame(width: 1.5)
                        .frame(minHeight: 26)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Typo.bodyMedium)
                    .foregroundStyle(isDone ? Palette.ink : Palette.inkSecondary)
                Text(detail)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.bottom, isLast ? 0 : Space.sm)

            Spacer(minLength: 0)
        }
    }

    private func handoffBlock(trip: Trip, car: Car) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: trip.handoff == .delivery ? "Delivery" : "Pickup")

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: car.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                ),
                interactionModes: []
            ) {
                Annotation("", coordinate: car.location.coordinate) {
                    Image(systemName: "mappin")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.inkInverted)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.ink))
                }
                .annotationTitles(.hidden)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: Space.xs) {
                DetailRow(label: "Address", value: trip.handoffAddress, labelIcon: "mappin.and.ellipse")
                DetailRow(label: "Pick up", value: "\(DateText.withWeekday(trip.startDate)), \(DateText.clock(trip.startDate))", labelIcon: "arrow.down.circle")
                DetailRow(label: "Return", value: "\(DateText.withWeekday(trip.endDate)), \(DateText.clock(trip.endDate))", labelIcon: "arrow.up.circle")
            }
        }
        .pageGutter()
    }

    private func hostBlock(host: Host, car: Car) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Your host")

            Card(padding: Space.md) {
                HStack(spacing: Space.sm) {
                    Avatar(initials: host.initials, seed: host.accentSeed, size: 46, isVerified: host.isVerified)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(host.name)
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                        Text("Replies \(host.responseTimeLabel)")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        state.selectedTab = .inbox
                        dismiss()
                    } label: {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.inkInverted)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Palette.ink))
                    }
                    .buttonStyle(PressableStyle(scale: 0.92, dimsOnPress: false))
                }
            }
        }
        .pageGutter()
    }

    private func includedBlock(trip: Trip, car: Car) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "What's included")

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DetailRow(
                        label: "Protection",
                        value: "\(trip.protection.label) · \(Money.short(trip.protection.deductible)) deductible",
                        labelIcon: "shield.lefthalf.filled"
                    )
                    DetailRow(
                        label: "Mileage",
                        value: "\(car.includedMilesPerDay * trip.dayCount) mi total",
                        labelIcon: "gauge.with.dots.needle.50percent"
                    )
                    ForEach(trip.extras) { selection in
                        if let extra = state.extra(selection.extraID) {
                            DetailRow(
                                label: selection.quantity > 1 ? "\(extra.name) ×\(selection.quantity)" : extra.name,
                                value: Money.full(extra.total(quantity: selection.quantity, days: trip.dayCount)),
                                labelIcon: extra.symbol
                            )
                        }
                    }
                }
            }
        }
        .pageGutter()
    }

    private func receipt(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: trip.status == .completed ? "Receipt" : "Price")

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DetailRow(
                        label: "\(Money.short(trip.quote.nightlyRate)) × \(trip.quote.days) day\(trip.quote.days == 1 ? "" : "s")",
                        value: Money.full(trip.quote.subtotal)
                    )
                    if let label = trip.quote.discountLabel {
                        DetailRow(label: label, value: "−\(Money.full(trip.quote.discountAmount))", valueColor: Palette.success)
                    }
                    DetailRow(label: "Protection", value: Money.full(trip.quote.protectionCost))
                    if trip.quote.extrasCost > 0 {
                        DetailRow(label: "Extras", value: Money.full(trip.quote.extrasCost))
                    }
                    if trip.quote.deliveryCost > 0 {
                        DetailRow(label: "Delivery", value: Money.full(trip.quote.deliveryCost))
                    }
                    DetailRow(label: "Trip fee", value: Money.full(trip.quote.tripFee))
                    DetailRow(label: "Taxes", value: Money.full(trip.quote.taxes))
                    Hairline()
                    DetailRow(label: "Total", value: Money.full(trip.quote.total), isEmphasised: true)
                }
            }
        }
        .pageGutter()
    }

    @ViewBuilder
    private func actions(trip: Trip, car: Car) -> some View {
        VStack(spacing: Space.sm) {
            switch trip.status {
            case .upcoming:
                PrimaryButton(title: "Check in and collect", icon: "camera.fill") {
                    showCheckIn = true
                }
                SecondaryButton(title: "Cancel trip", isDestructive: true) {
                    showCancelDialog = true
                }

            case .active:
                PrimaryButton(title: "Extend this trip", icon: "clock.arrow.circlepath") {
                    showExtend = true
                }
                SecondaryButton(title: "End trip and check out", icon: "flag.checkered") {
                    state.completeTrip(trip)
                }

            case .requested:
                SecondaryButton(title: "Withdraw request", isDestructive: true) {
                    showCancelDialog = true
                }

            case .completed:
                if !trip.guestReviewLeft {
                    PrimaryButton(title: "Leave a review", icon: "star.fill") {
                        showReview = true
                    }
                }
                SecondaryButton(title: "Book this car again", icon: "arrow.clockwise") {
                    state.selectedTab = .explore
                    dismiss()
                }

            case .cancelled, .declined:
                SecondaryButton(title: "Find another car", icon: "magnifyingglass") {
                    state.selectedTab = .explore
                    dismiss()
                }
            }
        }
        .pageGutter()
        .padding(.top, Space.xs)
    }
}

// MARK: - Extend

struct ExtendTripSheet: View {
    let trip: Trip

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var extraDays = 1

    private var car: Car? { state.car(trip.carID) }

    private var additionalCost: Double {
        guard let car else { return 0 }
        return car.dailyPrice * Double(extraDays) * 1.25 // rate plus protection and fees
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Space.lg) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("How much longer?")
                        .font(Typo.display(26))
                        .foregroundStyle(Palette.ink)
                    Text("Currently due back \(DateText.withWeekday(trip.endDate)) at \(DateText.clock(trip.endDate)).")
                        .font(Typo.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card(padding: Space.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extra days")
                                .font(Typo.bodyMedium)
                                .foregroundStyle(Palette.ink)
                            if let newEnd = Calendar.current.date(byAdding: .day, value: extraDays, to: trip.endDate) {
                                Text("New return: \(DateText.withWeekday(newEnd))")
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.inkSecondary)
                            }
                        }
                        Spacer()
                        CounterControl(value: $extraDays, range: 1...14)
                    }
                }

                Card(padding: Space.md) {
                    DetailRow(label: "Additional charge", value: Money.full(additionalCost), isEmphasised: true)
                }

                InlineNote(
                    icon: "info.circle.fill",
                    text: "The host has to be free for the new dates. If they aren't, you'll hear back within an hour and nothing is charged.",
                    tint: Palette.info
                )

                Spacer()
            }
            .pageGutter()
            .padding(.top, Space.md)
            .background(Palette.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Request \(extraDays) more day\(extraDays == 1 ? "" : "s")") {
                    state.extendTrip(trip, byDays: extraDays)
                    dismiss()
                }
                .padding(Space.md)
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Leave a review

struct LeaveReviewSheet: View {
    let trip: Trip
    let car: Car

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Double = 5
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    HStack(spacing: Space.sm) {
                        CarThumb(car: car, height: 68, radius: Radius.sm)
                            .frame(width: 96)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(car.fullTitle)
                                .font(Typo.bodySemibold)
                                .foregroundStyle(Palette.ink)
                            Text(DateText.range(trip.startDate, trip.endDate))
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("How was it?")
                            .font(Typo.sectionTitle)
                            .foregroundStyle(Palette.ink)

                        HStack(spacing: Space.xs) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    Haptics.select()
                                    withAnimation(Motion.press) { rating = Double(star) }
                                } label: {
                                    Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                        .font(.system(size: 30))
                                        .foregroundStyle(Palette.star)
                                }
                                .buttonStyle(PressableStyle(scale: 0.88, dimsOnPress: false))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Tell other guests about it")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        TextField("The car, the handover, the host…", text: $text, axis: .vertical)
                            .font(Typo.body)
                            .lineLimit(4...8)
                            .padding(Space.sm)
                            .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                    .stroke(Palette.hairlineStrong, lineWidth: 1)
                            )
                    }
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Post review") {
                    state.leaveReview(for: trip, rating: rating, text: text)
                    dismiss()
                }
                .padding(Space.md)
                .background(.regularMaterial)
            }
        }
    }
}
