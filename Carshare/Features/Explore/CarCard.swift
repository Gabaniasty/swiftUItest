import SwiftUI

// MARK: - Result card
//
// The unit of the whole app. Everything a guest decides on is here: what it is, what
// it costs, how far away, who owns it, and whether they can book it instantly.

struct CarCard: View {
    let car: Car
    var showsDistance: Bool = true
    @Environment(AppState.self) private var state

    private var host: Host? { state.host(for: car) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CarThumb(car: car, height: 196, radius: Radius.lg)

                HStack(spacing: Space.xs) {
                    if let discount = car.discountPercent {
                        Text("\(discount)% off")
                            .font(Typo.micro)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Palette.danger))
                    }
                    GlassIconButton(
                        icon: state.isFavourite(car) ? "heart.fill" : "heart",
                        isActive: state.isFavourite(car),
                        size: 34
                    ) {
                        state.toggleFavourite(car)
                    }
                }
                .padding(Space.sm)

                if car.isNewListing || car.isInstantBook {
                    VStack {
                        Spacer()
                        HStack(spacing: Space.xs) {
                            if car.isNewListing {
                                Badge(text: "New", icon: "sparkles", tint: .white)
                                    .background(Capsule().fill(.black.opacity(0.35)))
                            }
                            if car.isInstantBook {
                                Badge(text: "Instant book", icon: "bolt.fill", tint: .white)
                                    .background(Capsule().fill(.black.opacity(0.35)))
                            }
                            Spacer()
                        }
                        .padding(Space.sm)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(car.title)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text(String(car.year))
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                    Spacer(minLength: Space.xs)
                    if car.tripCount > 0 {
                        RatingLabel(rating: car.rating, tripCount: car.tripCount)
                    } else {
                        Text("No trips yet")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                    }
                }

                HStack(spacing: Space.xs) {
                    Label(car.location.name, systemImage: "mappin.and.ellipse")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineLimit(1)
                    if showsDistance {
                        Text("·")
                            .foregroundStyle(Palette.inkTertiary)
                        Text(String(format: "%.1f mi", car.distanceMiles))
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                    if let host, host.isAllStar {
                        Badge(text: "All-Star Host", icon: "star.circle.fill")
                    }
                    if car.supportsDelivery {
                        Badge(text: "Delivery", icon: "shippingbox.fill", tint: Palette.info)
                    }
                    Spacer(minLength: Space.xs)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let listPrice = car.listPrice {
                            Text(Money.short(listPrice))
                                .font(Typo.numeric(13, weight: .regular))
                                .foregroundStyle(Palette.inkTertiary)
                                .strikethrough(true, color: Palette.inkTertiary)
                        }
                        Text(Money.short(car.dailyPrice))
                            .font(Typo.numeric(17))
                            .foregroundStyle(Palette.ink)
                        Text("/day")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.top, Space.sm)
        }
    }
}

// MARK: - Compact row
//
// Used where vertical space is tight: favourites in a dense list, map sheet, trip
// pickers.

struct CarRow: View {
    let car: Car
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: Space.sm) {
            CarThumb(car: car, height: 72, radius: Radius.sm)
                .frame(width: 104)

            VStack(alignment: .leading, spacing: 3) {
                Text(car.title)
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    RatingLabel(rating: car.rating, tripCount: car.tripCount, size: 12)
                    Text("·")
                        .foregroundStyle(Palette.inkTertiary)
                    Text(car.location.name)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineLimit(1)
                }
                Text(trailingText ?? "\(Money.short(car.dailyPrice))/day")
                    .font(Typo.numeric(13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Skeleton

struct CarCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SkeletonBlock(height: 196, radius: Radius.lg)
            SkeletonBlock(height: 15, width: 190)
            SkeletonBlock(height: 12, width: 130)
            SkeletonBlock(height: 12, width: 90)
        }
    }
}
