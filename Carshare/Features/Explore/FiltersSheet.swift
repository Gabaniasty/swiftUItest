import SwiftUI

// MARK: - Filters
//
// Edits a local copy and only commits on "Show cars", so backing out of the sheet
// leaves the results exactly as they were.

struct FiltersSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var draft = SearchFilters()

    /// Live count against the uncommitted draft, so the button tells the truth before
    /// the user commits. Read-only — nothing in app state moves until "Show cars".
    private var matchCount: Int {
        state.results(for: draft).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    sortSection
                    priceSection
                    vehicleTypeSection
                    seatsSection
                    ratingSection
                    mechanicalSection
                    bookingSection
                    featuresSection
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(Typo.bodyMedium)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear all") {
                        withAnimation(Motion.content) { draft = SearchFilters() }
                        Haptics.tap()
                    }
                    .font(Typo.bodyMedium)
                    .disabled(draft.isDefault)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Hairline()
                    PrimaryButton(
                        title: matchCount == 0 ? "No cars match" : "Show \(matchCount) car\(matchCount == 1 ? "" : "s")",
                        isEnabled: matchCount > 0
                    ) {
                        withAnimation(Motion.content) { state.filters = draft }
                        state.runSearch()
                        dismiss()
                    }
                    .padding(Space.md)
                }
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.large])
        .onAppear { draft = state.filters }
    }

    // MARK: Sections

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Sort by")
            VStack(spacing: Space.xs) {
                ForEach(SortOrder.allCases) { order in
                    SelectableRow(title: order.label, isSelected: draft.sort == order) {
                        withAnimation(Motion.snap) { draft.sort = order }
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                groupTitle("Daily price")
                Spacer()
                Text("\(Money.short(draft.priceRange.lowerBound)) – \(Money.short(draft.priceRange.upperBound))\(draft.priceRange.upperBound >= SearchFilters.priceCeiling ? "+" : "")")
                    .font(Typo.numeric(13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }

            RangeSlider(
                range: $draft.priceRange,
                bounds: SearchFilters.priceFloor...SearchFilters.priceCeiling,
                step: 5
            )
            .padding(.vertical, Space.xs)

            Text("The average car near \(state.query.place.split(separator: ",").first.map(String.init) ?? "you") is $112 a day.")
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    private var vehicleTypeSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Vehicle type")
            WrapLayout {
                ForEach(BodyType.allCases) { type in
                    Chip(title: type.label, isSelected: draft.bodyTypes.contains(type)) {
                        withAnimation(Motion.snap) { toggle(type, in: &draft.bodyTypes) }
                    }
                }
            }
        }
    }

    private var seatsSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Seats")
            HStack(spacing: Space.xs) {
                ForEach([0, 2, 4, 5, 7], id: \.self) { seats in
                    Chip(title: seats == 0 ? "Any" : "\(seats)+", isSelected: draft.minSeats == seats) {
                        withAnimation(Motion.snap) { draft.minSeats = seats }
                    }
                }
            }
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Minimum rating")
            HStack(spacing: Space.xs) {
                ForEach([0.0, 4.0, 4.5, 4.8], id: \.self) { rating in
                    Chip(
                        title: rating == 0 ? "Any" : String(format: "%.1f+", rating),
                        icon: rating == 0 ? nil : "star.fill",
                        isSelected: draft.minRating == rating
                    ) {
                        withAnimation(Motion.snap) { draft.minRating = rating }
                    }
                }
            }
        }
    }

    private var mechanicalSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            VStack(alignment: .leading, spacing: Space.sm) {
                groupTitle("Transmission")
                HStack(spacing: Space.xs) {
                    ForEach(Transmission.allCases) { option in
                        Chip(title: option.label, isSelected: draft.transmissions.contains(option)) {
                            withAnimation(Motion.snap) { toggle(option, in: &draft.transmissions) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                groupTitle("Fuel")
                HStack(spacing: Space.xs) {
                    ForEach(FuelKind.allCases) { option in
                        Chip(title: option.label, icon: option.symbol, isSelected: draft.fuels.contains(option)) {
                            withAnimation(Motion.snap) { toggle(option, in: &draft.fuels) }
                        }
                    }
                }
            }
        }
    }

    private var bookingSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Booking")
            VStack(spacing: 0) {
                toggleRow(
                    "Instant book only",
                    detail: "Skip the wait for host approval",
                    icon: "bolt.fill",
                    isOn: $draft.instantBookOnly
                )
                Hairline()
                toggleRow(
                    "Delivered to me",
                    detail: "Host brings the car to your address",
                    icon: "shippingbox.fill",
                    isOn: $draft.deliveryOnly
                )
                Hairline()
                toggleRow(
                    "All-Star hosts only",
                    detail: "Top-rated, fastest to reply",
                    icon: "star.circle.fill",
                    isOn: $draft.allStarHostsOnly
                )
            }
            .padding(.horizontal, Space.md)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            groupTitle("Features")
            WrapLayout {
                ForEach(Amenity.allCases) { amenity in
                    Chip(title: amenity.label, icon: amenity.symbol, isSelected: draft.amenities.contains(amenity)) {
                        withAnimation(Motion.snap) { toggle(amenity, in: &draft.amenities) }
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private func groupTitle(_ text: String) -> some View {
        Text(text)
            .font(Typo.sectionTitle)
            .foregroundStyle(Palette.ink)
    }

    private func toggleRow(_ title: String, detail: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isOn.wrappedValue ? Palette.accent : Palette.inkTertiary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer(minLength: Space.xs)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Palette.accent)
        }
        .padding(.vertical, Space.sm)
        .animation(Motion.snap, value: isOn.wrappedValue)
    }

    private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }
}

// MARK: - Range slider
//
// Two thumbs on one track. Built by hand because a stock Slider only carries one
// value, and a price filter with a single bound is a worse filter.

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    var step: Double = 1

    private let thumbSize: CGFloat = 26
    @State private var activeThumb: Thumb?

    private enum Thumb { case lower, upper }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width - thumbSize
            let span = bounds.upperBound - bounds.lowerBound
            let lowerX = CGFloat((range.lowerBound - bounds.lowerBound) / span) * width
            let upperX = CGFloat((range.upperBound - bounds.lowerBound) / span) * width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.surfaceSunken)
                    .frame(height: 4)
                    .padding(.horizontal, thumbSize / 2)

                Capsule()
                    .fill(Palette.ink)
                    .frame(width: max(0, upperX - lowerX), height: 4)
                    .offset(x: lowerX + thumbSize / 2)

                thumb(isActive: activeThumb == .lower)
                    .offset(x: lowerX)
                    .gesture(drag(for: .lower, width: width, span: span))

                thumb(isActive: activeThumb == .upper)
                    .offset(x: upperX)
                    .gesture(drag(for: .upper, width: width, span: span))
            }
            .frame(height: thumbSize)
        }
        .frame(height: thumbSize)
    }

    private func thumb(isActive: Bool) -> some View {
        Circle()
            .fill(Palette.surface)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(Circle().stroke(Palette.hairlineStrong, lineWidth: 1))
            .elevation(isActive ? .mid : .low)
            .scaleEffect(isActive ? 1.14 : 1)
            .animation(Motion.press, value: isActive)
    }

    private func drag(for thumb: Thumb, width: CGFloat, span: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeThumb != thumb { activeThumb = thumb }
                guard width > 0 else { return }

                let raw = bounds.lowerBound + Double(value.location.x / width) * span
                let stepped = (raw / step).rounded() * step
                let clamped = min(max(stepped, bounds.lowerBound), bounds.upperBound)

                switch thumb {
                case .lower:
                    range = min(clamped, range.upperBound - step)...range.upperBound
                case .upper:
                    range = range.lowerBound...max(clamped, range.lowerBound + step)
                }
            }
            .onEnded { _ in
                Haptics.select()
                withAnimation(Motion.snap) { activeThumb = nil }
            }
    }
}
