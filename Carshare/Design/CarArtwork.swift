import SwiftUI

// MARK: - Paint
//
// A prototype with no photography still has to look like a product, so vehicle
// imagery is generated: a studio gradient, one light source, a silhouette and its
// floor reflection. Each car carries a paint colour so it stays recognisable
// between the list, the detail page and the trip card.

enum CarPaint: String, CaseIterable, Hashable {
    case midnight, pearl, sand, forest, ember, slate, ice, plum, copper, graphite

    var label: String {
        switch self {
        case .midnight: "Midnight Blue"
        case .pearl: "Pearl White"
        case .sand: "Desert Sand"
        case .forest: "British Racing Green"
        case .ember: "Ember Red"
        case .slate: "Slate Grey"
        case .ice: "Glacier Silver"
        case .plum: "Aubergine"
        case .copper: "Burnt Copper"
        case .graphite: "Graphite Black"
        }
    }

    /// Backdrop gradient — the "studio", not the car body.
    var backdrop: [Color] {
        switch self {
        case .midnight: [Color(red: 0.09, green: 0.15, blue: 0.28), Color(red: 0.04, green: 0.07, blue: 0.15)]
        case .pearl: [Color(red: 0.90, green: 0.90, blue: 0.88), Color(red: 0.70, green: 0.71, blue: 0.72)]
        case .sand: [Color(red: 0.83, green: 0.72, blue: 0.56), Color(red: 0.56, green: 0.46, blue: 0.35)]
        case .forest: [Color(red: 0.10, green: 0.24, blue: 0.19), Color(red: 0.04, green: 0.12, blue: 0.10)]
        case .ember: [Color(red: 0.48, green: 0.12, blue: 0.13), Color(red: 0.25, green: 0.05, blue: 0.07)]
        case .slate: [Color(red: 0.36, green: 0.40, blue: 0.44), Color(red: 0.18, green: 0.21, blue: 0.24)]
        case .ice: [Color(red: 0.76, green: 0.81, blue: 0.85), Color(red: 0.52, green: 0.58, blue: 0.64)]
        case .plum: [Color(red: 0.27, green: 0.14, blue: 0.30), Color(red: 0.13, green: 0.06, blue: 0.16)]
        case .copper: [Color(red: 0.60, green: 0.32, blue: 0.14), Color(red: 0.31, green: 0.15, blue: 0.07)]
        case .graphite: [Color(red: 0.19, green: 0.20, blue: 0.22), Color(red: 0.07, green: 0.07, blue: 0.08)]
        }
    }

    /// Silhouette colour. Light paints get a dark body so the shape stays readable.
    var body: Color {
        switch self {
        case .pearl, .ice, .sand:
            return Color.black.opacity(0.62)
        default:
            return Color.white.opacity(0.90)
        }
    }

    var isLight: Bool {
        self == .pearl || self == .ice || self == .sand
    }
}

// MARK: - Gallery variants
//
// Five framings so a photo carousel reads like a real listing rather than the same
// picture five times.

enum ArtVariant: Int, CaseIterable {
    case hero, threeQuarter, interior, wheel, parked

    var symbolOverride: String? {
        switch self {
        case .interior: "steeringwheel"
        case .wheel: "circle.dotted"
        default: nil
        }
    }

    var bodyScale: CGFloat {
        switch self {
        case .hero: 0.78
        case .threeQuarter: 1.05
        case .interior: 0.52
        case .wheel: 0.62
        case .parked: 0.60
        }
    }

    var bodyOffset: CGSize {
        switch self {
        case .hero: CGSize(width: 0, height: 0)
        case .threeQuarter: CGSize(width: 26, height: 8)
        case .interior: CGSize(width: 0, height: -4)
        case .wheel: CGSize(width: -14, height: 6)
        case .parked: CGSize(width: 0, height: 2)
        }
    }

    /// Where the studio light sits, so consecutive frames don't look identical.
    var lightAnchor: UnitPoint {
        switch self {
        case .hero: UnitPoint(x: 0.24, y: 0.12)
        case .threeQuarter: UnitPoint(x: 0.72, y: 0.18)
        case .interior: UnitPoint(x: 0.5, y: 0.1)
        case .wheel: UnitPoint(x: 0.3, y: 0.7)
        case .parked: UnitPoint(x: 0.6, y: 0.3)
        }
    }

