import Foundation
import Observation
import SwiftUI

// MARK: - App state
//
// One observable store for the whole prototype. No network, no persistence: every
// action mutates memory and the UI reacts. Where a real app would await a server,
// this fakes the latency so loading and empty states are actually reachable.

@Observable
final class AppState {

    // Catalogue
    var cars: [Car]
    var hosts: [Host]
    var reviews: [Review]
    let extras: [Extra] = SampleData.extras

    // Account
    var profile: UserProfile
    var paymentMethods: [PaymentMethod]
    var favouriteIDs: Set<UUID> = []
    var recentSearches: [String] = ["San Francisco, CA", "SFO Airport", "Lake Tahoe, CA", "Napa Valley"]

    // Trips & messages
    var trips: [Trip]
    var conversations: [Conversation]

    // Search
    var query = SearchQuery()
    var filters = SearchFilters()
    var isSearching = false

    // Mode
    enum Mode { case guest, host }
    var mode: Mode = .guest

    // Transient UI
    var toast: Toast?
    var selectedTab: AppTab = .explore
    var hostTab: HostTab = .dashboard

    init() {
        let seed = SampleData.build()
        self.cars = seed.cars
        self.hosts = seed.hosts
        self.reviews = seed.reviews
        self.profile = seed.profile
        self.paymentMethods = seed.paymentMethods
        self.trips = seed.trips
        self.conversations = seed.conversations
        self.favouriteIDs = Set(seed.cars.prefix(3).dropFirst().map(\.id))
    }

    // MARK: Lookups

    func car(_ id: UUID) -> Car? { cars.first { $0.id == id } }

    func host(_ id: UUID) -> Host? { hosts.first { $0.id == id } }

    func host(for car: Car) -> Host? { host(car.hostID) }

    func reviews(for carID: UUID) -> [Review] {
        reviews.filter { $0.carID == carID }.sorted { $0.date > $1.date }
    }

    func extra(_ id: String) -> Extra? { extras.first { $0.id == id } }

    /// Cars the signed-in user hosts. Fixed slice of the catalogue so the host side
    /// has something real to manage.
    var myListings: [Car] {
        cars.filter { $0.hostID == SampleData.meHostID }
    }

    var favourites: [Car] {
        cars.filter { favouriteIDs.contains($0.id) }
    }

    // MARK: Search results

    var results: [Car] { results(for: filters) }

    /// Pure — takes the filter set rather than reading it off self, so the filter sheet
    /// can preview a match count for an uncommitted draft without touching app state.
    func results(for filters: SearchFilters) -> [Car] {
        var list = cars.filter { $0.hostID != SampleData.meHostID }

        list = list.filter { car in
            guard filters.priceRange.contains(car.dailyPrice)
                    || car.dailyPrice > SearchFilters.priceCeiling && filters.priceRange.upperBound >= SearchFilters.priceCeiling
            else { return false }
            if !filters.bodyTypes.isEmpty, !filters.bodyTypes.contains(car.bodyType) { return false }
            if !filters.transmissions.isEmpty, !filters.transmissions.contains(car.transmission) { return false }
            if !filters.fuels.isEmpty, !filters.fuels.contains(car.fuel) { return false }
            if !filters.amenities.isSubset(of: Set(car.amenities)) { return false }
            if car.seats < filters.minSeats { return false }
            if car.rating < filters.minRating { return false }
            if filters.instantBookOnly, !car.isInstantBook { return false }
            if filters.deliveryOnly, !car.supportsDelivery { return false }
            if filters.allStarHostsOnly, host(for: car)?.isAllStar != true { return false }
            return true
        }

        switch filters.sort {
        case .recommended:
            list.sort { lhs, rhs in
                let lhsScore = lhs.rating * 12 + Double(lhs.tripCount) * 0.05 - lhs.distanceMiles
                let rhsScore = rhs.rating * 12 + Double(rhs.tripCount) * 0.05 - rhs.distanceMiles
                return lhsScore > rhsScore
            }
        case .priceLow: list.sort { $0.dailyPrice < $1.dailyPrice }
        case .priceHigh: list.sort { $0.dailyPrice > $1.dailyPrice }
        case .distance: list.sort { $0.distanceMiles < $1.distanceMiles }
        case .rating: list.sort { $0.rating > $1.rating }
        }

        return list
    }

    /// Rerun the "request" so the results list can show a loading state.
    func runSearch() {
        isSearching = true
        Task {
            try? await Task.sleep(for: .milliseconds(420))
            await MainActor.run {
                withAnimation(Motion.content) { self.isSearching = false }
            }
        }
    }

