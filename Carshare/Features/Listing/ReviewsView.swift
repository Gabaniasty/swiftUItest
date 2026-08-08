import SwiftUI

// MARK: - Review card

struct ReviewCard: View {
    let review: Review
    var isExpanded: Bool = false

    var body: some View {
        Card(padding: Space.md) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(spacing: Space.xs) {
                    Avatar(initials: review.initials, seed: review.accentSeed, size: 36)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(review.authorName)
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Text(DateText.full(review.date))
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                    }

                    Spacer(minLength: 0)
                }

                StarRow(rating: review.rating, size: 11)

                Text(review.text)
                    .font(Typo.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(3)
                    .lineLimit(isExpanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let reply = review.hostReply {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Host replied", systemImage: "arrow.turn.down.right")
                            .font(Typo.micro)
                            .foregroundStyle(Palette.inkTertiary)
                        Text(reply)
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Space.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(Palette.surfaceSunken)
                    )
                }
            }
        }
    }
}

// MARK: - All reviews
//
// Sortable and filterable by star rating, because the useful reviews on a rental
// listing are usually the three-star ones.

struct ReviewsListView: View {
    let car: Car

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var starFilter: Int? = nil

    private var allReviews: [Review] { state.reviews(for: car.id) }

    private var filtered: [Review] {
        guard let starFilter else { return allReviews }
        return allReviews.filter { Int($0.rating.rounded()) == starFilter }
    }

    private var distribution: [(Int, Int)] {
        (1...5).reversed().map { star in
            (star, allReviews.filter { Int($0.rating.rounded()) == star }.count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    summary
                    distributionBars

                    HStack(spacing: Space.xs) {
                        Chip(title: "All", isSelected: starFilter == nil) {
                            withAnimation(Motion.content) { starFilter = nil }
                        }
                        ForEach([5, 4, 3], id: \.self) { star in
                            Chip(title: "\(star)", icon: "star.fill", isSelected: starFilter == star) {
                                withAnimation(Motion.content) {
                                    starFilter = starFilter == star ? nil : star
                                }
                            }
                        }
                    }

                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "text.bubble",
                            title: "No reviews at that rating",
                            message: "Try another filter — most guests rated this car four or five stars."
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, review in
                            ReviewCard(review: review, isExpanded: true)
                                .appear(index)
                        }
                    }
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: Space.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.2f", car.rating))
                    .font(Typo.display(38))
                    .foregroundStyle(Palette.ink)
                StarRow(rating: car.rating, size: 13)
                Text("\(allReviews.count) review\(allReviews.count == 1 ? "" : "s") · \(car.tripCount) trips")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            CarThumb(car: car, height: 76, radius: Radius.md)
                .frame(width: 108)
        }
    }

    private var distributionBars: some View {
        VStack(spacing: 6) {
            ForEach(distribution, id: \.0) { star, count in
                HStack(spacing: Space.sm) {
                    Text("\(star)")
                        .font(Typo.numeric(12, weight: .medium))
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(width: 10)
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.star)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.surfaceSunken)
                            Capsule()
                                .fill(Palette.ink)
                                .frame(
                                    width: allReviews.isEmpty
                                        ? 0
                                        : max(count == 0 ? 0 : 3, geo.size.width * (Double(count) / Double(allReviews.count)))
                                )
                        }
                    }
                    .frame(height: 5)

                    Text("\(count)")
                        .font(Typo.numeric(12))
                        .foregroundStyle(Palette.inkTertiary)
                        .frame(width: 22, alignment: .trailing)
                }
            }
        }
    }
}