    var showsReflection: Bool {
        self == .hero || self == .threeQuarter || self == .parked
    }
}

// MARK: - Artwork

struct CarArtwork: View {
    let car: Car
    var variant: ArtVariant = .hero
    /// Vertical parallax driven by scroll offset on the detail page.
    var parallax: CGFloat = 0

    private var symbolName: String {
        Symbols.resolve(variant.symbolOverride ?? car.bodyType.symbol)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height * 1.6)

            ZStack {
                LinearGradient(
                    colors: car.paint.backdrop,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Single studio light. Placement changes per frame.
                RadialGradient(
                    colors: [Color.white.opacity(car.paint.isLight ? 0.55 : 0.28), .clear],
                    center: variant.lightAnchor,
                    startRadius: 0,
                    endRadius: side * 0.78
                )
                .blendMode(.softLight)

                // Studio floor: a soft band the silhouette can sit on.
                if variant.showsReflection {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(car.paint.isLight ? 0.30 : 0.14), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: side * 0.5
                            )
                        )
                        .frame(width: side * 0.95, height: geo.size.height * 0.26)
                        .offset(y: geo.size.height * 0.30)
                }

                vehicle(side: side, height: geo.size.height)
                    .offset(y: parallax)

                // Vignette. Keeps overlaid white text legible at the corners.
                LinearGradient(
                    colors: [Color.black.opacity(0.18), .clear, Color.black.opacity(0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.multiply)
            }
        }
        .clipped()
        .accessibilityLabel("\(car.fullTitle), \(car.paint.label)")
    }

    private func vehicle(side: CGFloat, height: CGFloat) -> some View {
        let glyphSize = side * variant.bodyScale * 0.52

        return VStack(spacing: 0) {
            Image(systemName: symbolName)
                .font(.system(size: glyphSize, weight: .regular))
                .foregroundStyle(car.paint.body)
                .shadow(color: .black.opacity(car.paint.isLight ? 0.18 : 0.42), radius: 22, x: 0, y: 14)

            if variant.showsReflection {
                Image(systemName: symbolName)
                    .font(.system(size: glyphSize, weight: .regular))
                    .foregroundStyle(car.paint.body)
                    .scaleEffect(x: 1, y: -1)
                    .opacity(0.22)
                    .blur(radius: 3)
                    .mask(
                        LinearGradient(
                            colors: [Color.black.opacity(0.85), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, -glyphSize * 0.18)
            }
        }
        .offset(x: variant.bodyOffset.width, y: variant.bodyOffset.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Thumbnails

struct CarThumb: View {
    let car: Car
    var height: CGFloat = 168
    var radius: CGFloat = Radius.md
    var variant: ArtVariant = .hero

    var body: some View {
        CarArtwork(car: car, variant: variant)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Photo carousel
//
// Paged horizontally with a counter pill rather than dots, because a real listing has
// more frames than dots can carry legibly.

struct PhotoCarousel: View {
    let car: Car
    var height: CGFloat = 300
    @Binding var index: Int

    var body: some View {
        let variants = ArtVariant.allCases

        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $index) {
                ForEach(Array(variants.enumerated()), id: \.offset) { offset, variant in
                    CarArtwork(car: car, variant: variant)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)

            HStack(spacing: 3) {
                Text("\(index + 1)")
                    .font(Typo.numeric(12, weight: .semibold))
                    .contentTransition(.numericText())
                Text("/ \(variants.count)")
                    .font(Typo.numeric(12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .padding(Space.sm)
            .animation(Motion.snap, value: index)
        }
    }
}

// MARK: - Map price pin

struct PricePin: View {
    let price: Double
    var isSelected: Bool = false

    var body: some View {
        Text(Money.short(price))
            .font(Typo.numeric(13, weight: .semibold))
            .foregroundStyle(isSelected ? Palette.inkInverted : Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Palette.ink : Palette.surface)
            )
            .overlay(Capsule(style: .continuous).stroke(Palette.hairlineStrong, lineWidth: 1))
            .elevation(.low)
            .scaleEffect(isSelected ? 1.12 : 1)
            .animation(Motion.press, value: isSelected)
    }
}
