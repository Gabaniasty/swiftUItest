import SwiftUI
import MapKit

// MARK: - Map results
//
// Pins carry the price, because on a map that is the only number worth showing. Tapping
// a pin promotes it and scrolls the card deck; swiping the deck selects the pin. The two
// stay in sync in both directions — a map where those disagree feels broken.

struct MapResultsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.784, longitude: -122.409),
            span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        )
    )
    @State private var selectedID: UUID?
    @State private var detailCar: Car?

    private var cars: [Car] { state.results }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                ForEach(cars) { car in
                    Annotation("", coordinate: car.location.coordinate, anchor: .bottom) {
                        Button {
                            Haptics.select()
                            withAnimation(Motion.move) { selectedID = car.id }
                        } label: {
                            PricePin(price: car.dailyPrice, isSelected: selectedID == car.id)
                        }
                        .buttonStyle(PressableStyle(scale: 0.92, dimsOnPress: false))
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()

            topBar

            VStack {
                Spacer()
                cardDeck
            }
        }
        .onAppear {
            if selectedID == nil { selectedID = cars.first?.id }
        }
        .sheet(item: $detailCar) { car in
            NavigationStack {
                CarDetailView(car: car)
            }
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack(spacing: Space.sm) {
            GlassIconButton(icon: "xmark", size: 44) { dismiss() }

            VStack(spacing: 1) {
                Text(state.query.place)
                    .font(Typo.bodySemibold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text("\(cars.count) car\(cars.count == 1 ? "" : "s") · \(state.query.rangeLabel)")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.inkSecondary)
            }
            .padding(.horizontal, Space.md)
            .frame(height: 44)
            .background(Capsule().fill(.regularMaterial))
            .overlay(Capsule().stroke(Palette.hairline, lineWidth: 0.5))

            Spacer(minLength: 0)
        }
        .pageGutter()
        .padding(.top, Space.xs)
    }

    private var cardDeck: some View {
        // `scrollPosition` is two-way: swiping the deck writes selectedID, and a pin tap
        // writing selectedID scrolls the deck. One binding keeps both in step without a
        // reader or a manual scrollTo fighting the user's gesture.
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Space.sm) {
                ForEach(cars) { car in
                    mapCard(car)
                        .containerRelativeFrame(.horizontal)
                        .id(car.id)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.horizontal, Space.gutter)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedID)
        .padding(.bottom, Space.md)
        .onChange(of: selectedID) { _, newValue in
            guard let newValue else { return }
            recentre(on: newValue)
        }
    }

    private func mapCard(_ car: Car) -> some View {
        Button {
            Haptics.tap()
            detailCar = car
        } label: {
            HStack(spacing: Space.sm) {
                CarThumb(car: car, height: 84, radius: Radius.sm)
                    .frame(width: 112)

                VStack(alignment: .leading, spacing: 4) {
                    Text(car.title)
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    RatingLabel(rating: car.rating, tripCount: car.tripCount, size: 12)
                    Text(car.location.name)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(Money.short(car.dailyPrice))
                            .font(Typo.numeric(16))
                            .foregroundStyle(Palette.ink)
                        Text("/day")
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Space.sm)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
            .elevation(.mid)
        }
        .buttonStyle(PressableStyle(scale: 0.985, dimsOnPress: false))
    }

    private func recentre(on id: UUID) {
        guard let car = cars.first(where: { $0.id == id }) else { return }
        withAnimation(Motion.drawer) {
            camera = .region(
                MKCoordinateRegion(
                    center: car.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
}
