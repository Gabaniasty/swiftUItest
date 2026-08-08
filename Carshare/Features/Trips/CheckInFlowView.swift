import SwiftUI

// MARK: - Check-in
//
// Six angles, a fuel reading and a confirmation. Modelled on the real thing because
// the photo step is the part of a car-share app that actually protects both sides —
// and it is the flow most worth prototyping properly.

struct CheckInFlowView: View {
    let trip: Trip

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var captured: Set<PhotoAngle> = []
    @State private var fuelLevel: Double = 1.0
    @State private var odometer: String = "48,210"
    @State private var notes: String = ""
    @State private var stage: Stage = .photos

    private enum Stage { case photos, condition, done }

    enum PhotoAngle: String, CaseIterable, Identifiable {
        case frontLeft, front, frontRight, rearRight, rear, interior

        var id: String { rawValue }

        var label: String {
            switch self {
            case .frontLeft: "Front left"
            case .front: "Front"
            case .frontRight: "Front right"
            case .rearRight: "Rear right"
            case .rear: "Rear"
            case .interior: "Interior"
            }
        }

        var variant: ArtVariant {
            switch self {
            case .frontLeft, .front: .hero
            case .frontRight, .rearRight: .threeQuarter
            case .rear: .parked
            case .interior: .interior
            }
        }
    }

    private var car: Car? { state.car(trip.carID) }
    private var allCaptured: Bool { captured.count == PhotoAngle.allCases.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg) {
                        header

                        switch stage {
                        case .photos: photoGrid
                        case .condition: conditionForm
                        case .done: EmptyView()
                        }
                    }
                    .pageGutter()
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
            }
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(stage == .photos ? "Cancel" : "Back") {
                        Haptics.tap()
                        if stage == .photos {
                            dismiss()
                        } else {
                            withAnimation(Motion.move) { stage = .photos }
                        }
                    }
                    .font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(stage == .photos ? "Photograph the car" : "Note the condition")
                .font(Typo.display(26))
                .foregroundStyle(Palette.ink)

            Text(stage == .photos
                 ? "Six angles before you drive away. If there's existing damage, this is what proves it wasn't you."
                 : "Record the fuel level and anything you noticed. The host sees this immediately.")
                .font(Typo.body)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if stage == .photos {
                HStack(spacing: Space.xs) {
                    Text("\(captured.count) of \(PhotoAngle.allCases.count)")
                        .font(Typo.numeric(13))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    Text("captured")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
                .padding(.top, Space.xxs)
                .animation(Motion.snap, value: captured.count)
            }
        }
    }

    // MARK: Photos

    private var photoGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Space.sm), GridItem(.flexible(), spacing: Space.sm)],
            spacing: Space.sm
        ) {
            ForEach(PhotoAngle.allCases) { angle in
                photoSlot(angle)
            }
        }
    }

    private func photoSlot(_ angle: PhotoAngle) -> some View {
        let isCaptured = captured.contains(angle)

        return Button {
            Haptics.tap()
            withAnimation(Motion.enter) {
                if isCaptured { captured.remove(angle) } else { captured.insert(angle) }
            }
            if captured.count == PhotoAngle.allCases.count { Haptics.success() }
        } label: {
            ZStack {
                if isCaptured, let car {
                    CarArtwork(car: car, variant: angle.variant)
                } else {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Palette.surfaceSunken)
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.inkTertiary)
                        Text(angle.label)
                            .font(Typo.captionMedium)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }

                if isCaptured {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 19))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Palette.accent))
                        }
                        Spacer()
                        HStack {
                            Text(angle.label)
                                .font(Typo.micro)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.black.opacity(0.45)))
                            Spacer()
                        }
                    }
                    .padding(Space.xs)
                }
            }
            .frame(height: 116)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isCaptured ? Palette.accent.opacity(0.6) : Palette.hairlineStrong,
                            style: StrokeStyle(lineWidth: 1, dash: isCaptured ? [] : [4, 3]))
            )
        }
        .buttonStyle(PressableStyle(scale: 0.96, dimsOnPress: false))
    }

    // MARK: Condition

    private var conditionForm: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack {
                    Text(car?.fuel == .electric ? "Charge level" : "Fuel level")
                        .font(Typo.bodyMedium)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(Int(fuelLevel * 100))%")
                        .font(Typo.numeric(15))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                }

                Slider(value: $fuelLevel, in: 0...1, step: 0.05)
                    .tint(Palette.accent)

                HStack {
                    Text("Empty").font(Typo.micro).foregroundStyle(Palette.inkTertiary)
                    Spacer()
                    Text("Full").font(Typo.micro).foregroundStyle(Palette.inkTertiary)
                }

                InlineNote(
                    icon: "info.circle.fill",
                    text: car?.fuel == .electric
                        ? "Return it at this level or above to avoid a recharging fee."
                        : "Return it at this level to avoid a refuelling fee.",
                    tint: Palette.info
                )
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Odometer reading")
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Palette.ink)
                TextField("Miles", text: $odometer)
                    .keyboardType(.numberPad)
                    .font(Typo.numeric(17, weight: .medium))
                    .padding(Space.sm)
                    .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Palette.hairlineStrong, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Anything to flag?")
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Palette.ink)
                TextField("Existing scratches, a warning light, low tyre…", text: $notes, axis: .vertical)
                    .font(Typo.body)
                    .lineLimit(3...6)
                    .padding(Space.sm)
                    .background(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(Palette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Palette.hairlineStrong, lineWidth: 1)
                    )
                Text("Optional, but worth doing. It's timestamped and both of you keep a copy.")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                SectionHeader(title: "Your photos")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Space.xs) {
                        ForEach(Array(captured).sorted(by: { $0.rawValue < $1.rawValue })) { angle in
                            if let car {
                                CarArtwork(car: car, variant: angle.variant)
                                    .frame(width: 92, height: 68)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Hairline()
            VStack(spacing: Space.xs) {
                PrimaryButton(
                    title: stage == .photos
                        ? (allCaptured ? "Continue" : "Take all six photos")
                        : "Finish check-in",
                    icon: stage == .photos ? nil : "checkmark",
                    isEnabled: stage == .photos ? allCaptured : true
                ) {
                    if stage == .photos {
                        withAnimation(Motion.move) { stage = .condition }
                    } else {
                        state.checkIn(trip, photoCount: captured.count)
                        dismiss()
                    }
                }

                if stage == .photos, !allCaptured {
                    Text("Tap each panel to capture it.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .padding(Space.md)
        }
        .background(.regularMaterial)
    }
}
