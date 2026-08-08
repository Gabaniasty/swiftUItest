import Foundation
import CoreLocation
import SwiftUI

// MARK: - Vehicle taxonomy

enum BodyType: String, CaseIterable, Identifiable, Codable {
    case car, suv, truck, minivan, sports, convertible, van

    var id: String { rawValue }

    var label: String {
        switch self {
        case .car: "Car"
        case .suv: "SUV"
        case .truck: "Truck"
        case .minivan: "Minivan"
        case .sports: "Sports car"
        case .convertible: "Convertible"
        case .van: "Van"
        }
    }

    /// SF Symbol used by the procedural artwork. Resolved through `Symbols.resolve`
    /// so a symbol missing on an older OS degrades instead of rendering blank.
    var symbol: String {
        switch self {
        case .car: "car.side.fill"
        case .suv: "suv.side.fill"
        case .truck: "truck.pickup.side.fill"
        case .minivan: "van.passenger.side.fill"
        case .sports: "car.side.fill"
        case .convertible: "car.top.door.front.left.open.fill"
        case .van: "bus.side.fill"
        }
    }
}

enum Transmission: String, CaseIterable, Identifiable, Codable {
    case automatic, manual

    var id: String { rawValue }
    var label: String { self == .automatic ? "Automatic" : "Manual" }
}

enum FuelKind: String, CaseIterable, Identifiable, Codable {
    case gas, hybrid, electric, diesel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gas: "Gas"
        case .hybrid: "Hybrid"
        case .electric: "Electric"
        case .diesel: "Diesel"
        }
    }

    var symbol: String {
        switch self {
        case .gas, .diesel: "fuelpump.fill"
        case .hybrid: "leaf.fill"
        case .electric: "bolt.fill"
        }
    }
}

/// A single amenity. Kept as an enum rather than free text so filters can match on it.
enum Amenity: String, CaseIterable, Identifiable, Codable {
    case appleCarPlay, androidAuto, bluetooth, backupCamera, heatedSeats, ventilatedSeats
    case sunroof, allWheelDrive, usbCharger, auxInput, gps, childSeat, bikeRack, skiRack
    case petFriendly, toll, snowTires, keylessEntry, blindSpot, adaptiveCruise

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appleCarPlay: "Apple CarPlay"
        case .androidAuto: "Android Auto"
        case .bluetooth: "Bluetooth"
        case .backupCamera: "Backup camera"
        case .heatedSeats: "Heated seats"
        case .ventilatedSeats: "Cooled seats"
        case .sunroof: "Sunroof"
        case .allWheelDrive: "All-wheel drive"
        case .usbCharger: "USB charger"
        case .auxInput: "AUX input"
        case .gps: "GPS"
        case .childSeat: "Child seat"
        case .bikeRack: "Bike rack"
        case .skiRack: "Ski rack"
        case .petFriendly: "Pet friendly"
        case .toll: "Toll pass"
        case .snowTires: "Snow tires"
        case .keylessEntry: "Keyless entry"
        case .blindSpot: "Blind spot warning"
        case .adaptiveCruise: "Adaptive cruise"
        }
    }

    var symbol: String {
        switch self {
        case .appleCarPlay: "apple.logo"
        case .androidAuto: "point.3.connected.trianglepath.dotted"
        case .bluetooth: "wave.3.right"
        case .backupCamera: "video.fill"
        case .heatedSeats: "flame.fill"
        case .ventilatedSeats: "snowflake"
        case .sunroof: "sun.max.fill"
        case .allWheelDrive: "car.2.fill"
        case .usbCharger: "cable.connector"
        case .auxInput: "headphones"
        case .gps: "location.fill"
        case .childSeat: "figure.child"
        case .bikeRack: "bicycle"
        case .skiRack: "figure.skiing.downhill"
        case .petFriendly: "pawprint.fill"
        case .toll: "road.lanes"
        case .snowTires: "snowflake.circle.fill"
        case .keylessEntry: "key.radiowaves.forward.fill"
        case .blindSpot: "eye.trianglebadge.exclamationmark.fill"
        case .adaptiveCruise: "speedometer"
        }
    }
}

// MARK: - Host

struct Host: Identifiable, Hashable {
    let id: UUID
    var name: String
    var joinedYear: Int
    var rating: Double
    var tripCount: Int
    var responseRate: Int
    var responseTimeMinutes: Int
    var isAllStar: Bool
    var isVerified: Bool
    var bio: String
    var city: String
    var accentSeed: Int

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var responseTimeLabel: String {
        if responseTimeMinutes < 60 { return "within \(responseTimeMinutes) min" }
        let hours = responseTimeMinutes / 60
        return "within \(hours) hr\(hours == 1 ? "" : "s")"
    }
}

// MARK: - Location

