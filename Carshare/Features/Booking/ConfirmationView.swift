import SwiftUI

// MARK: - Confirmation
//
// A screen a given user sees a handful of times ever, so it is the one place in the
// app where a little delight is justified. The seal draws itself once and stops.

struct ConfirmationView: View {
    let trip: Trip
    let onDone: () -> Void

    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sealScale: CGFloat = 0.86
    @State private var sealOpacity: Double = 0
    @State private var contentVisible = false

    private var car: Car? { state.car(trip.carID) }
    private var host: Host? { car.flatMap { state.host(for: $0) } }

    private var isInstant: Bool { trip.status == .upcoming }

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Space.xl) {
                    seal
                        .padding(.top, Space.xxl)

                    headline

                    if let car {
                        Card(padding: Space.md) {
                            VStack(alignment: .leading, spacing: Space.sm) {
                                HStack(spacing: Space.sm) {
                                    CarThumb(car: car, height: 72, radius: Radius.sm)
                                        .frame(width: 104)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(car.fullTitle)
                                            .font(Typo.bodySemibold)
                                            .foregroundStyle(Palette.ink)
                                            .lineLimit(1)
                                        if let host {
                                            Text("Hosted by \(host.name)")
                                                .font(Typo.caption)
                                                .foregroundStyle(Palette.inkSecondary)
                                        }
                                        Text(Money.full(trip.quote.total))
                                            .font(Typo.numeric(15))
                                            .foregroundStyle(Palette.ink)
                                    }
                                    Spacer(minLength: 0)
                                }

                                Hairline()

                                DetailRow(label: "Pick up", value: DateText.withWeekday(trip.startDate), labelIcon: "calendar")
                                DetailRow(label: "Return", value: DateText.withWeekday(trip.endDate), labelIcon: "calendar")
                                DetailRow(
                                    label: trip.handoff == .delivery ? "Delivered to" : "Collect from",
                                    value: trip.handoffAddress,
                                    labelIcon: trip.handoff.symbol
                                )
                            }
                        }
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible || reduceMotion ? 0 : 12)
                    }

                    nextSteps
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible || reduceMotion ? 0 : 12)
                }
                .pageGutter()
                .padding(.bottom, Space.xxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Space.xs) {
                PrimaryButton(title: "View my trip", icon: "car.side.fill") {
                    state.selectedTab = .trips
                    onDone()
                }
                Button {
                    Haptics.tap()
                    onDone()
                } label: {
                    Text("Keep browsing")
                        .font(Typo.bodyMedium)
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(PressableStyle(scale: 0.98))
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.xs)
            .background(.regularMaterial)
        }
        .onAppear(perform: runEntrance)
    }

    // MARK: Pieces

    private var seal: some View {
        ZStack {
            Circle()
                .fill(isInstant ? Palette.accentWash : Palette.star.opacity(0.14))
                .frame(width: 104, height: 104)

            Image(systemName: isInstant ? "checkmark" : "paperplane.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(isInstant ? Palette.accent : Palette.star)
        }
        .scaleEffect(sealScale)
        .opacity(sealOpacity)
    }

    private var headline: some View {
        VStack(spacing: Space.xs) {
            Text(isInstant ? "You're booked." : "Request sent.")
                .font(Typo.display(30))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)

            Text(isInstant
                 ? "The host has been notified. You'll get the exact pickup spot 24 hours before you collect it."
                 : "\(host?.name.split(separator: " ").first.map(String.init) ?? "The host") usually replies \(host?.responseTimeLabel ?? "within a few hours"). Nothing is charged until they accept.")
                .font(Typo.bodyLarge)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(contentVisible ? 1 : 0)
    }

    private var nextSteps: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionHeader(title: "What happens next")

            VStack(alignment: .leading, spacing: Space.md) {
                stepRow(
                    number: 1,
                    title: isInstant ? "Message your host" : "Wait for approval",
                    detail: isInstant
                        ? "Agree a rough pickup time. They're expecting to hear from you."
                        : "You'll get a notification the moment they respond."
                )
                stepRow(
                    number: 2,
                    title: "Check in with photos",
                    detail: "At pickup you'll photograph the car from six angles. It takes a minute and protects you both."
                )
                stepRow(
                    number: 3,
                    title: "Drive, then return it",
                    detail: "Bring it back to the same spot at the same fuel or charge level, and check out in the app."
                )
            }
        }
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Space.sm) {
            Text("\(number)")
                .font(Typo.numeric(13))
                .foregroundStyle(Palette.inkInverted)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Palette.ink))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Entrance

    private func runEntrance() {
        guard !reduceMotion else {
            sealScale = 1
            sealOpacity = 1
            contentVisible = true
            return
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
            sealScale = 1
            sealOpacity = 1
        }
        withAnimation(Motion.enter.delay(0.14)) {
            contentVisible = true
        }
    }
}
