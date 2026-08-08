import SwiftUI

// MARK: - Explore
//
// The search header collapses as you scroll: the big serif greeting goes away and a
// compact search pill stays pinned, so the query is always one tap from being changed
// without eating a third of the screen.

struct ExploreView: View {
    @Environment(AppState.self) private var state

    @State private var showSearchSheet = false
    @State private var showFilters = false
    @State private var showMap = false
    @State private var scrollOffset: CGFloat = 0
    @State private var path: [Car] = []

    private var isHeaderCollapsed: Bool { scrollOffset < -46 }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    // Offset probe. Cheaper than a scroll-position API and works on 17.
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("explore")).minY
                        )
                    }
                    .frame(height: 0)

                    LazyVStack(alignment: .leading, spacing: Space.xl) {
                        greeting
                            .padding(.top, Space.sm)

                        if state.isSearching {
                            ForEach(0..<3, id: \.self) { _ in
                                CarCardSkeleton()
                            }
                        } else if state.results.isEmpty {
                            EmptyStateView(
                                icon: "car.side",
                                title: "Nothing matches yet",
                                message: "Your filters are a little tight. Loosen one and we'll find something.",
                                actionTitle: "Reset filters"
                            ) {
                                withAnimation(Motion.content) { state.filters = SearchFilters() }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, Space.xxl)
                        } else {
                            resultsHeader

                            ForEach(Array(state.results.enumerated()), id: \.element.id) { index, car in
                                NavigationLink(value: car) {
                                    CarCard(car: car)
                                }
                                .buttonStyle(PressableStyle(scale: 0.985, dimsOnPress: false))
                                .appear(index)
                            }

                            hostPrompt
                                .padding(.top, Space.sm)
                        }
                    }
                    .pageGutter()
                    .padding(.top, 108)
                    .padding(.bottom, Space.xxxl)
                }
                .coordinateSpace(name: "explore")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
                .scrollDismissesKeyboard(.immediately)

                header
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Car.self) { car in
                CarDetailView(car: car)
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchSheet()
            }
            .sheet(isPresented: $showFilters) {
                FiltersSheet()
            }
            .fullScreenCover(isPresented: $showMap) {
                MapResultsView()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: Space.sm) {
                searchPill

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Space.xs) {
                        Chip(
                            title: state.filters.activeCount > 0 ? "Filters · \(state.filters.activeCount)" : "Filters",
                            icon: "slider.horizontal.3",
                            isSelected: state.filters.activeCount > 0
                        ) {
                            showFilters = true
                        }

                        Chip(title: state.filters.sort.label, icon: "arrow.up.arrow.down", showsChevron: true) {
                            showFilters = true
                        }

                        Chip(title: "Instant book", icon: "bolt.fill", isSelected: state.filters.instantBookOnly) {
                            withAnimation(Motion.content) { state.filters.instantBookOnly.toggle() }
                        }

                        Chip(title: "Delivery", icon: "shippingbox.fill", isSelected: state.filters.deliveryOnly) {
                            withAnimation(Motion.content) { state.filters.deliveryOnly.toggle() }
                        }

                        Chip(title: "Electric", icon: "bolt.car.fill", isSelected: state.filters.fuels.contains(.electric)) {
                            withAnimation(Motion.content) {
                                if state.filters.fuels.contains(.electric) {
                                    state.filters.fuels.remove(.electric)
                                } else {
                                    state.filters.fuels.insert(.electric)
                                }
                            }
                        }

                        Chip(title: "All-Star hosts", icon: "star.circle.fill", isSelected: state.filters.allStarHostsOnly) {
                            withAnimation(Motion.content) { state.filters.allStarHostsOnly.toggle() }
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                }
                .padding(.bottom, Space.sm)
            }
            .background(
                Rectangle()
                    .fill(Palette.canvas)
                    .opacity(isHeaderCollapsed ? 0 : 1)
                    .overlay(
                        Rectangle()
                            .fill(.regularMaterial)
                            .opacity(isHeaderCollapsed ? 1 : 0)
                    )
                    .ignoresSafeArea(edges: .top)
            )
            .overlay(alignment: .bottom) {
                Hairline().opacity(isHeaderCollapsed ? 1 : 0)
            }
            .animation(Motion.snap, value: isHeaderCollapsed)

            Spacer()
        }
    }

    private var searchPill: some View {
        HStack(spacing: Space.sm) {
            Button {
                Haptics.tap()
                showSearchSheet = true
            } label: {
                HStack(spacing: Space.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.query.place)
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Text("\(state.query.rangeLabel) · \(state.query.dayCount) day\(state.query.dayCount == 1 ? "" : "s")")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Space.md)
                .frame(height: 54)
                .background(
                    Capsule(style: .continuous).fill(Palette.surface)
                )
                .overlay(Capsule(style: .continuous).stroke(Palette.hairlineStrong, lineWidth: 1))
                .elevation(.low)
            }
            .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))

            Button {
                Haptics.tap()
                showMap = true
            } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.inkInverted)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Palette.ink))
            }
            .buttonStyle(PressableStyle(scale: 0.92, dimsOnPress: false))
            .accessibilityLabel("Show results on a map")
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.xs)
    }

    // MARK: Body sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text("Available near you")
                .font(Typo.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Palette.inkTertiary)
            Text("Where are you\nheaded?")
                .font(Typo.display(32))
                .foregroundStyle(Palette.ink)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(isHeaderCollapsed ? 0 : 1)
        .animation(Motion.snap, value: isHeaderCollapsed)
    }

    private var resultsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(state.results.count) car\(state.results.count == 1 ? "" : "s") available")
                .font(Typo.bodyMedium)
                .foregroundStyle(Palette.ink)
            Spacer()
            if !state.filters.isDefault {
                Button {
                    Haptics.tap()
                    withAnimation(Motion.content) { state.filters = SearchFilters() }
                } label: {
                    Text("Clear all")
                        .font(Typo.captionMedium)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
    }

    private var hostPrompt: some View {
        Card(padding: Space.lg, radius: Radius.lg, elevation: .none, fill: Palette.accentWash) {
            VStack(alignment: .leading, spacing: Space.sm) {
                Image(systemName: "key.radiowaves.forward.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Palette.accent)

                Text("Your car could be earning\nwhile you're not using it.")
                    .font(Typo.sectionTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Hosts near you make around $780 a month listing one car. You choose the dates, the price and who drives it.")
                    .font(Typo.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                SecondaryButton(title: "See what you could earn", icon: "arrow.right", fullWidth: false) {
                    state.mode = .host
                    state.hostTab = .dashboard
                }
                .padding(.top, Space.xxs)
            }
        }
    }
}

// MARK: - Scroll offset plumbing

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