struct PickupLocation: Hashable {
    var name: String
    var detail: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Car

struct Car: Identifiable, Hashable {
    let id: UUID
    var make: String
    var model: String
    var year: Int
    var trim: String
    var bodyType: BodyType
    var transmission: Transmission
    var fuel: FuelKind
    var seats: Int
    var doors: Int
    /// MPG for combustion, estimated range in miles for electric.
    var efficiency: Int
    var dailyPrice: Double
    /// Shown struck through when a discount is active.
    var listPrice: Double?
    var rating: Double
    var tripCount: Int
    var hostID: UUID
    var location: PickupLocation
    var distanceMiles: Double
    var amenities: [Amenity]
    var blurb: String
    var details: String
    var rules: [String]
    var isInstantBook: Bool
    var deliveryFee: Double?
    var paint: CarPaint
    var photoCount: Int
    var minTripDays: Int
    var includedMilesPerDay: Int
    var extraMileFee: Double
    var isNewListing: Bool
    /// Dates already booked out, normalised to start-of-day. Drives the availability
    /// calendar and blocks selection in the booking flow.
    var blockedDates: Set<Date>

    var title: String { "\(make) \(model)" }
    var fullTitle: String { "\(year) \(make) \(model)" }

    var supportsDelivery: Bool { deliveryFee != nil }

    var efficiencyLabel: String {
        fuel == .electric ? "\(efficiency) mi range" : "\(efficiency) MPG"
    }

    var discountPercent: Int? {
        guard let listPrice, listPrice > dailyPrice else { return nil }
        return Int(((listPrice - dailyPrice) / listPrice * 100).rounded())
    }
}

// MARK: - Reviews

struct Review: Identifiable, Hashable {
    let id: UUID
    var carID: UUID
    var authorName: String
    var date: Date
    var rating: Double
    var text: String
    var hostReply: String?
    var accentSeed: Int

    var initials: String {
        authorName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

struct RatingBreakdown: Hashable {
    var cleanliness: Double
    var maintenance: Double
    var communication: Double
    var convenience: Double
    var accuracy: Double

    var overall: Double {
        (cleanliness + maintenance + communication + convenience + accuracy) / 5
    }
}

// MARK: - Extras & protection

struct Extra: Identifiable, Hashable {
    let id: String
    var name: String
    var detail: String
    var symbol: String
    var price: Double
    var isPerDay: Bool
    var maxQuantity: Int

    func total(quantity: Int, days: Int) -> Double {
        Double(quantity) * price * (isPerDay ? Double(days) : 1)
    }

    var priceLabel: String {
        isPerDay ? "\(Money.short(price))/day" : "\(Money.short(price)) per trip"
    }
}

enum ProtectionPlan: String, CaseIterable, Identifiable, Hashable {
    case minimum, standard, premium

    var id: String { rawValue }

    var label: String {
        switch self {
        case .minimum: "Minimum"
        case .standard: "Standard"
        case .premium: "Premium"
        }
    }

    /// Multiplier applied to the trip subtotal.
    var rate: Double {
        switch self {
        case .minimum: 0.18
        case .standard: 0.40
        case .premium: 0.65
        }
    }

    var deductible: Double {
        switch self {
        case .minimum: 3000
        case .standard: 500
        case .premium: 0
        }
    }

    var summary: String {
        switch self {
        case .minimum: "Lowest cost, highest out-of-pocket if something happens."
        case .standard: "A middle ground most guests pick."
        case .premium: "No deductible and the broadest cover."
        }
    }

    var inclusions: [String] {
        switch self {
        case .minimum:
            ["$3,000 deductible", "Liability up to state minimum", "24/7 roadside assistance"]
        case .standard:
            ["$500 deductible", "$750,000 liability cover", "24/7 roadside assistance", "Lost key reimbursement"]
        case .premium:
            ["$0 deductible", "$750,000 liability cover", "24/7 roadside assistance", "Lost key reimbursement", "Interior damage cover"]
        }
    }
}

// MARK: - Trips

enum TripStatus: String, Hashable {
    case requested, upcoming, active, completed, cancelled, declined

    var label: String {
        switch self {
        case .requested: "Awaiting host"
        case .upcoming: "Booked"
        case .active: "In progress"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        case .declined: "Declined"
        }
    }

    var tint: Color {
        switch self {
        case .requested: Palette.star
        case .upcoming: Palette.accent
        case .active: Palette.info
        case .completed: Palette.inkTertiary
        case .cancelled, .declined: Palette.danger
        }
    }

    var symbol: String {
        switch self {
        case .requested: "clock.fill"
        case .upcoming: "checkmark.seal.fill"
        case .active: "car.side.fill"
        case .completed: "flag.checkered"
        case .cancelled, .declined: "xmark.circle.fill"
        }
    }
}

enum HandoffMode: String, Hashable, CaseIterable {
    case hostLocation, delivery

    var label: String {
        self == .hostLocation ? "Pick up from host" : "Delivered to you"
    }

    var symbol: String {
        self == .hostLocation ? "figure.walk" : "shippingbox.fill"
    }
}

struct ExtraSelection: Hashable, Identifiable {
    var extraID: String
    var quantity: Int
    var id: String { extraID }
}

/// The money side of a booking, computed once and stored so a saved trip never
/// silently re-prices itself.
struct PriceQuote: Hashable {
    var days: Int
    var nightlyRate: Double
    var subtotal: Double
    var discountLabel: String?
    var discountAmount: Double
    var protectionCost: Double
    var extrasCost: Double
    var deliveryCost: Double
    var tripFee: Double
    var taxes: Double

    var total: Double {
        subtotal - discountAmount + protectionCost + extrasCost + deliveryCost + tripFee + taxes
    }

    /// What the host actually banks, shown in host-side screens.
    var hostEarnings: Double {
        (subtotal - discountAmount) * 0.75
    }
}

struct Trip: Identifiable, Hashable {
    let id: UUID
    var carID: UUID
    var startDate: Date
    var endDate: Date
    var handoff: HandoffMode
    var handoffAddress: String
    var protection: ProtectionPlan
    var extras: [ExtraSelection]
    var quote: PriceQuote
    var status: TripStatus
    var bookedAt: Date
    var guestName: String
    var isCheckedIn: Bool
    var checkInPhotoCount: Int
    var guestReviewLeft: Bool
    /// Set when the guest is the host in this scenario (host-side trip list).
    var isHostSide: Bool

    var dayCount: Int { quote.days }
}

// MARK: - Messaging

struct Message: Identifiable, Hashable {
    let id: UUID
    var text: String
    var sentAt: Date
    var isFromMe: Bool
    var isSystem: Bool
}

struct Conversation: Identifiable, Hashable {
    let id: UUID
    var participantName: String
    var participantSeed: Int
    var carID: UUID?
    var messages: [Message]
    var unreadCount: Int
    var isHostThread: Bool

    var lastMessage: Message? { messages.last }
}

// MARK: - Account

struct PaymentMethod: Identifiable, Hashable {
    let id: UUID
    var brand: String
    var last4: String
    var expiry: String
    var isDefault: Bool

    var symbol: String {
        switch brand.lowercased() {
        case "apple pay": "apple.logo"
        case "paypal": "p.circle.fill"
        default: "creditcard.fill"
        }
    }
}

struct UserProfile: Hashable {
    var name: String
    var email: String
    var joinedYear: Int
    var city: String
    var tripCount: Int
    var rating: Double
    var isLicenseVerified: Bool
    var isPhoneVerified: Bool
    var isEmailVerified: Bool
    var isHost: Bool

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    var verificationProgress: Double {
        let checks = [isLicenseVerified, isPhoneVerified, isEmailVerified]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }
}

// MARK: - Search

enum SortOrder: String, CaseIterable, Identifiable {
    case recommended, priceLow, priceHigh, distance, rating

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recommended: "Recommended"
        case .priceLow: "Price: low to high"
        case .priceHigh: "Price: high to low"
        case .distance: "Closest first"
        case .rating: "Top rated"
        }
    }
}

struct SearchFilters: Hashable {
    var priceRange: ClosedRange<Double> = 25...400
    var bodyTypes: Set<BodyType> = []
    var transmissions: Set<Transmission> = []
    var fuels: Set<FuelKind> = []
    var amenities: Set<Amenity> = []
    var minSeats: Int = 0
    var minRating: Double = 0
    var instantBookOnly: Bool = false
    var deliveryOnly: Bool = false
    var allStarHostsOnly: Bool = false
    var sort: SortOrder = .recommended