    func rememberSearch(_ place: String) {
        guard !place.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(place) == .orderedSame }
        recentSearches.insert(place, at: 0)
        recentSearches = Array(recentSearches.prefix(6))
    }

    // MARK: Favourites

    func isFavourite(_ car: Car) -> Bool { favouriteIDs.contains(car.id) }

    func toggleFavourite(_ car: Car) {
        if favouriteIDs.contains(car.id) {
            favouriteIDs.remove(car.id)
            show(Toast(message: "Removed from favourites", style: .info))
        } else {
            favouriteIDs.insert(car.id)
            Haptics.success()
            show(Toast(message: "Saved to favourites"))
        }
    }

    // MARK: Pricing
    //
    // Single pricing path. Everything that shows money — the detail sheet, checkout,
    // the trip receipt, host earnings — reads a quote from here, so the numbers can
    // never disagree between screens.

    func quote(
        car: Car,
        start: Date,
        end: Date,
        protection: ProtectionPlan,
        extras selections: [ExtraSelection],
        handoff: HandoffMode
    ) -> PriceQuote {
        let days = DateText.days(from: start, to: end)
        let subtotal = car.dailyPrice * Double(days)

        // Longer trips earn a discount, mirroring how these marketplaces price.
        var discountAmount: Double = 0
        var discountLabel: String?
        if days >= 7 {
            discountAmount = subtotal * 0.15
            discountLabel = "Weekly discount (15%)"
        } else if days >= 3 {
            discountAmount = subtotal * 0.07
            discountLabel = "3+ day discount (7%)"
        }

        let discounted = subtotal - discountAmount
        let protectionCost = (discounted * protection.rate).rounded()

        let extrasCost = selections.reduce(0.0) { partial, selection in
            guard let extra = extra(selection.extraID) else { return partial }
            return partial + extra.total(quantity: selection.quantity, days: days)
        }

        let deliveryCost = handoff == .delivery ? (car.deliveryFee ?? 0) : 0
        let tripFee = (discounted * 0.10).rounded()
        let taxes = ((discounted + protectionCost + extrasCost + deliveryCost + tripFee) * 0.0875).rounded()

        return PriceQuote(
            days: days,
            nightlyRate: car.dailyPrice,
            subtotal: subtotal,
            discountLabel: discountLabel,
            discountAmount: discountAmount.rounded(),
            protectionCost: protectionCost,
            extrasCost: extrasCost,
            deliveryCost: deliveryCost,
            tripFee: tripFee,
            taxes: taxes
        )
    }

    // MARK: Booking

    @discardableResult
    func book(_ draft: BookingDraft) -> Trip {
        let car = draft.car
        let quote = quote(
            car: car,
            start: draft.startDate,
            end: draft.endDate,
            protection: draft.protection,
            extras: draft.selectedExtras,
            handoff: draft.handoff
        )

        let trip = Trip(
            id: UUID(),
            carID: car.id,
            startDate: draft.startDate,
            endDate: draft.endDate,
            handoff: draft.handoff,
            handoffAddress: draft.handoff == .delivery ? draft.deliveryAddress : car.location.name,
            protection: draft.protection,
            extras: draft.selectedExtras,
            quote: quote,
            status: car.isInstantBook ? .upcoming : .requested,
            bookedAt: Date(),
            guestName: profile.name,
            isCheckedIn: false,
            checkInPhotoCount: 0,
            guestReviewLeft: false,
            isHostSide: false
        )

        trips.insert(trip, at: 0)
        openThread(for: car, seededWith: trip)
        Haptics.success()
        return trip
    }

    func cancelTrip(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        withAnimation(Motion.move) {
            trips[index].status = .cancelled
        }
        show(Toast(message: "Trip cancelled — refund on its way", style: .info))
    }

    func checkIn(_ trip: Trip, photoCount: Int) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        withAnimation(Motion.move) {
            trips[index].isCheckedIn = true
            trips[index].checkInPhotoCount = photoCount
            trips[index].status = .active
        }
        Haptics.success()
        show(Toast(message: "Checked in. Enjoy the drive."))
    }

    func completeTrip(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        withAnimation(Motion.move) { trips[index].status = .completed }
        show(Toast(message: "Trip ended. Leave a review?", style: .info))
    }

    func extendTrip(_ trip: Trip, byDays days: Int) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }),
              let car = car(trip.carID),
              let newEnd = Calendar.current.date(byAdding: .day, value: days, to: trip.endDate)
        else { return }

        withAnimation(Motion.move) {
            trips[index].endDate = newEnd
            trips[index].quote = quote(
                car: car,
                start: trip.startDate,
                end: newEnd,
                protection: trip.protection,
                extras: trip.extras,
                handoff: trip.handoff
            )
        }
        show(Toast(message: "Trip extended by \(days) day\(days == 1 ? "" : "s")"))
    }

    func leaveReview(for trip: Trip, rating: Double, text: String) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index].guestReviewLeft = true
        reviews.insert(
            Review(
                id: UUID(),
                carID: trip.carID,
                authorName: profile.name,
                date: Date(),
                rating: rating,
                text: text.isEmpty ? "Great car, smooth handover." : text,
                hostReply: nil,
                accentSeed: 9
            ),
            at: 0
        )
        Haptics.success()
        show(Toast(message: "Review posted — thank you"))
    }

    var upcomingTrips: [Trip] {
        trips
            .filter { !$0.isHostSide && [.requested, .upcoming, .active].contains($0.status) }
            .sorted { $0.startDate < $1.startDate }
    }

    var pastTrips: [Trip] {
        trips
            .filter { !$0.isHostSide && [.completed, .cancelled, .declined].contains($0.status) }
            .sorted { $0.startDate > $1.startDate }
    }

    // MARK: Host side

    var hostRequests: [Trip] {
        trips.filter { $0.isHostSide && $0.status == .requested }
    }

    var hostBookedTrips: [Trip] {
        trips
            .filter { $0.isHostSide && [.upcoming, .active].contains($0.status) }
            .sorted { $0.startDate < $1.startDate }
    }

    var hostCompletedTrips: [Trip] {
        trips.filter { $0.isHostSide && $0.status == .completed }
    }

    var hostEarningsToDate: Double {
        hostCompletedTrips.reduce(0) { $0 + $1.quote.hostEarnings }
    }

    var hostEarningsScheduled: Double {
        hostBookedTrips.reduce(0) { $0 + $1.quote.hostEarnings }
    }

    /// Twelve months of earnings for the host chart. Deterministic, derived from the
    /// listing mix so it moves when a listing is added.
    var hostMonthlyEarnings: [Double] {
        let base = max(1, myListings.count)
        return (0..<12).map { month in
            let wave = sin(Double(month) / 11 * .pi * 1.4) * 0.5 + 0.6
            return (420 * Double(base) * wave).rounded()
        }
    }

    func respondToRequest(_ trip: Trip, approve: Bool) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        withAnimation(Motion.move) {
            trips[index].status = approve ? .upcoming : .declined
        }
        Haptics.success()
        show(Toast(
            message: approve ? "Booking approved" : "Request declined",
            style: approve ? .success : .info
        ))
    }

    func addListing(_ car: Car) {
        withAnimation(Motion.content) {
            cars.insert(car, at: 0)
        }
        if !profile.isHost { profile.isHost = true }
        Haptics.success()
        show(Toast(message: "\(car.title) is live"))
    }

    func updateListing(_ car: Car) {
        guard let index = cars.firstIndex(where: { $0.id == car.id }) else { return }
        cars[index] = car
        show(Toast(message: "Listing updated"))
    }

    func removeListing(_ car: Car) {
        withAnimation(Motion.move) {
            cars.removeAll { $0.id == car.id }
        }
        show(Toast(message: "\(car.title) unlisted", style: .info))
    }

    // MARK: Messaging

    var unreadMessageCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    func send(_ text: String, to conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        conversations[index].messages.append(
            Message(id: UUID(), text: text, sentAt: Date(), isFromMe: true, isSystem: false)
        )

        // Fake a reply so the thread feels alive.
        let conversationID = conversations[index].id
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            await MainActor.run {
                guard let index = self.conversations.firstIndex(where: { $0.id == conversationID }) else { return }
                let replies = [
                    "Sounds good — I'll have it cleaned and fuelled for you.",
                    "That works. I'll text you the exact spot the morning of pickup.",
                    "Yep, happy to do that. See you then!",
                    "No problem at all. Anything else you need?"
                ]
                withAnimation(Motion.enter) {
                    self.conversations[index].messages.append(
                        Message(
                            id: UUID(),
                            text: replies[self.conversations[index].messages.count % replies.count],
                            sentAt: Date(),
                            isFromMe: false,
                            isSystem: false
                        )
                    )
                }
            }
        }
    }

    func markRead(_ conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
    }

    /// Booking a car should produce a thread with that host, like the real thing.
    private func openThread(for car: Car, seededWith trip: Trip) {
        guard let host = host(for: car) else { return }
        let opener = Message(
            id: UUID(),
            text: trip.status == .requested
                ? "\(profile.name) requested your \(car.title) for \(DateText.range(trip.startDate, trip.endDate))."
                : "Booking confirmed for \(DateText.range(trip.startDate, trip.endDate)).",
            sentAt: Date(),
            isFromMe: false,
            isSystem: true
        )

        if let index = conversations.firstIndex(where: { $0.carID == car.id }) {
            conversations[index].messages.append(opener)
            conversations.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
        } else {
            conversations.insert(
                Conversation(
                    id: UUID(),
                    participantName: host.name,
                    participantSeed: host.accentSeed,
                    carID: car.id,
                    messages: [
                        opener,
                        Message(
                            id: UUID(),
                            text: "Hi \(profile.name.split(separator: " ").first.map(String.init) ?? "there")! Thanks for booking. Let me know roughly what time suits for pickup.",
                            sentAt: Date().addingTimeInterval(30),
                            isFromMe: false,
                            isSystem: false
                        )
                    ],
                    unreadCount: 1,
                    isHostThread: false
                ),
                at: 0
            )
        }
    }

    // MARK: Account actions

    func verifyLicense() {
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            await MainActor.run {
                withAnimation(Motion.move) { self.profile.isLicenseVerified = true }
                Haptics.success()
                self.show(Toast(message: "Driver's licence approved"))
            }
        }
    }

    func addPaymentMethod(brand: String, last4: String, expiry: String) {
        let isFirst = paymentMethods.isEmpty
        paymentMethods.append(
            PaymentMethod(id: UUID(), brand: brand, last4: last4, expiry: expiry, isDefault: isFirst)
        )
        show(Toast(message: "\(brand) •••• \(last4) added"))
    }

    func makeDefault(_ method: PaymentMethod) {
        for index in paymentMethods.indices {
            paymentMethods[index].isDefault = paymentMethods[index].id == method.id
        }
        show(Toast(message: "Default payment updated"))
    }

    func removePaymentMethod(_ method: PaymentMethod) {
        paymentMethods.removeAll { $0.id == method.id }
        if !paymentMethods.contains(where: \.isDefault), !paymentMethods.isEmpty {
            paymentMethods[0].isDefault = true
        }
    }

    var defaultPaymentMethod: PaymentMethod? {
        paymentMethods.first(where: \.isDefault) ?? paymentMethods.first
    }

    // MARK: Toast

    func show(_ toast: Toast) {
        withAnimation(Motion.enter) { self.toast = toast }
        let id = toast.id
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            await MainActor.run {
                guard self.toast?.id == id else { return }
                withAnimation(Motion.exit) { self.toast = nil }
            }
        }
    }
}

