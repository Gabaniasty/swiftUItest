import SwiftUI
import MapKit

// MARK: - Listing detail
//
// Order is deliberate and mirrors how people actually decide: what it is → is it
// any good → can I get it when I need it → what does it really cost → who am I
// dealing with → what are the rules. Price stays pinned at the bottom throughout,
// because the answer to "how much" should never require scrolling.

struct CarDetailView: View {
    let car: Car

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var photoIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showBooking = false
    @State private var showAllReviews = false
    @State private var showHost = false
    @State private var isDescriptionExpanded = false

    private var host: Host? { state.host(for: car) }
    private var reviews: [Review] { state.reviews(for: car.id) }
    private var breakdown: RatingBreakdown { SampleData.breakdown(for: car) }

    private var quote: PriceQuote {
        state.quote(
            car: car,
            start: state.query.startDate,
            end: state.query.endDate,
            protection: .standard,
            extras: [],
            handoff: .hostLocation
        )
    }

    /// Title bar fades in only once the photo has scrolled past.
    private var isTitleBarVisible: Bool { scrollOffset < -190 }

    var body: some View {
        ZStack(alignment: .top) {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .named("detail")).minY
                    )
                }
                .frame(height: 0)

                VStack(alignment: .leading, spacing: Space.xl) {
                    gallery
                    heading
                    quickSpecs
                    ratingsSummary
                    description
                    featuresGrid
                    availability
                    priceBreakdown
                    hostCard
                    reviewsSection
                    locationSection
                    rulesSection
                    cancellationSection
                }
                .padding(.bottom, Space.xxxl * 2)
            }
            .coordinateSpace(name: "detail")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .ignoresSafeArea(edges: .top)

            floatingBar
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) { bookingBar }
        .sheet(isPresented: $showBooking) {
            BookingFlowView(car: car)
        }
        .sheet(isPresented: $showAllReviews) {
            ReviewsListView(car: car)
        }
        .sheet(isPresented: $showHost) {
            if let host {
                HostProfileView(host: host)
            }
        }
    }

    // MARK: Gallery

    private var gallery: some View {
        // Parallax: the artwork drifts at roughly a third of scroll speed while the
        // page moves, and stretches instead of tearing when over-scrolled.
        let stretch = max(0, scrollOffset)

        return PhotoCarousel(car: car, height: 320 + stretch, index: $photoIndex)
            .offset(y: -stretch)
            .overlay(alignment: .bottomLeading) {
                if let discount = car.discountPercent {
                    Text("\(discount)% below usual price")
                        .font(Typo.micro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Palette.danger))
                        .padding(Space.md)
                }
            }
    }

    // MARK: Floating chrome

    private var floatingBar: some View {
        HStack(spacing: Space.xs) {
            GlassIconButton(icon: "chevron.left", size: 40) { dismiss() }

            if isTitleBarVisible {
                Text(car.title)
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .padding(.horizontal, Space.sm)
                    .frame(height: 40)
                    .background(Capsule().fill(.regularMaterial))
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .leading)))
            }

            Spacer(minLength: 0)

            GlassIconButton(icon: "square.and.arrow.up", size: 40) {
                state.show(Toast(message: "Link copied to clipboard", style: .info))
            }

            GlassIconButton(
                icon: state.isFavourite(car) ? "heart.fill" : "heart",
                isActive: state.isFavourite(car),
                size: 40
            ) {
                state.toggleFavourite(car)
            }
        }
        .pageGutter()
        .padding(.top, Space.xs)
        .animation(Motion.snap, value: isTitleBarVisible)
    }

    // MARK: Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.xs) {
                if car.isInstantBook {
                    Badge(text: "Instant book", icon: "bolt.fill")
                }
                if car.isNewListing {
                    Badge(text: "New listing", icon: "sparkles", tint: Palette.info)
                }
                Badge(text: car.paint.label, tint: Palette.inkTertiary)
            }

            Text(car.fullTitle)
                .font(Typo.title)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(car.trim.isEmpty ? car.blurb : "\(car.trim) · \(car.blurb)")
                .font(Typo.body)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Space.sm) {
                if car.tripCount > 0 {
                    RatingLabel(rating: car.rating, tripCount: car.tripCount, size: 14, showsWord: true)
                } else {
                    Text("No trips yet")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text("·").foregroundStyle(Palette.inkTertiary)
                Label(String(format: "%.1f mi away", car.distanceMiles), systemImage: "location.fill")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)
            }
            .padding(.top, 2)
        }
        .pageGutter()
    }

    // MARK: Specs

    private var quickSpecs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.sm) {
                specTile(car.bodyType.label, value: "Type", icon: Symbols.resolve(car.bodyType.symbol))
                specTile("\(car.seats)", value: "Seats", icon: "person.2.fill")
                specTile(car.transmission.label, value: "Gearbox", icon: "gearshape.fill")
                specTile(car.fuel.label, value: "Fuel", icon: car.fuel.symbol)
                specTile(car.efficiencyLabel, value: car.fuel == .electric ? "Range" : "Economy", icon: "gauge.with.dots.needle.50percent")
                specTile("\(car.doors)", value: "Doors", icon: "door.left.hand.closed")
            }
            .padding(.horizontal, Space.gutter)
        }
    }

    private func specTile(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.accent)
            Text(title)
                .font(Typo.bodySemibold)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Text(value.uppercased())
                .font(Typo.micro)
                .tracking(0.7)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(width: 96, alignment: .leading)
        .padding(Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    // MARK: Ratings

    @ViewBuilder
    private var ratingsSummary: some View {
        if car.tripCount > 0 {
            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeader(title: "Rated \(String(format: "%.2f", car.rating))", eyebrow: "\(car.tripCount) trips")

                VStack(spacing: Space.xs) {
                    ScoreBar(label: "Cleanliness", score: breakdown.cleanliness)
                    ScoreBar(label: "Maintenance", score: breakdown.maintenance)
                    ScoreBar(label: "Communication", score: breakdown.communication)
                    ScoreBar(label: "Convenience", score: breakdown.convenience)
                    ScoreBar(label: "Accuracy", score: breakdown.accuracy)
                }
            }
            .pageGutter()
        }
    }

    // MARK: Description

    private var description: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "About this car")

            Text(car.details)
                .font(Typo.body)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .lineLimit(isDescriptionExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.tap()
                withAnimation(Motion.move) { isDescriptionExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isDescriptionExpanded ? "Show less" : "Read more")
                        .font(Typo.captionMedium)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .rotationEffect(.degrees(isDescriptionExpanded ? 180 : 0))
                }
                .foregroundStyle(Palette.accent)
            }
            .buttonStyle(PressableStyle(scale: 0.97))
        }
        .pageGutter()
    }

    // MARK: Features

    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "Features")

            LazyVGrid(
                columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                alignment: .leading,
                spacing: Space.sm
            ) {
                ForEach(car.amenities) { amenity in
                    HStack(spacing: Space.xs) {
                        Image(systemName: Symbols.resolve(amenity.symbol, fallback: "checkmark"))
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.inkSecondary)
                            .frame(width: 20)
                        Text(amenity.label)
                            .font(Typo.body)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
        }
        .pageGutter()
    }

    // MARK: Availability

    private var availability: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(
                title: "Availability",
                eyebrow: car.minTripDays > 1 ? "\(car.minTripDays) day minimum" : nil
            )

            AvailabilityCalendar(
                blockedDates: car.blockedDates,
                selectedRange: state.query.startDate...state.query.endDate
            )

            HStack(spacing: Space.md) {
                legendDot(fill: Palette.ink, label: "Your dates")
                legendDot(fill: Palette.surfaceSunken, label: "Booked", isStruck: true)
            }
        }
        .pageGutter()
    }

    private func legendDot(fill: Color, label: String, isStruck: Bool = false) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fill)
                .frame(width: 14, height: 14)
                .overlay(
                    Group {
                        if isStruck {
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Palette.inkTertiary)
                        }
                    }
                )
            Text(label)
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSecondary)
        }
    }

    // MARK: Price

    private var priceBreakdown: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "Price for \(quote.days) day\(quote.days == 1 ? "" : "s")", eyebrow: state.query.rangeLabel)

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DetailRow(
                        label: "\(Money.short(car.dailyPrice)) × \(quote.days) day\(quote.days == 1 ? "" : "s")",
                        value: Money.full(quote.subtotal)
                    )
                    if let discountLabel = quote.discountLabel {
                        DetailRow(
                            label: discountLabel,
                            value: "−\(Money.full(quote.discountAmount))",
                            valueColor: Palette.success
                        )
                    }
                    DetailRow(label: "Protection (Standard)", value: Money.full(quote.protectionCost))
                    DetailRow(label: "Trip fee", value: Money.full(quote.tripFee))
                    DetailRow(label: "Taxes", value: Money.full(quote.taxes))

                    Hairline()

                    DetailRow(label: "Total", value: Money.full(quote.total), isEmphasised: true)

                    Text("Includes \(car.includedMilesPerDay) miles a day. Extra miles are \(Money.full(car.extraMileFee)) each.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .pageGutter()
    }

    // MARK: Host

    @ViewBuilder
    private var hostCard: some View {
        if let host {
            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeader(title: "Hosted by \(host.name.split(separator: " ").first.map(String.init) ?? host.name)")

                Button {
                    Haptics.tap()
                    showHost = true
                } label: {
                    Card(padding: Space.md) {
                        VStack(alignment: .leading, spacing: Space.sm) {
                            HStack(spacing: Space.sm) {
                                Avatar(initials: host.initials, seed: host.accentSeed, size: 52, isVerified: host.isVerified)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(host.name)
                                            .font(Typo.bodySemibold)
                                            .foregroundStyle(Palette.ink)
                                        if host.isAllStar {
                                            Image(systemName: "star.circle.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Palette.star)
                                        }
                                    }
                                    Text("Joined \(String(host.joinedYear)) · \(host.tripCount) trips")
                                        .font(Typo.caption)
                                        .foregroundStyle(Palette.inkSecondary)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.inkTertiary)
                            }

                            Hairline()

                            HStack(spacing: 0) {
                                hostStat(String(format: "%.2f", host.rating), label: "Rating")
                                Divider().frame(height: 30)
                                hostStat("\(host.responseRate)%", label: "Replies")
                                Divider().frame(height: 30)
                                hostStat(host.responseTimeLabel.replacingOccurrences(of: "within ", with: ""), label: "Response")
                            }

                            Text(host.bio)
                                .font(Typo.caption)
                                .foregroundStyle(Palette.inkSecondary)
                                .lineLimit(3)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
            }
            .pageGutter()
        }
    }

    private func hostStat(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Typo.numeric(15))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.6)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Reviews

    @ViewBuilder
    private var reviewsSection: some View {
        if !reviews.isEmpty {
            let hasMore = reviews.count > 2
            let seeAllTitle: String? = hasMore ? "See all" : nil
            let seeAllAction: (() -> Void)? = hasMore ? { showAllReviews = true } : nil

            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeader(
                    title: "What guests said",
                    eyebrow: "\(reviews.count) review\(reviews.count == 1 ? "" : "s")",
                    actionTitle: seeAllTitle,
                    action: seeAllAction
                )
                .pageGutter()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Space.sm) {
                        ForEach(reviews.prefix(4)) { review in
                            ReviewCard(review: review)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                }
            }
        }
    }

    // MARK: Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "Pickup location", eyebrow: car.location.detail)

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: car.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                ),
                interactionModes: []
            ) {
                Annotation("", coordinate: car.location.coordinate) {
                    Image(systemName: Symbols.resolve(car.bodyType.symbol))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.inkInverted)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Palette.ink))
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                        .elevation(.mid)
                }
                .annotationTitles(.hidden)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: Space.xs) {
                Label(car.location.name, systemImage: "mappin.and.ellipse")
                    .font(Typo.bodyMedium)
                    .foregroundStyle(Palette.ink)

                Text("Exact address is shared once your booking is confirmed.")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)

                if let fee = car.deliveryFee {
                    Hairline().padding(.vertical, Space.xxs)
                    HStack(spacing: Space.xs) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.info)
                        Text("Delivery available for \(Money.short(fee))")
                            .font(Typo.body)
                            .foregroundStyle(Palette.ink)
                    }
                }
            }
        }
        .pageGutter()
    }

    // MARK: Rules & cancellation

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "House rules")
            VStack(alignment: .leading, spacing: Space.sm) {
                ForEach(car.rules, id: \.self) { rule in
                    HStack(alignment: .top, spacing: Space.xs) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(Palette.inkTertiary)
                            .padding(.top, 7)
                        Text(rule)
                            .font(Typo.body)
                            .foregroundStyle(Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .pageGutter()
    }

    private var cancellationSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Cancellation")
            Card(padding: Space.md, elevation: .none, fill: Palette.surfaceSunken) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Label("Free cancellation up to 24 hours before pickup", systemImage: "checkmark.circle.fill")
                        .font(Typo.bodyMedium)
                        .foregroundStyle(Palette.ink)
                    Text("Cancel inside 24 hours and you're charged one day, or 50% of the trip if that's less.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .pageGutter()
    }

    // MARK: Booking bar

    private var bookingBar: some View {
        VStack(spacing: 0) {
            Hairline()

            HStack(alignment: .center, spacing: Space.md) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(Money.full(quote.total))
                            .font(Typo.numeric(20))
                            .foregroundStyle(Palette.ink)
                        Text("total")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    Text("\(state.query.rangeLabel) · \(quote.days) day\(quote.days == 1 ? "" : "s")")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }

                Spacer(minLength: 0)

                PrimaryButton(
                    title: car.isInstantBook ? "Book now" : "Request",
                    icon: car.isInstantBook ? "bolt.fill" : nil,
                    fullWidth: false
                ) {
                    showBooking = true
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.sm)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Availability calendar
//
// Two months, read-only. Booked days are struck through, the guest's own range is
// filled — enough to answer "can I have it then" without pretending to be a picker.

struct AvailabilityCalendar: View {
    let blockedDates: Set<Date>
    let selectedRange: ClosedRange<Date>

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: Space.lg) {
            ForEach(0..<2, id: \.self) { offset in
                if let month = calendar.date(byAdding: .month, value: offset, to: Date()) {
                    monthGrid(for: month)
                }
            }
        }
    }

    private func monthGrid(for month: Date) -> some View {
        let days = daysInMonth(month)
        let weekdaySymbols = calendar.veryShortStandaloneWeekdaySymbols

        return VStack(alignment: .leading, spacing: Space.sm) {
            Text(DateText.month(month))
                .font(Typo.bodySemibold)
                .foregroundStyle(Palette.ink)

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(Typo.micro)
                        .foregroundStyle(Palette.inkTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let startOfDay = calendar.startOfDay(for: date)
        let isBlocked = blockedDates.contains { calendar.isDate($0, inSameDayAs: startOfDay) }
        let isPast = startOfDay < calendar.startOfDay(for: Date())
        let isSelected = !isPast && !isBlocked
            && startOfDay >= calendar.startOfDay(for: selectedRange.lowerBound)
            && startOfDay <= calendar.startOfDay(for: selectedRange.upperBound)

        return Text("\(calendar.component(.day, from: date))")
            .font(Typo.numeric(13, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(
                isSelected ? Palette.inkInverted
                    : (isBlocked || isPast) ? Palette.inkTertiary.opacity(0.55)
                    : Palette.ink
            )
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Palette.ink : (isBlocked ? Palette.surfaceSunken : .clear))
            )
            .overlay(
                Group {
                    if isBlocked {
                        Rectangle()
                            .fill(Palette.inkTertiary.opacity(0.5))
                            .frame(height: 1)
                            .rotationEffect(.degrees(-16))
                    }
                }
            )
    }

    /// Leading nils pad the first week so the 1st lands on the right weekday.
    private func daysInMonth(_ month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let leadingBlanks = calendar.component(.weekday, from: first) - calendar.firstWeekday
        let padding = (leadingBlanks + 7) % 7

        return Array(repeating: nil, count: padding)
            + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}
