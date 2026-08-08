import SwiftUI

// MARK: - Root
//
// Owns three things: the welcome gate, the guest/host split, and the toast layer that
// has to float above every sheet.

struct RootView: View {
    @Environment(AppState.self) private var state
    @State private var hasEntered = false

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            if hasEntered {
                Group {
                    switch state.mode {
                    case .guest: MainTabView()
                    case .host: HostShellView()
                    }
                }
                .transition(.opacity)
            } else {
                WelcomeView { withAnimation(Motion.drawer) { hasEntered = true } }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .overlay(alignment: .top) {
            if let toast = state.toast {
                ToastView(toast: toast)
                    .padding(.top, Space.xs)
                    .transition(
                        .move(edge: .top).combined(with: .opacity)
                    )
                    .zIndex(100)
            }
        }
        .animation(Motion.enter, value: state.toast?.id)
        .animation(Motion.drawer, value: state.mode)
        .onAppear(perform: applyLaunchConfig)
    }

    /// Honours a `-startScreen` launch argument so CI (and you, while working) can open
    /// straight onto a given tab instead of tapping through the welcome screen.
    private func applyLaunchConfig() {
        guard let screen = LaunchConfig.startScreen else { return }

        if let tab = screen.appTab {
            state.mode = .guest
            state.selectedTab = tab
        }
        if let hostTab = screen.hostTab {
            state.mode = .host
            state.hostTab = hostTab
        }
        if LaunchConfig.skipsWelcome {
            hasEntered = true
        }
    }
}

// MARK: - Guest tabs

struct MainTabView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        TabView(selection: $state.selectedTab) {
            ExploreView()
                .tabItem { Label(AppTab.explore.title, systemImage: AppTab.explore.symbol) }
                .tag(AppTab.explore)

            FavouritesView()
                .tabItem { Label(AppTab.favourites.title, systemImage: AppTab.favourites.filledSymbol) }
                .tag(AppTab.favourites)

            TripsView()
                .tabItem { Label(AppTab.trips.title, systemImage: AppTab.trips.filledSymbol) }
                .tag(AppTab.trips)

            InboxView()
                .tabItem { Label(AppTab.inbox.title, systemImage: AppTab.inbox.filledSymbol) }
                .badge(state.unreadMessageCount)
                .tag(AppTab.inbox)

            ProfileView()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.filledSymbol) }
                .tag(AppTab.profile)
        }
    }
}

// MARK: - Welcome
//
// One screen, one decision. The artwork is the same procedural system the listings
// use, so the app looks like itself from the first frame.

struct WelcomeView: View {
    let onContinue: () -> Void
    @Environment(AppState.self) private var state
    @State private var carIndex = 0

    private var showcase: [Car] {
        Array(state.cars.prefix(4))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Rotating hero. Slow crossfade — this is a first-run screen, so it can
            // afford a moment of atmosphere.
            ZStack {
                ForEach(Array(showcase.enumerated()), id: \.element.id) { offset, car in
                    CarArtwork(car: car, variant: offset.isMultiple(of: 2) ? .hero : .threeQuarter)
                        .opacity(offset == carIndex ? 1 : 0)
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.9), value: carIndex)

            LinearGradient(
                colors: [.clear, .black.opacity(0.35), .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Space.lg) {
                Spacer()

                HStack(spacing: Space.xs) {
                    Image(systemName: Symbols.resolve("car.side.fill"))
                        .font(.system(size: 16, weight: .semibold))
                    Text("carshare")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .tracking(0.4)
                }
                .foregroundStyle(.white.opacity(0.85))

                Text("Rent almost any car,\nfrom someone nearby.")
                    .font(Typo.hero)
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Thousands of cars from local hosts — booked in a couple of taps, picked up down the road.")
                    .font(Typo.bodyLarge)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: Space.sm) {
                    Button {
                        Haptics.tap()
                        onContinue()
                    } label: {
                        Text("Find a car")
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .fill(.white)
                            )
                    }
                    .buttonStyle(PressableStyle())

                    Button {
                        Haptics.tap()
                        state.mode = .host
                        onContinue()
                    } label: {
                        Text("I want to list my car")
                            .font(Typo.bodyMedium)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))
                }
                .padding(.top, Space.xs)
            }
            .pageGutter()
            .padding(.bottom, Space.xl)
        }
        .task {
            // Cycle the hero while the user reads. Stops as soon as they move on.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.2))
                guard !showcase.isEmpty else { return }
                carIndex = (carIndex + 1) % showcase.count
            }
        }
    }
}
