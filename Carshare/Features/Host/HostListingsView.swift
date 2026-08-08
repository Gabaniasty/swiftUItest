import SwiftUI

// MARK: - Listings

struct HostListingsView: View {
    @Environment(AppState.self) private var state
    @State private var showAddCar = false
    @State private var editing: Car?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if state.myListings.isEmpty {
                    EmptyStateView(
                        icon: "car.2",
                        title: "No vehicles listed",
                        message: "Add your first car and it'll be visible to guests in about ten minutes.",
                        actionTitle: "Add a car"
                    ) {
                        showAddCar = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: Space.md) {
                            ForEach(Array(state.myListings.enumerated()), id: \.element.id) { index, car in
                                Button {
                                    Haptics.tap()
                                    editing = car
                                } label: {
                                    ListingManageCard(car: car)
                                }
                                .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
                                .appear(index)
                            }
                        }
                        .pageGutter()
                        .padding(.vertical, Space.md)
                        .padding(.bottom, Space.xxl)
                    }
                }
            }
            .navigationTitle("Vehicles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAddCar = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showAddCar) { AddCarFlowView() }
            .sheet(item: $editing) { car in
                ListingEditorView(carID: car.id)
            }
        }
        .animation(Motion.content, value: state.myListings.count)
    }
}

private struct ListingManageCard: View {
    let car: Car
    @Environment(AppState.self) private var state

    private var upcomingCount: Int {
        state.trips.filter { $0.isHostSide && $0.carID == car.id && [.upcoming, .active, .requested].contains($0.status) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CarThumb(car: car, height: 150, radius: Radius.lg, variant: .threeQuarter)

                HStack(spacing: Space.xs) {
                    Badge(text: "Live", icon: "dot.radiowaves.left.and.right", tint: .white)
                        .background(Capsule().fill(Palette.success.opacity(0.9)))
                }
                .padding(Space.sm)
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(car.fullTitle)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: Space.xs)
                    Text("\(Money.short(car.dailyPrice))/day")
                        .font(Typo.numeric(15))
                        .foregroundStyle(Palette.ink)
                }

                HStack(spacing: Space.md) {
                    stat("\(car.tripCount)", label: "Trips")
                    stat(car.tripCount > 0 ? String(format: "%.2f", car.rating) : "—", label: "Rating")
                    stat("\(upcomingCount)", label: "Booked")
                    stat("\(car.blockedDates.count)", label: "Blocked")
                }

                Hairline()

                HStack(spacing: Space.xs) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Tap to edit price, availability and rules")
                        .font(Typo.caption)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Palette.inkTertiary)
            }
            .padding(Space.md)
        }
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(Typo.numeric(15))
                .foregroundStyle(Palette.ink)
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.6)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Listing editor
//
// Edits a working copy and commits on save. Price changes preview the effect on a
// typical three-day booking, because a host raising a daily rate is really asking
// "what does this do to my payout".