// MARK: - Tabs

enum AppTab: Hashable {
    case explore, favourites, trips, inbox, profile

    var title: String {
        switch self {
        case .explore: "Explore"
        case .favourites: "Saved"
        case .trips: "Trips"
        case .inbox: "Inbox"
        case .profile: "You"
        }
    }

    var symbol: String {
        switch self {
        case .explore: "magnifyingglass"
        case .favourites: "heart"
        case .trips: "car.side"
        case .inbox: "bubble.left.and.bubble.right"
        case .profile: "person"
        }
    }

    var filledSymbol: String {
        switch self {
        case .explore: "magnifyingglass"
        case .favourites: "heart.fill"
        case .trips: "car.side.fill"
        case .inbox: "bubble.left.and.bubble.right.fill"
        case .profile: "person.fill"
        }
    }
}

enum HostTab: Hashable {
    case dashboard, listings, requests, earnings

    var title: String {
        switch self {
        case .dashboard: "Today"
        case .listings: "Vehicles"
        case .requests: "Requests"
        case .earnings: "Earnings"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .listings: "car.2"
        case .requests: "tray.full"
        case .earnings: "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Booking draft
//
// Held for the length of the booking flow only. Separate from AppState so
// abandoning the flow leaves nothing behind.

@Observable
final class BookingDraft {
    let car: Car
    var startDate: Date
    var endDate: Date
    var handoff: HandoffMode = .hostLocation
    var deliveryAddress: String = "1 Ferry Building, San Francisco"
    var protection: ProtectionPlan = .standard
    var quantities: [String: Int] = [:]
    var message: String = ""
    var agreedToTerms = false

    init(car: Car, start: Date, end: Date) {
        self.car = car
        self.startDate = start
        self.endDate = end
        if !car.supportsDelivery { handoff = .hostLocation }
    }

    var selectedExtras: [ExtraSelection] {
        quantities
            .filter { $0.value > 0 }
            .map { ExtraSelection(extraID: $0.key, quantity: $0.value) }
            .sorted { $0.extraID < $1.extraID }
    }

    var days: Int { DateText.days(from: startDate, to: endDate) }

    func quantity(for extra: Extra) -> Int { quantities[extra.id] ?? 0 }

    func setQuantity(_ value: Int, for extra: Extra) {
        quantities[extra.id] = value
    }
}