    static let priceFloor: Double = 25
    static let priceCeiling: Double = 400

    var isDefault: Bool { self == SearchFilters() }

    /// Count shown on the filter chip badge.
    var activeCount: Int {
        var count = 0
        if priceRange != SearchFilters.priceFloor...SearchFilters.priceCeiling { count += 1 }
        count += bodyTypes.isEmpty ? 0 : 1
        count += transmissions.isEmpty ? 0 : 1
        count += fuels.isEmpty ? 0 : 1
        count += amenities.count
        if minSeats > 0 { count += 1 }
        if minRating > 0 { count += 1 }
        if instantBookOnly { count += 1 }
        if deliveryOnly { count += 1 }
        if allStarHostsOnly { count += 1 }
        return count
    }
}

struct SearchQuery: Hashable {
    var place: String = "San Francisco, CA"
    var startDate: Date
    var endDate: Date

    init(place: String = "San Francisco, CA", startDate: Date? = nil, endDate: Date? = nil) {
        self.place = place
        let calendar = Calendar.current
        let defaultStart = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date())) ?? Date()
        self.startDate = startDate ?? calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultStart) ?? defaultStart
        let defaultEnd = calendar.date(byAdding: .day, value: 3, to: defaultStart) ?? defaultStart
        self.endDate = endDate ?? calendar.date(bySettingHour: 10, minute: 0, second: 0, of: defaultEnd) ?? defaultEnd
    }

    var dayCount: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    var rangeLabel: String { DateText.range(startDate, endDate) }
}

// MARK: - Toast

struct Toast: Identifiable, Equatable {
    enum Style: Equatable {
        case success, info, warning

        var tint: Color {
            switch self {
            case .success: Palette.success
            case .info: Palette.info
            case .warning: Palette.star
            }
        }
    }

    let id = UUID()
    var message: String
    var style: Style = .success

    var icon: String {
        switch style {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }
}