struct ListingEditorView: View {
    let carID: UUID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Car?
    @State private var showDeleteDialog = false

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if let binding = Binding($draft) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Space.xl) {
                            CarThumb(car: binding.wrappedValue, height: 170, radius: Radius.lg)

                            pricing(binding)
                            tripRules(binding)
                            mileage(binding)
                            instantBook(binding)
                            availabilityBlock(binding.wrappedValue)
                            dangerZone
                        }
                        .pageGutter()
                        .padding(.vertical, Space.md)
                        .padding(.bottom, Space.xxl)
                    }
                }
            }
            .navigationTitle(draft?.title ?? "Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.font(Typo.bodyMedium)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let draft { state.updateListing(draft) }
                        dismiss()
                    }
                    .font(Typo.bodySemibold)
                }
            }
            .confirmationDialog("Unlist this car?", isPresented: $showDeleteDialog, titleVisibility: .visible) {
                Button("Unlist", role: .destructive) {
                    if let draft { state.removeListing(draft) }
                    dismiss()
                }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text("It disappears from search straight away. Trips already booked are unaffected.")
            }
            .onAppear { draft = state.car(carID) }
        }
    }

    private func pricing(_ car: Binding<Car>) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Daily price")

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Money.short(car.wrappedValue.dailyPrice))
                            .font(Typo.display(30))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                        Text("per day")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                        Spacer()
                    }

                    Slider(value: car.dailyPrice, in: 25...500, step: 1)
                        .tint(Palette.accent)

                    Hairline()

                    DetailRow(
                        label: "You'd earn on a 3-day booking",
                        value: Money.full(car.wrappedValue.dailyPrice * 3 * 0.93 * 0.75),
                        isEmphasised: true,
                        valueColor: Palette.success
                    )

                    Text("After the 3-day guest discount and the 25% service fee.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .animation(Motion.snap, value: car.wrappedValue.dailyPrice)

            InlineNote(
                icon: "chart.line.uptrend.xyaxis",
                text: "Similar cars near you go for $72–$118 a day. Pricing in that band gets booked fastest.",
                tint: Palette.info
            )
        }
    }

    private func tripRules(_ car: Binding<Car>) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Trip length")
            Card(padding: Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Minimum days")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        Text("Shorter requests are turned away automatically.")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Space.xs)
                    CounterControl(value: car.minTripDays, range: 1...14)
                }
            }
        }
    }

    private func mileage(_ car: Binding<Car>) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Mileage")
            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    HStack {
                        Text("Included per day")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(car.wrappedValue.includedMilesPerDay) mi")
                            .font(Typo.numeric(15))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                    }
                    Slider(
                        value: Binding(
                            get: { Double(car.wrappedValue.includedMilesPerDay) },
                            set: { car.wrappedValue.includedMilesPerDay = Int($0) }
                        ),
                        in: 50...400,
                        step: 25
                    )
                    .tint(Palette.accent)

                    Hairline()

                    HStack {
                        Text("Charge per extra mile")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text(Money.full(car.wrappedValue.extraMileFee))
                            .font(Typo.numeric(15))
                            .foregroundStyle(Palette.ink)
                    }
                    Slider(value: car.extraMileFee, in: 0.25...2.5, step: 0.05)
                        .tint(Palette.accent)
                }
            }
            .animation(Motion.snap, value: car.wrappedValue.includedMilesPerDay)
        }
    }

    private func instantBook(_ car: Binding<Car>) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Booking")
            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    Toggle(isOn: car.isInstantBook) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Instant book")
                                .font(Typo.bodyMedium)
                                .foregroundStyle(Palette.ink)
                            Text("Guests book without waiting for you. Listings with it on get roughly 30% more trips.")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Palette.accent)

                    Hairline()

                    Toggle(isOn: Binding(
                        get: { car.wrappedValue.deliveryFee != nil },
                        set: { car.wrappedValue.deliveryFee = $0 ? 40 : nil }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Offer delivery")
                                .font(Typo.bodyMedium)
                                .foregroundStyle(Palette.ink)
                            Text("You drop the car off at the guest's address.")
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }
                    .tint(Palette.accent)

                    if let fee = car.wrappedValue.deliveryFee {
                        Hairline()
                        HStack {
                            Text("Delivery fee")
                                .font(Typo.bodyMedium)
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text(Money.short(fee))
                                .font(Typo.numeric(15))
                                .foregroundStyle(Palette.ink)
                        }
                        Slider(
                            value: Binding(
                                get: { car.wrappedValue.deliveryFee ?? 40 },
                                set: { car.wrappedValue.deliveryFee = $0 }
                            ),
                            in: 10...150,
                            step: 5
                        )
                        .tint(Palette.accent)
                    }
                }
            }
            .animation(Motion.snap, value: car.wrappedValue.deliveryFee)
        }
    }

    private func availabilityBlock(_ car: Car) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Availability", eyebrow: "\(car.blockedDates.count) days blocked")
            AvailabilityCalendar(
                blockedDates: car.blockedDates,
                selectedRange: Date()...Date()
            )
            Text("Blocked days are shown crossed out. Editing them isn't wired up in this prototype.")
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    private var dangerZone: some View {
        SecondaryButton(title: "Unlist this car", icon: "trash", isDestructive: true) {
            showDeleteDialog = true
        }
    }
}
