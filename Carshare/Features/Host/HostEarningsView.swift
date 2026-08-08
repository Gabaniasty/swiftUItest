import SwiftUI

// MARK: - Earnings
//
// A bar chart drawn with plain shapes rather than a charting dependency. Values are
// derived from the real listing mix, so adding a car actually moves the chart.

struct HostEarningsView: View {
    @Environment(AppState.self) private var state
    @State private var selectedMonth: Int?

    private let monthLabels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    private var monthly: [Double] { state.hostMonthlyEarnings }
    private var peak: Double { max(1, monthly.max() ?? 1) }
    private var yearTotal: Double { monthly.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl) {
                        headline
                        chart
                        summaryTiles
                        payoutsSection
                        performanceSection
                    }
                    .pageGutter()
                    .padding(.vertical, Space.md)
                    .padding(.bottom, Space.xxl)
                }
            }
            .navigationTitle("Earnings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text("Last 12 months".uppercased())
                .font(Typo.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Palette.inkTertiary)

            HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                Text(Money.short(selectedMonth.map { monthly[$0] } ?? yearTotal))
                    .font(Typo.display(34))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())

                if let selectedMonth {
                    Text(monthName(selectedMonth))
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .animation(Motion.snap, value: selectedMonth)

            Text(selectedMonth == nil ? "Across \(state.myListings.count) vehicle\(state.myListings.count == 1 ? "" : "s")" : "Tap the bar again to see the year")
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)
        }
    }

    private var chart: some View {
        VStack(spacing: Space.xs) {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(monthly.indices, id: \.self) { index in
                    let isSelected = selectedMonth == index
                    Button {
                        Haptics.select()
                        withAnimation(Motion.snap) {
                            selectedMonth = isSelected ? nil : index
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(isSelected ? Palette.accent : Palette.ink.opacity(selectedMonth == nil ? 0.82 : 0.28))
                                .frame(height: max(6, 132 * (monthly[index] / peak)))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 132)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle(scale: 0.94, dimsOnPress: false))
                }
            }

            HStack(spacing: 5) {
                ForEach(monthly.indices, id: \.self) { index in
                    Text(monthLabels[index])
                        .font(Typo.micro)
                        .foregroundStyle(selectedMonth == index ? Palette.ink : Palette.inkTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Space.md)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    private var summaryTiles: some View {
        HStack(spacing: Space.sm) {
            tile(Money.compact(state.hostEarningsToDate), label: "Paid out", tint: Palette.success)
            tile(Money.compact(state.hostEarningsScheduled), label: "Scheduled", tint: Palette.info)
            tile("\(state.hostCompletedTrips.count)", label: "Trips done", tint: Palette.accent)
        }
    }

    private func tile(_ value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(value)
                .font(Typo.numeric(18))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(Typo.micro)
                .tracking(0.7)
                .foregroundStyle(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var payoutsSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "Payouts")

            if state.hostCompletedTrips.isEmpty {
                Card(padding: Space.md, elevation: .none, fill: Palette.surfaceSunken) {
                    Text("No payouts yet. Your first one lands three hours after a trip starts.")
                        .font(Typo.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(state.hostCompletedTrips.enumerated()), id: \.element.id) { index, trip in
                        HStack(spacing: Space.sm) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(Palette.success)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(state.car(trip.carID)?.title ?? "Trip")
                                    .font(Typo.bodyMedium)
                                    .foregroundStyle(Palette.ink)
                                Text("\(trip.guestName) · \(DateText.range(trip.startDate, trip.endDate))")
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.inkTertiary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            Text("+\(Money.full(trip.quote.hostEarnings))")
                                .font(Typo.numeric(14))
                                .foregroundStyle(Palette.success)
                        }
                        .padding(.vertical, Space.sm)

                        if index < state.hostCompletedTrips.count - 1 { Hairline() }
                    }
                }
                .padding(.horizontal, Space.md)
                .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
            }
        }
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SectionHeader(title: "How you're doing")

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    ScoreBar(label: "Rating", score: 4.88)
                    ScoreBar(label: "Response", score: 4.85)
                    ScoreBar(label: "Acceptance", score: 4.40)
                    ScoreBar(label: "Cleanliness", score: 4.92)

                    Hairline()

                    HStack(alignment: .top, spacing: Space.xs) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(Palette.star)
                        Text("Accept two more requests and you'll qualify for All-Star Host, which puts your cars higher in search.")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func monthName(_ index: Int) -> String {
        let names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[index % 12]
    }
}
