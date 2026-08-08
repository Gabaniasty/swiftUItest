import SwiftUI

// MARK: - Host profile
//
// The trust screen. Verification, responsiveness and their other cars — the three
// things a guest checks before handing over a card.

struct HostProfileView: View {
    let host: Host

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private var listings: [Car] {
        state.cars.filter { $0.hostID == host.id }
    }

    private var hostReviews: [Review] {
        let ids = Set(listings.map(\.id))
        return state.reviews.filter { ids.contains($0.carID) }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    identity
                    stats
                    verification
                    bio
                    listingsSection
                    reviewsSection
                }
                .padding(.vertical, Space.md)
                .padding(.bottom, Space.xxl)
            }
            .background(Palette.canvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(Typo.bodyMedium)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        state.show(Toast(message: "Opening a thread with \(host.name)", style: .info))
                    } label: {
                        Image(systemName: "bubble.left.fill")
                    }
                }
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Avatar(initials: host.initials, seed: host.accentSeed, size: 76, isVerified: host.isVerified)

            VStack(alignment: .leading, spacing: 4) {
                Text(host.name)
                    .font(Typo.title)
                    .foregroundStyle(Palette.ink)

                HStack(spacing: Space.xs) {
                    if host.isAllStar {
                        Badge(text: "All-Star Host", icon: "star.circle.fill", tint: Palette.star)
                    }
                    Text("Joined \(String(host.joinedYear)) · \(host.city)")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }

            if host.isAllStar {
                Text("All-Star Hosts have at least five trips, a 4.8 rating, a 90% response rate and no cancellations.")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .pageGutter()
    }

    private var stats: some View {
        HStack(spacing: Space.sm) {
            statTile("\(host.tripCount)", label: "Trips", icon: "car.side.fill")
            statTile(String(format: "%.2f", host.rating), label: "Rating", icon: "star.fill")
            statTile("\(host.responseRate)%", label: "Replies", icon: "bubble.left.fill")
        }
        .pageGutter()
    }

    private func statTile(_ value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: Symbols.resolve(icon, fallback: "circle.fill"))
                .font(.system(size: 13))
                .foregroundStyle(Palette.accent)
            Text(value)
                .font(Typo.numeric(18))
                .foregroundStyle(Palette.ink)
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.7)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    private var verification: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Verified")
            VStack(spacing: Space.xs) {
                verifiedRow("Government ID", isDone: host.isVerified)
                verifiedRow("Phone number", isDone: true)
                verifiedRow("Email address", isDone: true)
                verifiedRow("Typically replies \(host.responseTimeLabel)", isDone: host.responseTimeMinutes < 60, icon: "clock.fill")
            }
        }
        .pageGutter()
    }

    private func verifiedRow(_ title: String, isDone: Bool, icon: String? = nil) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: icon ?? (isDone ? "checkmark.circle.fill" : "circle.dashed"))
                .font(.system(size: 15))
                .foregroundStyle(isDone ? Palette.success : Palette.inkTertiary)
            Text(title)
                .font(Typo.body)
                .foregroundStyle(isDone ? Palette.ink : Palette.inkTertiary)
            Spacer()
        }
    }

    private var bio: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            SectionHeader(title: "About")
            Text(host.bio)
                .font(Typo.body)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .pageGutter()
    }

    @ViewBuilder
    private var listingsSection: some View {
        if !listings.isEmpty {
            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeader(title: "\(host.name.split(separator: " ").first.map(String.init) ?? "Their") cars", eyebrow: "\(listings.count) listed")
                    .pageGutter()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Space.sm) {
                        ForEach(listings) { car in
                            NavigationLink {
                                CarDetailView(car: car)
                            } label: {
                                VStack(alignment: .leading, spacing: Space.xs) {
                                    CarThumb(car: car, height: 120, radius: Radius.md)
                                    Text(car.title)
                                        .font(Typo.bodySemibold)
                                        .foregroundStyle(Palette.ink)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        RatingLabel(rating: car.rating, size: 11)
                                        Text("·").foregroundStyle(Palette.inkTertiary)
                                        Text("\(Money.short(car.dailyPrice))/day")
                                            .font(Typo.numeric(12, weight: .medium))
                                            .foregroundStyle(Palette.inkSecondary)
                                    }
                                }
                                .frame(width: 190)
                            }
                            .buttonStyle(PressableStyle(scale: 0.98, dimsOnPress: false))
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                }
            }
        }
    }

    @ViewBuilder
    private var reviewsSection: some View {
        if !hostReviews.isEmpty {
            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeader(title: "Reviews of \(host.name.split(separator: " ").first.map(String.init) ?? "this host")", eyebrow: "\(hostReviews.count) total")

                ForEach(hostReviews.prefix(5)) { review in
                    ReviewCard(review: review, isExpanded: true)
                }
            }
            .pageGutter()
        }
    }
}
