import SwiftUI

// MARK: - Host shell
//
// A separate tab set rather than a section inside the guest app. Hosting is a different
// job with different verbs — approve, price, block dates — and mixing it into the
// browse experience is what makes these apps feel confused.

struct HostShellView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        TabView(selection: $state.hostTab) {
            HostDashboardView()
                .tabItem { Label(HostTab.dashboard.title, systemImage: HostTab.dashboard.symbol) }
                .tag(HostTab.dashboard)

            HostListingsView()
                .tabItem { Label(HostTab.listings.title, systemImage: HostTab.listings.symbol) }
                .tag(HostTab.listings)

            HostRequestsView()
                .tabItem { Label(HostTab.requests.title, systemImage: HostTab.requests.symbol) }
                .badge(state.hostRequests.count)
                .tag(HostTab.requests)

            HostEarningsView()
                .tabItem { Label(HostTab.earnings.title, systemImage: HostTab.earnings.symbol) }
                .tag(HostTab.earnings)
        }
    }
}

// MARK: - Dashboard

struct HostDashboardView: View {
    @Environment(AppState.self) private var state

    @State private var showAddCar = false
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl) {
                        greeting
                        earningsStrip

                        if !state.hostRequests.isEmpty {
                            requestsPreview
                        }

                        upcomingSection
                        listingsPreview
                        tipCard
                    }
                    .pageGutter()
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
            }
            .navigationTitle("Hosting")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        withAnimation(Motion.drawer) { state.mode = .guest }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("Guest")
                                .font(Typo.captionMedium)
                        }
                        .foregroundStyle(Palette.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddCar) { AddCarFlowView() }
            .sheet(item: $selectedTrip) { trip in
                HostTripDetailView(tripID: trip.id)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text("Today".uppercased())
                .font(Typo.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Palette.inkTertiary)
            Text(state.hostRequests.isEmpty
                 ? "Everything's handled."
                 : "\(state.hostRequests.count) request\(state.hostRequests.count == 1 ? "" : "s") need you.")
                .font(Typo.display(28))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var earningsStrip: some View {
        HStack(spacing: Space.sm) {
            metricTile(Money.compact(state.hostEarningsToDate), label: "Earned", detail: "all time")
            metricTile(Money.compact(state.hostEarningsScheduled), label: "Scheduled", detail: "\(state.hostBookedTrips.count) trips")
            metricTile("\(state.myListings.count)", label: "Vehicles", detail: "listed")
        }
    }

    private func metricTile(_ value: String, label: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.8)
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .font(Typo.numeric(21))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(Typo.micro)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    private var requestsPreview: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(
                title: "Waiting on you",
                eyebrow: "Respond within 24 hours",
                actionTitle: "See all"
            ) {
                state.hostTab = .requests
            }

            ForEach(state.hostRequests.prefix(2)) { trip in
                HostRequestCard(trip: trip, isCompact: true) {
                    selectedTrip = trip
                }
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Upcoming trips")

            if state.hostBookedTrips.isEmpty {
                Card(padding: Space.md, elevation: .none, fill: Palette.surfaceSunken) {
                    Text("Nothing booked yet. Keep your calendar open and your price competitive and bookings tend to follow.")
                        .font(Typo.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(state.hostBookedTrips) { trip in
                    Button {
                        Haptics.tap()
                        selectedTrip = trip
                    } label: {
                        HostTripRow(trip: trip)
                    }
                    .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
                }
            }
        }
    }

    private var listingsPreview: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Your vehicles", actionTitle: "Manage") {
                state.hostTab = .listings
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Space.sm) {
                    ForEach(state.myListings) { car in
                        VStack(alignment: .leading, spacing: Space.xs) {
                            CarThumb(car: car, height: 104, radius: Radius.md)
                            Text(car.title)
                                .font(Typo.bodySemibold)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                            Text("\(Money.short(car.dailyPrice))/day · \(car.tripCount) trips")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        .frame(width: 170)
                    }

                    Button {
                        Haptics.tap()
                        showAddCar = true
                    } label: {
                        VStack(spacing: Space.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Palette.accent)
                            Text("Add a car")
                                .font(Typo.captionMedium)
                                .foregroundStyle(Palette.accent)
                        }
                        .frame(width: 130, height: 104)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .fill(Palette.accentWash)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .stroke(Palette.accent.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        )
                    }
                    .buttonStyle(PressableStyle(scale: 0.96, dimsOnPress: false))
                }
            }
        }
    }

    private var tipCard: some View {
        Card(padding: Space.lg, elevation: .none, fill: Palette.star.opacity(0.08)) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Label("Tip", systemImage: "lightbulb.fill")
                    .font(Typo.micro)
                    .foregroundStyle(Palette.star)
                Text("Reply within an hour")
                    .font(Typo.sectionTitle)
                    .foregroundStyle(Palette.ink)
                Text("Hosts who answer inside an hour get booked roughly twice as often. It counts towards All-Star status too.")
                    .font(Typo.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Requests

struct HostRequestsView: View {
    @Environment(AppState.self) private var state
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if state.hostRequests.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No open requests",
                        message: "New booking requests land here. You have 24 hours to accept before they expire."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Space.md) {
                            InlineNote(
                                icon: "clock.fill",
                                text: "Requests expire after 24 hours. Declining doesn't hurt your rating — letting one expire does.",
                                tint: Palette.star
                            )

                            ForEach(Array(state.hostRequests.enumerated()), id: \.element.id) { index, trip in
                                HostRequestCard(trip: trip, isCompact: false) {
                                    selectedTrip = trip
                                }
                                .appear(index)
                            }
                        }
                        .pageGutter()
                        .padding(.vertical, Space.md)
                        .padding(.bottom, Space.xxl)
                    }
                }
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTrip) { trip in
                HostTripDetailView(tripID: trip.id)
            }
        }
        .animation(Motion.content, value: state.hostRequests.count)
    }
}

