import Foundation

// MARK: - Seed data
//
// Everything the prototype shows comes from here. Written to look like a real
// marketplace: uneven ratings, some listings with no trips yet, hosts who reply
// slowly, one trip mid-flight and a couple of pending host requests.

struct SeedBundle {
    var cars: [Car]
    var hosts: [Host]
    var reviews: [Review]
    var profile: UserProfile
    var paymentMethods: [PaymentMethod]
    var trips: [Trip]
    var conversations: [Conversation]
}

enum SampleData {

    /// The signed-in user, in their capacity as a host.
    static let meHostID = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!

    static let extras: [Extra] = [
        Extra(id: "prepaid-fuel", name: "Prepaid fuel", detail: "Return it at any level — no refuelling stop.", symbol: "fuelpump.fill", price: 75, isPerDay: false, maxQuantity: 1),
        Extra(id: "unlimited-miles", name: "Unlimited miles", detail: "Removes the daily mileage cap.", symbol: "infinity", price: 24, isPerDay: true, maxQuantity: 1),
        Extra(id: "child-seat", name: "Child seat", detail: "Rear-facing, fitted before pickup.", symbol: "figure.child", price: 12, isPerDay: true, maxQuantity: 3),
        Extra(id: "extra-driver", name: "Additional driver", detail: "Add a second approved driver.", symbol: "person.2.fill", price: 10, isPerDay: true, maxQuantity: 2),
        Extra(id: "toll-pass", name: "Toll pass", detail: "Bridges and express lanes, no invoices later.", symbol: "road.lanes", price: 9, isPerDay: true, maxQuantity: 1),
        Extra(id: "phone-mount", name: "Phone mount", detail: "Magnetic vent mount with charging.", symbol: "iphone.gen3", price: 5, isPerDay: false, maxQuantity: 1)
    ]

