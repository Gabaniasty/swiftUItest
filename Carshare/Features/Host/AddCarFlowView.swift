import SwiftUI

// MARK: - Add a car
//
// Six steps that mirror a real onboarding: vehicle → details → photos → features →
// price → publish. The earnings estimate updates from the very first step so the host
// always sees why they're filling the form in.

struct AddCarFlowView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .vehicle
    @State private var isAdvancing = true
    @State private var isPublishing = false

    // Form
    @State private var make = ""
    @State private var model = ""
    @State private var year = 2022
    @State private var trim = ""
    @State private var bodyType: BodyType = .car
    @State private var transmission: Transmission = .automatic
    @State private var fuel: FuelKind = .gas
    @State private var seats = 5
    @State private var doors = 4
    @State private var efficiency = 30
    @State private var paint: CarPaint = .midnight
    @State private var capturedPhotos: Set<Int> = []
    @State private var amenities: Set<Amenity> = [.bluetooth, .backupCamera, .appleCarPlay]
    @State private var dailyPrice: Double = 85
    @State private var minTripDays = 1
    @State private var includedMiles = 200
    @State private var instantBook = true
    @State private var offersDelivery = false
    @State private var locationName = "Mission District"
    @State private var blurb = ""

    enum Step: Int, CaseIterable {
        case vehicle, spec, photos, features, price, publish

        var title: String {
            switch self {
            case .vehicle: "What are you listing?"
            case .spec: "Tell us about it"
            case .photos: "Add photos"
            case .features: "What does it have?"
            case .price: "Set your price"
            case .publish: "Ready to publish"
            }
        }
    }

    /// Prototype earnings model: rate, minus the guest discount, minus the service fee,
    /// assuming a fairly typical twelve booked days a month.
    private var monthlyEstimate: Double {
        dailyPrice * 12 * 0.93 * 0.75
    }

    private var canAdvance: Bool {
        switch step {
        case .vehicle:
            return !make.trimmingCharacters(in: .whitespaces).isEmpty
                && !model.trimmingCharacters(in: .whitespaces).isEmpty
        case .spec: return true
        case .photos: return capturedPhotos.count >= 3
        case .features: return true
        case .price: return dailyPrice >= 25
        case .publish: return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg) {
                        header

                        Group {
                            switch step {
                            case .vehicle: vehicleStep
                            case .spec: specStep
                            case .photos: photosStep
                            case .features: featuresStep
                            case .price: priceStep
                            case .publish: publishStep
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
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("List your car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(step == .vehicle ? "Cancel" : "Back") {
                        Haptics.tap()
                        if step == .vehicle { dismiss() } else { goBack() }
                    }
                    .font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
        .animation(Motion.move, value: step)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            ProgressTrack(current: step.rawValue, total: Step.allCases.count)

            VStack(alignment: .leading, spacing: 2) {
                Text("Step \(step.rawValue + 1) of \(Step.allCases.count)".uppercased())
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

    // MARK: Step 1

    private var vehicleStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            field("Make", text: $make, placeholder: "Toyota, BMW, Tesla…")
            field("Model", text: $model, placeholder: "Corolla, 3 Series, Model Y…")
            field("Trim", text: $trim, placeholder: "Optional — Sport, Long Range…")

            VStack(alignment: .leading, spacing: Space.xs) {
                label("Year")
                Picker("Year", selection: $year) {
                    ForEach(Array((2005...2025).reversed()), id: \.self) { value in
                        Text(String(value)).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.ink)
                .padding(.horizontal, Space.sm)
                .frame(height: 48, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .stroke(Palette.hairlineStrong, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                label("Body type")
                WrapLayout {
                    ForEach(BodyType.allCases) { type in
                        Chip(title: type.label, isSelected: bodyType == type) {
                            withAnimation(Motion.snap) { bodyType = type }
                        }
                    }
                }
            }
        }
    }

    // MARK: Step 2

    private var specStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            VStack(alignment: .leading, spacing: Space.xs) {
                label("Transmission")
                HStack(spacing: Space.xs) {
                    ForEach(Transmission.allCases) { option in
                        Chip(title: option.label, isSelected: transmission == option) {
                            withAnimation(Motion.snap) { transmission = option }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                label("Fuel")
                HStack(spacing: Space.xs) {
                    ForEach(FuelKind.allCases) { option in
                        Chip(title: option.label, icon: option.symbol, isSelected: fuel == option) {
                            withAnimation(Motion.snap) {
                                fuel = option
                                efficiency = option == .electric ? 280 : 30
                            }
                        }
                    }
                }
            }

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    HStack {
                        Text("Seats").font(Typo.bodyMedium).foregroundStyle(Palette.ink)
                        Spacer()
                        CounterControl(value: $seats, range: 2...9)
                    }
                    Hairline()
                    HStack {
                        Text("Doors").font(Typo.bodyMedium).foregroundStyle(Palette.ink)
                        Spacer()
                        CounterControl(value: $doors, range: 2...5)
                    }
                    Hairline()
                    HStack {
                        Text(fuel == .electric ? "Range (miles)" : "MPG combined")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(efficiency)")
                            .font(Typo.numeric(15))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                    }
                    Slider(
                        value: Binding(
                            get: { Double(efficiency) },
                            set: { efficiency = Int($0) }
                        ),
                        in: fuel == .electric ? 100...500 : 12...60,
                        step: fuel == .electric ? 10 : 1
                    )
                    .tint(Palette.accent)
                }
            }
            .animation(Motion.snap, value: efficiency)

            VStack(alignment: .leading, spacing: Space.xs) {
                label("Colour")
                WrapLayout {
                    ForEach(CarPaint.allCases, id: \.self) { option in
                        Button {
                            Haptics.select()
                            withAnimation(Motion.snap) { paint = option }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(LinearGradient(colors: option.backdrop, startPoint: .top, endPoint: .bottom))
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Palette.hairlineStrong, lineWidth: 0.5))
                                Text(option.label)
                                    .font(Typo.captionMedium)
                                    .foregroundStyle(paint == option ? Palette.inkInverted : Palette.ink)
                            }
                            .padding(.horizontal, Space.sm)
                            .frame(height: 34)
                            .background(Capsule().fill(paint == option ? Palette.ink : Palette.surface))
                            .overlay(Capsule().stroke(paint == option ? .clear : Palette.hairlineStrong, lineWidth: 1))
                        }
                        .buttonStyle(PressableStyle(scale: 0.95, dimsOnPress: false))
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                label("One-line description")
                TextField("The one you book for the coast road.", text: $blurb, axis: .vertical)
                    .font(Typo.body)
                    .lineLimit(2...4)
                    .padding(Space.sm)
                    .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Palette.hairlineStrong, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: Step 3

    private var photosStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            InlineNote(
                icon: "camera.fill",
                text: "Listings with six or more photos get booked about twice as often. Three is the minimum.",
                tint: Palette.info
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Space.sm), GridItem(.flexible(), spacing: Space.sm)],
                spacing: Space.sm
            ) {
                ForEach(0..<6, id: \.self) { index in
                    photoSlot(index)
                }
            }

            Text("\(capturedPhotos.count) of 6 added")
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)
                .contentTransition(.numericText())
        }
    }

    private func photoSlot(_ index: Int) -> some View {
        let isFilled = capturedPhotos.contains(index)
        let previewCar = previewVehicle

        return Button {
            Haptics.tap()
            withAnimation(Motion.enter) {
                if isFilled { capturedPhotos.remove(index) } else { capturedPhotos.insert(index) }
            }
        } label: {
            ZStack {
                if isFilled {
                    CarArtwork(
                        car: previewCar,
                        variant: ArtVariant(rawValue: index % ArtVariant.allCases.count) ?? .hero
                    )
                } else {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Palette.surfaceSunken)
                    VStack(spacing: 5) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.inkTertiary)
                        if index == 0 {
                            Text("Cover photo")
                                .font(Typo.micro)
                                .foregroundStyle(Palette.inkSecondary)
                        }
                    }
                }

                if isFilled {
                    VStack {
                        HStack {
                            if index == 0 {
                                Text("COVER")
                                    .font(Typo.micro)
                                    .tracking(0.8)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(.black.opacity(0.5)))
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Palette.accent))
                        }
                        Spacer()
                    }
                    .padding(Space.xs)
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(
                        isFilled ? Palette.accent.opacity(0.5) : Palette.hairlineStrong,
                        style: StrokeStyle(lineWidth: 1, dash: isFilled ? [] : [4, 3])
                    )
            )
        }
        .buttonStyle(PressableStyle(scale: 0.96, dimsOnPress: false))
    }

    // MARK: Step 4

    private var featuresStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("Pick everything that applies. Guests filter on these, so being thorough gets you found.")
                .font(Typo.body)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            WrapLayout {
                ForEach(Amenity.allCases) { amenity in
                    Chip(title: amenity.label, icon: amenity.symbol, isSelected: amenities.contains(amenity)) {
                        withAnimation(Motion.snap) {
                            if amenities.contains(amenity) { amenities.remove(amenity) } else { amenities.insert(amenity) }
                        }
                    }
                }
            }

            Text("\(amenities.count) selected")
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)

            VStack(alignment: .leading, spacing: Space.xs) {
                label("Where do guests collect it?")
                TextField("Neighbourhood or street", text: $locationName)
                    .font(Typo.body)
                    .padding(Space.sm)
                    .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Palette.hairlineStrong, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: Step 5

    private var priceStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Money.short(dailyPrice))
                            .font(Typo.display(36))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                        Text("per day")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                        Spacer()
                    }

                    Slider(value: $dailyPrice, in: 25...500, step: 1)
                        .tint(Palette.accent)

                    HStack {
                        Text("$25").font(Typo.micro).foregroundStyle(Palette.inkTertiary)
                        Spacer()
                        Text("$500").font(Typo.micro).foregroundStyle(Palette.inkTertiary)
                    }
                }
            }
            .animation(Motion.snap, value: dailyPrice)

            Card(padding: Space.md, fill: Palette.accentWash) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Estimated monthly earnings")
                        .font(Typo.eyebrow)
                        .tracking(1.1)
                        .foregroundStyle(Palette.inkTertiary)
                    Text(Money.short(monthlyEstimate))
                        .font(Typo.display(28))
                        .foregroundStyle(Palette.success)
                        .contentTransition(.numericText())
                    Text("Assuming 12 booked days a month, after the 25% service fee.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .animation(Motion.snap, value: monthlyEstimate)

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    HStack {
                        Text("Minimum trip length").font(Typo.bodyMedium).foregroundStyle(Palette.ink)
                        Spacer()
                        CounterControl(value: $minTripDays, range: 1...14)
                    }
                    Hairline()
                    HStack {
                        Text("Miles included per day").font(Typo.bodyMedium).foregroundStyle(Palette.ink)
                        Spacer()
                        Text("\(includedMiles)")
                            .font(Typo.numeric(15))
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText())
                    }
                    Slider(
                        value: Binding(get: { Double(includedMiles) }, set: { includedMiles = Int($0) }),
                        in: 50...400,
                        step: 25
                    )
                    .tint(Palette.accent)
                    Hairline()
                    Toggle("Instant book", isOn: $instantBook)
                        .font(Typo.bodyMedium)
                        .tint(Palette.accent)
                    Toggle("Offer delivery", isOn: $offersDelivery)
                        .font(Typo.bodyMedium)
                        .tint(Palette.accent)
                }
            }
            .animation(Motion.snap, value: includedMiles)
        }
    }

    // MARK: Step 6

    private var publishStep: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            CarCardPreview(car: previewVehicle)

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DetailRow(label: "Vehicle", value: "\(year) \(make) \(model)")
                    DetailRow(label: "Type", value: "\(bodyType.label) · \(seats) seats")
                    DetailRow(label: "Gearbox", value: transmission.label)
                    DetailRow(label: "Fuel", value: fuel.label)
                    DetailRow(label: "Photos", value: "\(capturedPhotos.count)")
                    DetailRow(label: "Features", value: "\(amenities.count)")
                    DetailRow(label: "Pickup", value: locationName)
                    Hairline()
                    DetailRow(label: "Daily price", value: Money.short(dailyPrice), isEmphasised: true)
                }
            }

            InlineNote(
                icon: "checkmark.shield.fill",
                text: "In the real product your car would be checked against DMV records before going live. Here it publishes immediately.",
                tint: Palette.inkSecondary
            )
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Hairline()
            VStack(spacing: Space.xs) {
                if step != .publish {
                    HStack {
                        Text("Estimated monthly earnings")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                        Spacer()
                        Text(Money.short(monthlyEstimate))
                            .font(Typo.numeric(15))
                            .foregroundStyle(Palette.success)
                            .contentTransition(.numericText())
                    }
                }

                PrimaryButton(
                    title: step == .publish ? "Publish listing" : "Continue",
                    icon: step == .publish ? "checkmark" : nil,
                    isEnabled: canAdvance,
                    isLoading: isPublishing
                ) {
                    if step == .publish { publish() } else { goForward() }
                }

                if step == .photos, capturedPhotos.count < 3 {
                    Text("Add at least three photos to continue.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.sm)
        }
        .background(.regularMaterial)
        .animation(Motion.snap, value: monthlyEstimate)
    }

    // MARK: Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Typo.eyebrow)
            .tracking(1.1)
            .foregroundStyle(Palette.inkTertiary)
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            label(title)
            TextField(placeholder, text: text)
                .font(Typo.bodyLarge)
                .autocorrectionDisabled()
                .padding(.horizontal, Space.sm)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .stroke(Palette.hairlineStrong, lineWidth: 1)
                )
        }
    }

    /// Live preview object. Built from the form so the card at the end is genuinely
    /// what gets published.
    private var previewVehicle: Car {
        Car(
            id: UUID(),
            make: make.isEmpty ? "Your" : make,
            model: model.isEmpty ? "Car" : model,
            year: year,
            trim: trim,
            bodyType: bodyType,
            transmission: transmission,
            fuel: fuel,
            seats: seats,
            doors: doors,
            efficiency: efficiency,
            dailyPrice: dailyPrice,
            listPrice: nil,
            rating: 0,
            tripCount: 0,
            hostID: SampleData.meHostID,
            location: PickupLocation(
                name: locationName.isEmpty ? "Your neighbourhood" : locationName,
                detail: "Exact spot shared after booking",
                latitude: 37.7554,
                longitude: -122.4205
            ),
            distanceMiles: 0,
            amenities: Array(amenities).sorted { $0.rawValue < $1.rawValue },
            blurb: blurb.isEmpty ? "Newly listed." : blurb,
            details: blurb.isEmpty ? "This listing was created in the prototype." : blurb,
            rules: ["No smoking", "Return with the same fuel level"],
            isInstantBook: instantBook,
            deliveryFee: offersDelivery ? 40 : nil,
            paint: paint,
            photoCount: max(1, capturedPhotos.count),
            minTripDays: minTripDays,
            includedMilesPerDay: includedMiles,
            extraMileFee: 0.55,
            isNewListing: true,
            blockedDates: []
        )
    }

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

    private func publish() {
        isPublishing = true
        Task {
            try? await Task.sleep(for: .milliseconds(1100))
            await MainActor.run {
                state.addListing(previewVehicle)
                isPublishing = false
                state.hostTab = .listings
                dismiss()
            }
        }
    }
}

// MARK: - Preview card
//
// Deliberately the same composition as the guest-facing result card, so a host sees
// exactly what a guest will.

struct CarCardPreview: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("How guests will see it".uppercased())
                .font(Typo.eyebrow)
                .tracking(1.1)
                .foregroundStyle(Palette.inkTertiary)

            VStack(alignment: .leading, spacing: Space.sm) {
                CarThumb(car: car, height: 168, radius: Radius.md)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(car.title)
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Text(String(car.year))
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                        Spacer()
                        Text("New")
                            .font(Typo.micro)
                            .foregroundStyle(Palette.info)
                    }

                    Label(car.location.name, systemImage: "mappin.and.ellipse")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        if car.isInstantBook {
                            Badge(text: "Instant book", icon: "bolt.fill")
                        }
                        Spacer()
                        Text(Money.short(car.dailyPrice))
                            .font(Typo.numeric(17))
                            .foregroundStyle(Palette.ink)
                        Text("/day")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
            }
            .padding(Space.sm)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
        }
    }
}