struct HostRequestCard: View {
    let trip: Trip
    let isCompact: Bool
    let onTap: () -> Void

    @Environment(AppState.self) private var state

    private var car: Car? { state.car(trip.carID) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                Haptics.tap()
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack(spacing: Space.sm) {
                        Avatar(
                            initials: trip.guestName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined(),
                            seed: trip.guestName.count,
                            size: 42
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(trip.guestName)
                                .font(Typo.bodySemibold)
                                .foregroundStyle(Palette.ink)
                            Text("wants your \(car?.title ?? "car")")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                        }

                        Spacer(minLength: 0)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Money.full(trip.quote.hostEarnings))
                                .font(Typo.numeric(16))
                                .foregroundStyle(Palette.ink)
                            Text("you earn")
                                .font(Typo.micro)
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }

                    Hairline()

                    HStack(spacing: Space.md) {
                        infoPair("Dates", DateText.range(trip.startDate, trip.endDate))
                        infoPair("Length", "\(trip.dayCount) day\(trip.dayCount == 1 ? "" : "s")")
                        infoPair("Handoff", trip.handoff == .delivery ? "Delivery" : "Pickup")
                    }
                }
                .padding(Space.md)
            }
            .buttonStyle(PressableStyle(scale: 0.995, dimsOnPress: false))

            if !isCompact {
                Hairline()
                HStack(spacing: Space.sm) {
                    Button {
                        state.respondToRequest(trip, approve: false)
                    } label: {
                        Text("Decline")
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        state.respondToRequest(trip, approve: true)
                    } label: {
                        Text("Approve")
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.inkInverted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                    .fill(Palette.accent)
                            )
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(Space.sm)
            }
        }
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    private func infoPair(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.6)
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .font(Typo.captionMedium)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HostTripRow: View {
    let trip: Trip
    @Environment(AppState.self) private var state

    private var car: Car? { state.car(trip.carID) }

    var body: some View {
        HStack(spacing: Space.sm) {
            if let car {
                CarThumb(car: car, height: 60, radius: Radius.sm)
                    .frame(width: 84)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.guestName)
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                Text("\(car?.title ?? "") · \(DateText.range(trip.startDate, trip.endDate))")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineLimit(1)
                Text(DateText.countdown(to: trip.startDate))
                    .font(Typo.micro)
                    .foregroundStyle(Palette.accent)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 1) {
                Text(Money.short(trip.quote.hostEarnings))
                    .font(Typo.numeric(14))
                    .foregroundStyle(Palette.ink)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Host trip detail

struct HostTripDetailView: View {
    let tripID: UUID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private var trip: Trip? { state.trips.first { $0.id == tripID } }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if let trip, let car = state.car(trip.carID) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Space.lg) {
                            HStack(spacing: Space.sm) {
                                Avatar(
                                    initials: trip.guestName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined(),
                                    seed: trip.guestName.count,
                                    size: 56
                                )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(trip.guestName)
                                        .font(Typo.title)
                                        .foregroundStyle(Palette.ink)
                                    HStack(spacing: Space.xs) {
                                        StatusPill(status: trip.status)
                                        Badge(text: "Verified", icon: "checkmark.seal.fill", tint: Palette.success)
                                    }
                                }
                                Spacer(minLength: 0)
                            }

                            Card(padding: Space.md) {
                                VStack(alignment: .leading, spacing: Space.sm) {
                                    HStack(spacing: Space.sm) {
                                        CarThumb(car: car, height: 60, radius: Radius.sm)
                                            .frame(width: 84)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(car.fullTitle)
                                                .font(Typo.bodySemibold)
                                                .foregroundStyle(Palette.ink)
                                            Text(car.location.name)
                                                .font(Typo.caption)
                                                .foregroundStyle(Palette.inkSecondary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    Hairline()
                                    DetailRow(label: "Pick up", value: "\(DateText.withWeekday(trip.startDate)), \(DateText.clock(trip.startDate))", labelIcon: "calendar")
                                    DetailRow(label: "Return", value: "\(DateText.withWeekday(trip.endDate)), \(DateText.clock(trip.endDate))", labelIcon: "calendar")
                                    DetailRow(label: trip.handoff.label, value: trip.handoffAddress, labelIcon: trip.handoff.symbol)
                                    DetailRow(label: "Protection", value: trip.protection.label, labelIcon: "shield.lefthalf.filled")
                                }
                            }

                            VStack(alignment: .leading, spacing: Space.sm) {
                                SectionHeader(title: "Your payout")
                                Card(padding: Space.md) {
                                    VStack(spacing: Space.sm) {
                                        DetailRow(label: "Trip total paid by guest", value: Money.full(trip.quote.total))
                                        DetailRow(label: "Protection and fees", value: "−\(Money.full(trip.quote.total - trip.quote.hostEarnings))", valueColor: Palette.inkSecondary)
                                        Hairline()
                                        DetailRow(label: "You receive", value: Money.full(trip.quote.hostEarnings), isEmphasised: true, valueColor: Palette.success)
                                        Text("Paid out 3 hours after the trip starts.")
                                            .font(Typo.caption)
                                            .foregroundStyle(Palette.inkTertiary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }

                            if trip.status == .requested {
                                VStack(spacing: Space.sm) {
                                    PrimaryButton(title: "Approve this booking", icon: "checkmark") {
                                        state.respondToRequest(trip, approve: true)
                                        dismiss()
                                    }
                                    SecondaryButton(title: "Decline", isDestructive: true) {
                                        state.respondToRequest(trip, approve: false)
                                        dismiss()
                                    }
                                }
                            } else {
                                SecondaryButton(title: "Message \(trip.guestName.split(separator: " ").first.map(String.init) ?? "guest")", icon: "bubble.left.fill") {
                                    state.show(Toast(message: "Opening thread", style: .info))
                                }
                            }
                        }
                        .pageGutter()
                        .padding(.vertical, Space.md)
                        .padding(.bottom, Space.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
    }
}
