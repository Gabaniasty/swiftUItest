import SwiftUI

// MARK: - Trips
//
// Booked and history. The soonest trip gets a larger card with the live action on it —
// on the day of a rental that action is the only thing the guest opens the app for.

struct TripsView: View {
    @Environment(AppState.self) private var state
    @State private var scope: Scope = .booked
    @State private var selectedTrip: Trip?

    enum Scope: String, CaseIterable {
        case booked, history
        var label: String { self == .booked ? "Booked" : "History" }
    }

    private var trips: [Trip] {
        scope == .booked ? state.upcomingTrips : state.pastTrips
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg) {
                        Picker("Scope", selection: $scope) {
                            ForEach(Scope.allCases, id: \.self) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        if trips.isEmpty {
                            let isBooked = scope == .booked
                            let emptyActionTitle: String? = isBooked ? "Find a car" : nil
                            let emptyAction: (() -> Void)? = isBooked ? { state.selectedTab = .explore } : nil

                            EmptyStateView(
                                icon: isBooked ? "car.side" : "clock.arrow.circlepath",
                                title: isBooked ? "No trips booked" : "No past trips",
                                message: isBooked
                                    ? "When you book a car it'll show up here with everything you need for pickup."
                                    : "Finished trips and their receipts live here.",
                                actionTitle: emptyActionTitle,
                                action: emptyAction
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, Space.xxl)
                        } else {
                            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                                Button {
                                    Haptics.tap()
                                    selectedTrip = trip
                                } label: {
                                    if index == 0 && scope == .booked {
                                        FeaturedTripCard(trip: trip)
                                    } else {
                                        TripCard(trip: trip)
                                    }
                                }
                                .buttonStyle(PressableStyle(scale: 0.985, dimsOnPress: false))
                                .appear(index)
                            }
                        }
                    }
                    .pageGutter()
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
            }
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTrip) { trip in
                TripDetailView(tripID: trip.id)
            }
        }
        .animation(Motion.content, value: scope)
    }
}

// MARK: - Featured card
//
// The next trip. Carries the countdown and the one action that matters at this stage
// of the trip's life.

struct FeaturedTripCard: View {
    let trip: Trip
    @Environment(AppState.self) private var state

    private var car: Car? { state.car(trip.carID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let car {
                ZStack(alignment: .topLeading) {
                    CarArtwork(car: car, variant: .threeQuarter)
                        .frame(height: 176)

                    HStack(spacing: Space.xs) {
                        StatusPill(status: trip.status)
                        if trip.status == .upcoming || trip.status == .requested {
                            Text(DateText.countdown(to: trip.startDate))
                                .font(Typo.micro)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.black.opacity(0.42)))
                        }
                    }
                    .padding(Space.sm)
                }
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                Text(car?.fullTitle ?? "Trip")
                    .font(Typo.sectionTitle)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                HStack(spacing: Space.md) {
                    infoBlock("Pick up", DateText.withWeekday(trip.startDate), DateText.clock(trip.startDate))
                    Divider().frame(height: 34)
                    infoBlock("Return", DateText.withWeekday(trip.endDate), DateText.clock(trip.endDate))
                }

                Hairline()

                HStack(spacing: Space.xs) {
                    Image(systemName: Symbols.resolve(trip.handoff.symbol, fallback: "mappin"))
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.inkTertiary)
                    Text(trip.handoffAddress)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text(Money.full(trip.quote.total))
                        .font(Typo.numeric(14))
                        .foregroundStyle(Palette.ink)
                }
            }
            .padding(Space.md)
        }
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .elevation(.mid)
    }

    private func infoBlock(_ label: String, _ value: String, _ time: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.7)
                .foregroundStyle(Palette.inkTertiary)
            Text(value)
                .font(Typo.bodyMedium)
                .foregroundStyle(Palette.ink)
            Text(time)
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Standard card

struct TripCard: View {
    let trip: Trip
    @Environment(AppState.self) private var state

    private var car: Car? { state.car(trip.carID) }

    var body: some View {
        HStack(spacing: Space.sm) {
            if let car {
                CarThumb(car: car, height: 84, radius: Radius.md)
                    .frame(width: 112)
                    .saturation(trip.status == .cancelled || trip.status == .declined ? 0.25 : 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                StatusPill(status: trip.status)

                Text(car?.title ?? "Trip")
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(DateText.range(trip.startDate, trip.endDate))
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)

                Text(Money.full(trip.quote.total))
                    .font(Typo.numeric(13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let status: TripStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: Symbols.resolve(status.symbol, fallback: "circle.fill"))
                .font(.system(size: 9, weight: .bold))
            Text(status.label.uppercased())
                .font(Typo.micro)
                .tracking(0.6)
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(status.tint.opacity(0.14)))
    }
}