    static func build() -> SeedBundle {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func day(_ offset: Int, hour: Int = 10) -> Date {
            let base = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }

        func blocked(_ offsets: [Int]) -> Set<Date> {
            Set(offsets.compactMap { calendar.date(byAdding: .day, value: $0, to: today) })
        }

        // MARK: Hosts

        let marcus = Host(id: UUID(), name: "Marcus Whitfield", joinedYear: 2019, rating: 4.96, tripCount: 412, responseRate: 100, responseTimeMinutes: 8, isAllStar: true, isVerified: true, bio: "I keep a small fleet of well-sorted German cars. Every one gets detailed between trips and serviced on schedule. Message me any time — I usually reply within a few minutes.", city: "San Francisco", accentSeed: 0)
        let priya = Host(id: UUID(), name: "Priya Raman", joinedYear: 2021, rating: 4.91, tripCount: 168, responseRate: 98, responseTimeMinutes: 22, isAllStar: true, isVerified: true, bio: "Weekend adventurer renting out the cars I love. Both of mine are set up for trips to Tahoe — roof box and chains included at no extra cost in winter.", city: "Oakland", accentSeed: 1)
        let dilan = Host(id: UUID(), name: "Dilan Ortega", joinedYear: 2022, rating: 4.72, tripCount: 54, responseRate: 92, responseTimeMinutes: 95, isAllStar: false, isVerified: true, bio: "Straightforward rentals, fair prices. I work weekdays so pickups before 9am or after 6pm are easiest.", city: "Daly City", accentSeed: 2)
        let sofia = Host(id: UUID(), name: "Sofia Lindqvist", joinedYear: 2020, rating: 4.99, tripCount: 289, responseRate: 100, responseTimeMinutes: 5, isAllStar: true, isVerified: true, bio: "Electric only. Charged to 100% before every handover, and I'll walk you through the charging network if it's your first EV.", city: "San Francisco", accentSeed: 3)
        let ray = Host(id: UUID(), name: "Ray Okonkwo", joinedYear: 2023, rating: 4.64, tripCount: 19, responseRate: 88, responseTimeMinutes: 180, isAllStar: false, isVerified: false, bio: "New here but taking it seriously. The truck is my daily so it's genuinely looked after.", city: "Berkeley", accentSeed: 4)
        let me = Host(id: meHostID, name: "Alex Mercer", joinedYear: 2022, rating: 4.88, tripCount: 63, responseRate: 97, responseTimeMinutes: 30, isAllStar: false, isVerified: true, bio: "Renting out two cars around the Mission. Flexible on pickup times.", city: "San Francisco", accentSeed: 5)

        let hosts = [marcus, priya, dilan, sofia, ray, me]

        // MARK: Cars

        let cars: [Car] = [
            Car(
                id: UUID(), make: "Porsche", model: "911 Carrera", year: 2022, trim: "Carrera S",
                bodyType: .sports, transmission: .automatic, fuel: .gas, seats: 4, doors: 2, efficiency: 22,
                dailyPrice: 389, listPrice: 445, rating: 4.98, tripCount: 87, hostID: marcus.id,
                location: PickupLocation(name: "Marina District", detail: "Chestnut St & Fillmore", latitude: 37.8006, longitude: -122.4364),
                distanceMiles: 1.4,
                amenities: [.appleCarPlay, .bluetooth, .backupCamera, .heatedSeats, .ventilatedSeats, .keylessEntry, .blindSpot, .adaptiveCruise],
                blurb: "The one you book for the coast road.",
                details: "A 2022 Carrera S in Midnight Blue, kept in a garage and driven gently. Sport Chrono, adaptive suspension, and a PDK gearbox that makes traffic painless. It is quick, but it is also genuinely easy to drive slowly — most guests take it down Highway 1 and back.\n\nA few honest notes: it is low, so steep driveways need care, and the front boot holds two soft bags rather than suitcases.",
                rules: ["No smoking, ever", "Premium fuel only (91+)", "Keep it off unpaved roads", "No track or timed events"],
                isInstantBook: true, deliveryFee: 65, paint: .midnight, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 150, extraMileFee: 1.25, isNewListing: false,
                blockedDates: blocked([5, 6, 7, 18, 19])
            ),
            Car(
                id: UUID(), make: "Tesla", model: "Model 3", year: 2023, trim: "Long Range AWD",
                bodyType: .car, transmission: .automatic, fuel: .electric, seats: 5, doors: 4, efficiency: 341,
                dailyPrice: 94, listPrice: nil, rating: 4.93, tripCount: 214, hostID: sofia.id,
                location: PickupLocation(name: "Hayes Valley", detail: "Octavia Blvd", latitude: 37.7759, longitude: -122.4245),
                distanceMiles: 0.8,
                amenities: [.bluetooth, .backupCamera, .heatedSeats, .allWheelDrive, .usbCharger, .gps, .keylessEntry, .blindSpot, .adaptiveCruise],
                blurb: "Charged to 100% before every trip.",
                details: "Long Range AWD with about 330 miles of real-world range. Supercharging is the easy option and the car routes you to chargers automatically — I'll show you how it works at handover if you have not driven an EV before.\n\nIt has the acceleration to surprise you, so take the first few minutes gently. Autopilot is enabled for lane keeping and adaptive cruise.",
                rules: ["Return with at least 20% charge", "No smoking or vaping", "Pets in a carrier only"],
                isInstantBook: true, deliveryFee: 35, paint: .pearl, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 200, extraMileFee: 0.85, isNewListing: false,
                blockedDates: blocked([2, 3, 11])
            ),
            Car(
                id: UUID(), make: "Toyota", model: "4Runner", year: 2021, trim: "TRD Off-Road",
                bodyType: .suv, transmission: .automatic, fuel: .gas, seats: 5, doors: 4, efficiency: 19,
                dailyPrice: 118, listPrice: 135, rating: 4.89, tripCount: 96, hostID: priya.id,
                location: PickupLocation(name: "Rockridge, Oakland", detail: "College Ave", latitude: 37.8443, longitude: -122.2516),
                distanceMiles: 9.2,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .allWheelDrive, .skiRack, .snowTires, .usbCharger, .petFriendly],
                blurb: "Built for Tahoe. Chains and roof box included.",
                details: "My own weekend car, set up properly for the Sierra. Full-time 4WD, all-terrain tires, and a Yakima box on the roof for skis or bags. In winter I include chains and I will make sure you know how to fit them.\n\nIt drinks fuel on the highway — budget for that — but it will get you up an unploughed forest road without drama.",
                rules: ["Chains must be carried Nov–Apr", "Off-road use is fine, mud is not", "Return roughly as clean as you got it"],
                isInstantBook: false, deliveryFee: nil, paint: .forest, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 250, extraMileFee: 0.65, isNewListing: false,
                blockedDates: blocked([1, 8, 9, 10, 22, 23])
            ),
            Car(
                id: UUID(), make: "Honda", model: "Civic", year: 2022, trim: "Sport",
                bodyType: .car, transmission: .automatic, fuel: .gas, seats: 5, doors: 4, efficiency: 36,
                dailyPrice: 47, listPrice: nil, rating: 4.81, tripCount: 143, hostID: dilan.id,
                location: PickupLocation(name: "Daly City BART", detail: "John Daly Blvd", latitude: 37.7061, longitude: -122.4690),
                distanceMiles: 7.6,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .usbCharger, .auxInput],
                blurb: "Cheap, clean, reliable. Nothing more, nothing less.",
                details: "The sensible choice. It is a well-kept Civic Sport that returns close to 36 MPG in mixed driving, fits four adults properly, and takes two large suitcases in the boot.\n\nI park it at Daly City BART, which makes it easy if you are coming in on transit. Pickup before 9am or after 6pm works best for me.",
                rules: ["No smoking", "Return with the same fuel level", "Street parking only — no valet"],
                isInstantBook: true, deliveryFee: 25, paint: .slate, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 200, extraMileFee: 0.45, isNewListing: false,
                blockedDates: blocked([4, 12])
            ),
            Car(
                id: UUID(), make: "Ford", model: "F-150", year: 2020, trim: "XLT SuperCrew",
                bodyType: .truck, transmission: .automatic, fuel: .gas, seats: 5, doors: 4, efficiency: 20,
                dailyPrice: 102, listPrice: nil, rating: 4.58, tripCount: 19, hostID: ray.id,
                location: PickupLocation(name: "West Berkeley", detail: "San Pablo Ave", latitude: 37.8672, longitude: -122.2951),
                distanceMiles: 12.1,
                amenities: [.appleCarPlay, .bluetooth, .backupCamera, .allWheelDrive, .usbCharger, .toll],
                blurb: "For the move you keep putting off.",
                details: "A SuperCrew with the 5.5ft bed and a tonneau cover. Most people book it for moving apartments or hauling from a lumber yard — it will take a full pallet with the tailgate down.\n\nIt is my daily driver so it is looked after, but it is a working truck and has a few scuffs in the bed. I would rather tell you now than have it be a surprise.",
                rules: ["Nothing over 1,500 lb in the bed", "Sweep the bed out before returning", "No towing without asking first"],
                isInstantBook: false, deliveryFee: nil, paint: .ember, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 150, extraMileFee: 0.70, isNewListing: false,
                blockedDates: blocked([14, 15])
            ),
            Car(
                id: UUID(), make: "BMW", model: "M4 Competition", year: 2023, trim: "xDrive",
                bodyType: .sports, transmission: .automatic, fuel: .gas, seats: 4, doors: 2, efficiency: 20,
                dailyPrice: 265, listPrice: nil, rating: 4.94, tripCount: 61, hostID: marcus.id,
                location: PickupLocation(name: "SoMa", detail: "Brannan St garage", latitude: 37.7786, longitude: -122.3934),
                distanceMiles: 2.2,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .heatedSeats, .ventilatedSeats, .allWheelDrive, .keylessEntry, .blindSpot, .adaptiveCruise, .sunroof],
                blurb: "510hp and surprisingly civil in traffic.",
                details: "The Competition with xDrive, so it is usable in the rain and cold mornings. Carbon bucket seats up front — brilliant once you are in, slightly awkward to climb over. Comfort mode genuinely is comfortable.\n\nI keep it in a secure garage in SoMa. There is a 20-minute walkthrough at handover because there are a lot of drive modes and I would rather you actually enjoy it.",
                rules: ["Premium fuel only", "No smoking", "No track days", "Under 25s cannot drive this one"],
                isInstantBook: true, deliveryFee: 55, paint: .graphite, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 125, extraMileFee: 1.50, isNewListing: false,
                blockedDates: blocked([3, 4, 5, 20])
            ),
            Car(
                id: UUID(), make: "Chrysler", model: "Pacifica", year: 2021, trim: "Touring L",
                bodyType: .minivan, transmission: .automatic, fuel: .hybrid, seats: 7, doors: 4, efficiency: 30,
                dailyPrice: 89, listPrice: 99, rating: 4.86, tripCount: 77, hostID: priya.id,
                location: PickupLocation(name: "Temescal, Oakland", detail: "Telegraph Ave", latitude: 37.8360, longitude: -122.2620),
                distanceMiles: 10.4,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .childSeat, .usbCharger, .petFriendly, .gps],
                blurb: "Seven seats and doors the kids can't slam.",
                details: "The family workhorse. Stow-and-go middle seats fold flat, so it goes from seven seats to a van-sized load bay in about a minute. Plug-in hybrid, so short trips around town are electric and quiet.\n\nTwo child seats are available at no charge — just tell me the ages and I will fit them before you arrive.",
                rules: ["No smoking", "Car seats must be fitted by me or checked by me", "Return with the same charge level"],
                isInstantBook: true, deliveryFee: 40, paint: .ice, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 200, extraMileFee: 0.55, isNewListing: false,
                blockedDates: blocked([6, 7, 16])
            ),
            Car(
                id: UUID(), make: "Jeep", model: "Wrangler", year: 2022, trim: "Rubicon 4xe",
                bodyType: .suv, transmission: .automatic, fuel: .hybrid, seats: 5, doors: 4, efficiency: 21,
                dailyPrice: 139, listPrice: nil, rating: 4.77, tripCount: 44, hostID: dilan.id,
                location: PickupLocation(name: "Outer Sunset", detail: "Judah St & 46th", latitude: 37.7601, longitude: -122.5062),
                distanceMiles: 5.9,
                amenities: [.appleCarPlay, .bluetooth, .backupCamera, .allWheelDrive, .bikeRack, .snowTires, .petFriendly, .usbCharger],
                blurb: "Roof comes off in about ten minutes.",
                details: "Rubicon 4xe — the plug-in hybrid, so it is quiet around town and still has proper low-range gearing and locking differentials when you leave the tarmac.\n\nThe hard top panels come off and store in the back. I will show you how. Expect wind noise on the highway; that is the deal with a Wrangler and nobody has ever complained twice.",
                rules: ["Panels must be refitted before return", "No deep water crossings", "Sand is fine, salt water is not"],
                isInstantBook: false, deliveryFee: 45, paint: .sand, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 150, extraMileFee: 0.75, isNewListing: false,
                blockedDates: blocked([9, 10, 11, 25])
            ),
            Car(
                id: UUID(), make: "Mazda", model: "MX-5 Miata", year: 2023, trim: "Club",
                bodyType: .convertible, transmission: .manual, fuel: .gas, seats: 2, doors: 2, efficiency: 34,
                dailyPrice: 88, listPrice: nil, rating: 4.97, tripCount: 118, hostID: marcus.id,
                location: PickupLocation(name: "Cow Hollow", detail: "Union St", latitude: 37.7975, longitude: -122.4326),
                distanceMiles: 1.9,
                amenities: [.appleCarPlay, .bluetooth, .backupCamera, .usbCharger, .keylessEntry],
                blurb: "Manual. Roof down. Don't overthink it.",
                details: "A six-speed Club with the limited-slip differential and Bilstein dampers. This is the car I recommend to anyone who wants a good day rather than a fast one — it is only 181hp and that is entirely the point.\n\nYou must be able to drive a manual. I will ask, and I will check at handover. The boot takes one soft weekend bag, honestly.",
                rules: ["Manual transmission experience required", "Roof down at your own risk in fog", "No smoking"],
                isInstantBook: true, deliveryFee: 40, paint: .ember, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 150, extraMileFee: 0.60, isNewListing: false,
                blockedDates: blocked([13, 14, 27])
            ),
            Car(
                id: UUID(), make: "Rivian", model: "R1S", year: 2024, trim: "Adventure",
                bodyType: .suv, transmission: .automatic, fuel: .electric, seats: 7, doors: 4, efficiency: 316,
                dailyPrice: 214, listPrice: 249, rating: 5.0, tripCount: 12, hostID: sofia.id,
                location: PickupLocation(name: "Dogpatch", detail: "3rd St & 20th", latitude: 37.7605, longitude: -122.3885),
                distanceMiles: 3.1,
                amenities: [.bluetooth, .backupCamera, .heatedSeats, .ventilatedSeats, .allWheelDrive, .usbCharger, .gps, .keylessEntry, .blindSpot, .adaptiveCruise, .petFriendly, .skiRack],
                blurb: "Seven seats, 316 miles, quad motors.",
                details: "Brand new to the platform and it has been a hit. Quad-motor Adventure with the 21-inch road wheels fitted for range. Third row is genuinely usable for adults on shorter journeys.\n\nCamp mode, a built-in air compressor and a front boot big enough to be useful. I charge it to full and reset the trip computer before every handover.",
                rules: ["Return above 25% charge", "No smoking", "Off-road modes are fine, rock crawling is not"],
                isInstantBook: true, deliveryFee: 60, paint: .plum, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 200, extraMileFee: 0.95, isNewListing: true,
                blockedDates: blocked([17, 18])
            ),
            Car(
                id: UUID(), make: "Volkswagen", model: "Golf GTI", year: 2021, trim: "Autobahn",
                bodyType: .car, transmission: .manual, fuel: .gas, seats: 5, doors: 4, efficiency: 30,
                dailyPrice: 72, listPrice: nil, rating: 4.84, tripCount: 91, hostID: dilan.id,
                location: PickupLocation(name: "Bernal Heights", detail: "Cortland Ave", latitude: 37.7390, longitude: -122.4160),
                distanceMiles: 4.2,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .heatedSeats, .sunroof, .usbCharger],
                blurb: "The sensible car that isn't boring.",
                details: "Six-speed manual GTI in Autobahn trim, so it has the sunroof, the better stereo and adaptive dampers. Fast enough to be fun on Skyline, practical enough that you can fill it with luggage and four friends.\n\nIt lives on a hill in Bernal so you will get some hill-start practice. Manual experience needed.",
                rules: ["Manual transmission experience required", "Premium fuel preferred", "No smoking"],
                isInstantBook: true, deliveryFee: 30, paint: .ice, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 175, extraMileFee: 0.50, isNewListing: false,
                blockedDates: blocked([21, 22])
            ),
            Car(
                id: UUID(), make: "Mercedes-Benz", model: "Sprinter", year: 2020, trim: "2500 Crew",
                bodyType: .van, transmission: .automatic, fuel: .diesel, seats: 5, doors: 3, efficiency: 22,
                dailyPrice: 156, listPrice: nil, rating: 4.69, tripCount: 33, hostID: ray.id,
                location: PickupLocation(name: "Emeryville", detail: "Powell St", latitude: 37.8395, longitude: -122.2930),
                distanceMiles: 11.3,
                amenities: [.bluetooth, .backupCamera, .usbCharger, .toll, .gps],
                blurb: "High roof. You can stand up in it.",
                details: "A 144-inch wheelbase high-roof Sprinter, partially fitted out — insulated walls, a plywood floor and tie-down points, but no bed or kitchen. Bands book it for tours and people book it for moves.\n\nIt is 8ft 9in tall. Please check parking structures before you drive into one. That is the single most common problem guests have.",
                rules: ["Diesel only — check before fuelling", "Mind the 8ft 9in height", "No smoking", "Commercial use must be declared"],
                isInstantBook: false, deliveryFee: nil, paint: .pearl, photoCount: 5, minTripDays: 2,
                includedMilesPerDay: 150, extraMileFee: 0.80, isNewListing: false,
                blockedDates: blocked([2, 3, 4, 19, 20])
            ),

            // The signed-in user's own listings — these power the host side.
            Car(
                id: UUID(), make: "Subaru", model: "Outback", year: 2021, trim: "Onyx XT",
                bodyType: .suv, transmission: .automatic, fuel: .gas, seats: 5, doors: 4, efficiency: 26,
                dailyPrice: 84, listPrice: nil, rating: 4.88, tripCount: 41, hostID: meHostID,
                location: PickupLocation(name: "Mission District", detail: "Valencia St & 22nd", latitude: 37.7554, longitude: -122.4205),
                distanceMiles: 3.4,
                amenities: [.appleCarPlay, .androidAuto, .bluetooth, .backupCamera, .allWheelDrive, .heatedSeats, .skiRack, .petFriendly, .usbCharger],
                blurb: "Does everything, complains about nothing.",
                details: "Onyx XT with the turbo engine and the water-resistant seats, which have survived two dogs and a leaking cooler. Symmetrical AWD and enough ground clearance for a forest service road.\n\nParked on Valencia. I am flexible on pickup times — just message me the day before.",
                rules: ["No smoking", "Dogs welcome, please brush the seats after", "Return with the same fuel level"],
                isInstantBook: true, deliveryFee: 35, paint: .forest, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 200, extraMileFee: 0.55, isNewListing: false,
                blockedDates: blocked([8, 9, 26])
            ),
            Car(
                id: UUID(), make: "Mini", model: "Cooper S", year: 2019, trim: "Hardtop 2-Door",
                bodyType: .car, transmission: .manual, fuel: .gas, seats: 4, doors: 2, efficiency: 32,
                dailyPrice: 61, listPrice: nil, rating: 4.79, tripCount: 22, hostID: meHostID,
                location: PickupLocation(name: "Mission District", detail: "Folsom St & 20th", latitude: 37.7595, longitude: -122.4142),
                distanceMiles: 3.6,
                amenities: [.appleCarPlay, .bluetooth, .backupCamera, .sunroof, .usbCharger, .keylessEntry],
                blurb: "Small enough to park anywhere in this city.",
                details: "Six-speed manual Cooper S. The single best car for San Francisco parking I have owned — it fits in gaps nothing else will. Sport mode makes a slightly silly noise and I have never got tired of it.\n\nBack seats are for bags or short journeys, not adults.",
                rules: ["Manual transmission experience required", "Premium fuel", "No smoking"],
                isInstantBook: false, deliveryFee: nil, paint: .copper, photoCount: 5, minTripDays: 1,
                includedMilesPerDay: 150, extraMileFee: 0.50, isNewListing: false,
                blockedDates: blocked([15, 16, 17])
            )
        ]

        // MARK: Reviews

        let reviewSeeds: [(Int, String, Double, Int, String, String?)] = [
            (0, "Jordan Bell", 5.0, -4, "Exactly as described and Marcus is a genuinely great host. He met me early, walked me through every control, and the car was immaculate. Took it down to Pescadero and back — unforgettable.", "Thanks Jordan! Come back any time."),
            (0, "Aisha Mensah", 5.0, -12, "Second time booking this car. Nothing to fault. Handover took five minutes because Marcus is organised.", nil),
            (0, "Tom Reilly", 4.0, -25, "Wonderful car, though I underestimated how low it is and scraped a driveway on day one. Entirely my fault — Marcus was very fair about it.", "Appreciate you flagging it straight away, Tom. No harm done."),
            (1, "Nina Petrova", 5.0, -2, "First time driving an EV and Sofia made it completely painless. She sent me a charging guide the night before and the car was at 100%.", "Glad it clicked! You are an EV person now."),
            (1, "Marcus Hall", 5.0, -9, "Clean, fast, easy. Charged it once in four days. Would book again without thinking.", nil),
            (1, "Grace Kim", 4.0, -20, "Great car. Pickup spot has awkward street parking so give yourself ten extra minutes.", nil),
            (2, "Danielle Cruz", 5.0, -6, "Took it to Tahoe in a storm. Priya included chains and actually showed me how to fit them in her driveway, which I ended up needing at 8,000ft. Above and beyond.", "That storm was something else. Glad you got up safely!"),
            (2, "Owen Fitzgerald", 5.0, -15, "Perfect ski trip vehicle. Roof box swallowed four sets of skis.", nil),
            (2, "Ravi Shah", 4.0, -31, "Does what it says. Thirsty on the freeway, but that is a 4Runner.", nil),
            (3, "Chloe Barrett", 5.0, -3, "Cheapest booking I have made and one of the smoothest. Spotless inside.", nil),
            (3, "Peter Novak", 4.0, -11, "Good value. Dilan can only do early or late pickups, which he says upfront — just plan for it.", "Thanks Peter — weekday evenings are easiest for me."),
            (3, "Layla Haddad", 5.0, -22, "Drove it to LA and back. 38 MPG and zero drama.", nil),
            (4, "Sam Whitaker", 5.0, -5, "Moved a two-bedroom apartment in two trips. Ray is easy to deal with and the tonneau cover kept everything dry.", nil),
            (4, "Erin Doyle", 4.0, -17, "Truck did the job. Bed is scuffed but he mentions that in the listing, so no surprises.", nil),
            (5, "Felix Andersen", 5.0, -7, "Ridiculous car in the best way. The walkthrough was genuinely useful — there are a lot of settings.", "Enjoy is the whole point. Thanks Felix!"),
            (5, "Bianca Rossi", 5.0, -19, "Immaculate and stupidly fast. Comfort mode really is comfortable.", nil),
            (6, "Hana Suzuki", 5.0, -8, "Two kids, two car seats, already fitted when we arrived. That alone was worth booking.", "Any time! Glad the seats worked out."),
            (6, "Greg Mullins", 4.0, -26, "Loads of space. Electric range is short but it is quiet around town.", nil),
            (7, "Kofi Baptiste", 5.0, -10, "Took the roof off at Stinson and drove back at sunset. Best day of the trip.", nil),
            (7, "Marta Diaz", 4.0, -24, "Loud on the highway, brilliant everywhere else. Knew that going in.", nil),
            (8, "Lucas Moreau", 5.0, -1, "If you can drive a manual, book this. Marcus was right — you do not need more than 181hp to have a great day.", "Exactly the review I hoped for."),
            (8, "Zoe Clarke", 5.0, -13, "Perfect little car for the coast. One bag fits, so pack light.", nil),
            (9, "Ibrahim Al-Rashid", 5.0, -2, "New listing but Sofia is an experienced host and it shows. Third row fit two teenagers fine.", nil),
            (10, "Nadia Kowalski", 5.0, -6, "Manual GTI for $72 a day is a bargain. Hill starts in Bernal will keep you sharp.", nil),
            (11, "Craig Stephens", 4.0, -14, "Booked it for a band tour. Fits everything. Heed the height warning — I nearly forgot in Sacramento.", "Please do! That one keeps me up at night."),
            (12, "Rosa Delgado", 5.0, -9, "Alex was flexible on pickup time when my flight moved. Car is exactly what an Outback should be.", nil),
            (13, "Yuki Tanaka", 5.0, -12, "Parked it in spaces I would not have attempted in anything else.", nil)
        ]

        let reviews: [Review] = reviewSeeds.enumerated().compactMap { index, seed in
            let (carIndex, author, rating, dayOffset, text, reply) = seed
            guard carIndex < cars.count else { return nil }
            return Review(
                id: UUID(),
                carID: cars[carIndex].id,
                authorName: author,
                date: day(dayOffset),
                rating: rating,
                text: text,
                hostReply: reply,
                accentSeed: index
            )
        }

        // MARK: Profile & payment

        let profile = UserProfile(
            name: "Alex Mercer",
            email: "alex.mercer@example.com",
            joinedYear: 2022,
            city: "San Francisco, CA",
            tripCount: 14,
            rating: 4.9,
            isLicenseVerified: false,
            isPhoneVerified: true,
            isEmailVerified: true,
            isHost: true
        )

        let paymentMethods = [
            PaymentMethod(id: UUID(), brand: "Visa", last4: "4242", expiry: "08/28", isDefault: true),
            PaymentMethod(id: UUID(), brand: "Apple Pay", last4: "9931", expiry: "—", isDefault: false)
        ]

        // MARK: Trips
        //
        // A deliberate spread: one starting soon, one awaiting host approval, one
        // already running, two finished, plus host-side requests to action.

        func quoteFor(_ car: Car, days: Int, protection: ProtectionPlan, extrasCost: Double = 0, delivery: Double = 0) -> PriceQuote {
            let subtotal = car.dailyPrice * Double(days)
            var discount: Double = 0
            var label: String?
            if days >= 7 { discount = subtotal * 0.15; label = "Weekly discount (15%)" }
            else if days >= 3 { discount = subtotal * 0.07; label = "3+ day discount (7%)" }
            let discounted = subtotal - discount
            let protectionCost = (discounted * protection.rate).rounded()
            let tripFee = (discounted * 0.10).rounded()
            let taxes = ((discounted + protectionCost + extrasCost + delivery + tripFee) * 0.0875).rounded()
            return PriceQuote(
                days: days, nightlyRate: car.dailyPrice, subtotal: subtotal,
                discountLabel: label, discountAmount: discount.rounded(),
                protectionCost: protectionCost, extrasCost: extrasCost,
                deliveryCost: delivery, tripFee: tripFee, taxes: taxes
            )
        }

        var trips: [Trip] = []

        // Guest: starts in three days, confirmed.
        trips.append(Trip(
            id: UUID(), carID: cars[1].id, startDate: day(3, hour: 9), endDate: day(6, hour: 9),
            handoff: .delivery, handoffAddress: "1 Ferry Building, San Francisco",
            protection: .standard, extras: [ExtraSelection(extraID: "unlimited-miles", quantity: 1)],
            quote: quoteFor(cars[1], days: 3, protection: .standard, extrasCost: 72, delivery: 35),
            status: .upcoming, bookedAt: day(-5), guestName: profile.name,
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: false
        ))

        // Guest: awaiting host approval.
        trips.append(Trip(
            id: UUID(), carID: cars[2].id, startDate: day(12, hour: 8), endDate: day(15, hour: 18),
            handoff: .hostLocation, handoffAddress: cars[2].location.name,
            protection: .premium, extras: [],
            quote: quoteFor(cars[2], days: 3, protection: .premium),
            status: .requested, bookedAt: day(-1), guestName: profile.name,
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: false
        ))

        // Guest: in progress right now.
        trips.append(Trip(
            id: UUID(), carID: cars[8].id, startDate: day(-1, hour: 11), endDate: day(2, hour: 11),
            handoff: .hostLocation, handoffAddress: cars[8].location.name,
            protection: .standard, extras: [ExtraSelection(extraID: "prepaid-fuel", quantity: 1)],
            quote: quoteFor(cars[8], days: 3, protection: .standard, extrasCost: 75),
            status: .active, bookedAt: day(-9), guestName: profile.name,
            isCheckedIn: true, checkInPhotoCount: 6, guestReviewLeft: false, isHostSide: false
        ))

        // Guest: history.
        trips.append(Trip(
            id: UUID(), carID: cars[3].id, startDate: day(-24, hour: 8), endDate: day(-21, hour: 8),
            handoff: .hostLocation, handoffAddress: cars[3].location.name,
            protection: .minimum, extras: [],
            quote: quoteFor(cars[3], days: 3, protection: .minimum),
            status: .completed, bookedAt: day(-30), guestName: profile.name,
            isCheckedIn: true, checkInPhotoCount: 4, guestReviewLeft: true, isHostSide: false
        ))

        trips.append(Trip(
            id: UUID(), carID: cars[6].id, startDate: day(-48, hour: 10), endDate: day(-41, hour: 10),
            handoff: .delivery, handoffAddress: "Oakland Airport, Terminal 1",
            protection: .standard, extras: [ExtraSelection(extraID: "child-seat", quantity: 2)],
            quote: quoteFor(cars[6], days: 7, protection: .standard, extrasCost: 168, delivery: 40),
            status: .completed, bookedAt: day(-60), guestName: profile.name,
            isCheckedIn: true, checkInPhotoCount: 8, guestReviewLeft: false, isHostSide: false
        ))

        trips.append(Trip(
            id: UUID(), carID: cars[5].id, startDate: day(-15, hour: 12), endDate: day(-13, hour: 12),
            handoff: .hostLocation, handoffAddress: cars[5].location.name,
            protection: .premium, extras: [],
            quote: quoteFor(cars[5], days: 2, protection: .premium),
            status: .cancelled, bookedAt: day(-20), guestName: profile.name,
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: false
        ))

        // Host side: two requests waiting, one booked, two completed for earnings.
        let outback = cars[12]
        let mini = cars[13]

        trips.append(Trip(
            id: UUID(), carID: outback.id, startDate: day(4, hour: 9), endDate: day(8, hour: 17),
            handoff: .hostLocation, handoffAddress: outback.location.name,
            protection: .standard, extras: [ExtraSelection(extraID: "toll-pass", quantity: 1)],
            quote: quoteFor(outback, days: 4, protection: .standard, extrasCost: 36),
            status: .requested, bookedAt: day(0), guestName: "Meera Kapoor",
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: true
        ))

        trips.append(Trip(
            id: UUID(), carID: mini.id, startDate: day(2, hour: 18), endDate: day(4, hour: 18),
            handoff: .hostLocation, handoffAddress: mini.location.name,
            protection: .minimum, extras: [],
            quote: quoteFor(mini, days: 2, protection: .minimum),
            status: .requested, bookedAt: day(0), guestName: "Theo Lindgren",
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: true
        ))

        trips.append(Trip(
            id: UUID(), carID: outback.id, startDate: day(1, hour: 7), endDate: day(3, hour: 19),
            handoff: .delivery, handoffAddress: "SFO Terminal 2, Arrivals",
            protection: .premium, extras: [ExtraSelection(extraID: "extra-driver", quantity: 1)],
            quote: quoteFor(outback, days: 2, protection: .premium, extrasCost: 20, delivery: 35),
            status: .upcoming, bookedAt: day(-3), guestName: "Callum Pierce",
            isCheckedIn: false, checkInPhotoCount: 0, guestReviewLeft: false, isHostSide: true
        ))

        trips.append(Trip(
            id: UUID(), carID: mini.id, startDate: day(-11, hour: 10), endDate: day(-8, hour: 10),
            handoff: .hostLocation, handoffAddress: mini.location.name,
            protection: .standard, extras: [],
            quote: quoteFor(mini, days: 3, protection: .standard),
            status: .completed, bookedAt: day(-18), guestName: "Yuki Tanaka",
            isCheckedIn: true, checkInPhotoCount: 5, guestReviewLeft: true, isHostSide: true
        ))

        trips.append(Trip(
            id: UUID(), carID: outback.id, startDate: day(-20, hour: 9), endDate: day(-14, hour: 9),
            handoff: .hostLocation, handoffAddress: outback.location.name,
            protection: .standard, extras: [ExtraSelection(extraID: "prepaid-fuel", quantity: 1)],
            quote: quoteFor(outback, days: 6, protection: .standard, extrasCost: 75),
            status: .completed, bookedAt: day(-28), guestName: "Rosa Delgado",
            isCheckedIn: true, checkInPhotoCount: 7, guestReviewLeft: true, isHostSide: true
        ))

        // MARK: Conversations

        let conversations: [Conversation] = [
            Conversation(
                id: UUID(), participantName: sofia.name, participantSeed: sofia.accentSeed, carID: cars[1].id,
                messages: [
                    Message(id: UUID(), text: "Booking confirmed for \(DateText.range(day(3), day(6))).", sentAt: day(-5, hour: 14), isFromMe: false, isSystem: true),
                    Message(id: UUID(), text: "Hi Alex! I'll have it at the Ferry Building at 9am, charged to 100%. Any questions before then?", sentAt: day(-5, hour: 14), isFromMe: false, isSystem: false),
                    Message(id: UUID(), text: "Perfect. First time driving an EV — is charging complicated?", sentAt: day(-4, hour: 9), isFromMe: true, isSystem: false),
                    Message(id: UUID(), text: "Not at all. The car routes you to Superchargers automatically and the plug does the rest. I'll walk you through it at handover, takes two minutes.", sentAt: day(-4, hour: 9), isFromMe: false, isSystem: false),
                    Message(id: UUID(), text: "I'll send a charging cheat sheet the night before too.", sentAt: day(-1, hour: 20), isFromMe: false, isSystem: false)
                ],
                unreadCount: 1, isHostThread: false
            ),
            Conversation(
                id: UUID(), participantName: priya.name, participantSeed: priya.accentSeed, carID: cars[2].id,
                messages: [
                    Message(id: UUID(), text: "Alex Mercer requested your 4Runner for \(DateText.range(day(12), day(15))).", sentAt: day(-1, hour: 11), isFromMe: false, isSystem: true),
                    Message(id: UUID(), text: "Hi Priya — hoping to take this to Tahoe. Are chains included at that time of year?", sentAt: day(-1, hour: 11), isFromMe: true, isSystem: false),
                    Message(id: UUID(), text: "They are, and I'll show you how to fit them. Let me check my calendar tonight and I'll confirm the booking.", sentAt: day(-1, hour: 13), isFromMe: false, isSystem: false)
                ],
                unreadCount: 1, isHostThread: false
            ),
            Conversation(
                id: UUID(), participantName: marcus.name, participantSeed: marcus.accentSeed, carID: cars[8].id,
                messages: [
                    Message(id: UUID(), text: "Booking confirmed for \(DateText.range(day(-1), day(2))).", sentAt: day(-9, hour: 16), isFromMe: false, isSystem: true),
                    Message(id: UUID(), text: "You're all checked in — enjoy it. Roof latch is stiff, push down firmly before twisting.", sentAt: day(-1, hour: 11), isFromMe: false, isSystem: false),
                    Message(id: UUID(), text: "Got it, thanks! Roof is down and we're heading to Stinson.", sentAt: day(-1, hour: 12), isFromMe: true, isSystem: false),
                    Message(id: UUID(), text: "Perfect day for it. Text me if anything comes up.", sentAt: day(-1, hour: 12), isFromMe: false, isSystem: false)
                ],
                unreadCount: 0, isHostThread: false
            ),
            Conversation(
                id: UUID(), participantName: "Meera Kapoor", participantSeed: 7, carID: outback.id,
                messages: [
                    Message(id: UUID(), text: "Meera Kapoor requested your Outback for \(DateText.range(day(4), day(8))).", sentAt: day(0, hour: 8), isFromMe: false, isSystem: true),
                    Message(id: UUID(), text: "Hi! We're driving up to Mendocino with a dog — is that alright? He's well behaved and I'll bring a blanket.", sentAt: day(0, hour: 8), isFromMe: false, isSystem: false)
                ],
                unreadCount: 2, isHostThread: true
            ),
            Conversation(
                id: UUID(), participantName: "Callum Pierce", participantSeed: 8, carID: outback.id,
                messages: [
                    Message(id: UUID(), text: "Booking confirmed for \(DateText.range(day(1), day(3))).", sentAt: day(-3, hour: 15), isFromMe: false, isSystem: true),
                    Message(id: UUID(), text: "Landing at SFO T2 at 7:15am — will you be at arrivals or short-stay parking?", sentAt: day(-1, hour: 18), isFromMe: false, isSystem: false)
                ],
                unreadCount: 1, isHostThread: true
            )
        ]

        return SeedBundle(
            cars: cars,
            hosts: hosts,
            reviews: reviews,
            profile: profile,
            paymentMethods: paymentMethods,
            trips: trips,
            conversations: conversations
        )
    }

    /// Ratings breakdown shown on listing pages. Derived from the car's overall score
    /// so a 4.6 car does not show five perfect sub-scores.
    static func breakdown(for car: Car) -> RatingBreakdown {
        let base = car.rating
        func jitter(_ offset: Double) -> Double {
            min(5, max(3.5, base + offset))
        }
        return RatingBreakdown(
            cleanliness: jitter(0.03),
            maintenance: jitter(-0.02),
            communication: jitter(0.04),
            convenience: jitter(-0.06),
            accuracy: jitter(0.01)
        )
    }
}
