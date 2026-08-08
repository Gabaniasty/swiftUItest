import SwiftUI

// MARK: - Saved cars

struct FavouritesView: View {
    @Environment(AppState.self) private var state
    @State private var path: [Car] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if state.favourites.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "Nothing saved yet",
                        message: "Tap the heart on any car and it'll wait for you here.",
                        actionTitle: "Browse cars"
                    ) {
                        state.selectedTab = .explore
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Space.xl) {
                            HStack {
                                Text("\(state.favourites.count) car\(state.favourites.count == 1 ? "" : "s") saved")
                                    .font(Typo.bodyMedium)
                                    .foregroundStyle(Palette.inkSecondary)
                                Spacer()
                            }

                            ForEach(Array(state.favourites.enumerated()), id: \.element.id) { index, car in
                                NavigationLink(value: car) {
                                    CarCard(car: car)
                                }
                                .buttonStyle(PressableStyle(scale: 0.985, dimsOnPress: false))
                                .appear(index)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        state.toggleFavourite(car)
                                    } label: {
                                        Label("Remove from saved", systemImage: "heart.slash")
                                    }
                                }
                            }
                        }
                        .pageGutter()
                        .padding(.vertical, Space.md)
                        .padding(.bottom, Space.xxl)
                    }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Car.self) { car in
                CarDetailView(car: car)
            }
        }
        .animation(Motion.content, value: state.favouriteIDs)
    }
}
