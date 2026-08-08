# Carshare — peer-to-peer car rental prototype

A fully interactive SwiftUI prototype of a private car-rental marketplace, in the mould of
Turo. iOS only, no branding, no backend — every screen is driven by an in-memory store, so
booking a car, approving a request or publishing a listing genuinely changes the app's state
for the rest of the session.

- **Platform:** iOS 17.0+, iPhone, portrait
- **Stack:** SwiftUI + Observation (`@Observable`), MapKit. No third-party dependencies.
- **Bundle ID:** `com.prototype.carshare`

---

## How to actually run it

Apple's toolchain is macOS-only. That is a hard constraint — Xcode, `xcodebuild`, and the
iOS Simulator do not exist for Windows or Linux, and no emulator legitimately substitutes
for them. Pick whichever of these fits what you have.

### 1. You have a Mac → just open it

```bash
open Carshare.xcodeproj
```

Press **⌘R**. The project uses Xcode 16's synchronised file groups, so every `.swift` file
under `Carshare/` is picked up automatically — there is no file list to maintain.

In **Claude Code Desktop on macOS**, the iOS Simulator pane opens by itself when Claude
builds and launches the app. It needs Xcode 26.x (the pane does not yet support Xcode 27)
and is unavailable on Windows, since the simulator only runs on macOS.

### 2. No Mac → free CI build + screenshots, then a browser iPhone

This is the route to use from Windows. Cost: nothing.

1. Push this folder to a GitHub repo.
2. `.github/workflows/ios.yml` runs on a free **macOS runner**: it compiles the app, boots a
   real iOS Simulator, and screenshots all ten screens in light and dark mode.
3. Open the run in the **Actions** tab and download two artifacts:
   - `screenshots` — PNGs of every screen
   - `Carshare-sim-app` — `Carshare-sim.zip`, the simulator build

To go from screenshots to something you can *tap*:

4. Create a free account at [appetize.io](https://appetize.io) and upload `Carshare-sim.zip`.
5. You get a URL hosting a real iPhone running the app in a browser. Open it on your PC, or
   in Safari on your iPhone, and use the app properly. The free tier is around 100 minutes a
   month.

Optional: put your Appetize API token in a repository secret named `APPETIZE_TOKEN` and the
workflow uploads each build automatically, printing the play URL in the run summary.

### 3. Interactive Xcode without owning a Mac

Rent one by the hour and remote in:

- **Scaleway** Mac mini — around €0.11/hour
- **MacinCloud** — pay-as-you-go, around $1/hour
- **AWS EC2 `mac2`** instances — 24-hour minimum allocation

You get a macOS desktop, install Xcode, and run the simulator normally.

### 4. Installing on your physical iPhone

This needs code signing, which needs macOS or a signing service, plus an **Apple Developer
account at $99/year** for TestFlight or ad-hoc distribution. There is no way around signing
from Windows. If you only want to *see and use* the app, option 2 is far cheaper.

### What will not work

- **Expo Go** — it runs a JavaScript bundle inside a pre-compiled React Native shell. Swift
  must be compiled into a binary, and you cannot add compiled Swift to Expo Go's binary.
  Expo Go requires React Native, full stop.
- **Swift Playgrounds** — can run SwiftUI, but the app is iPad/Mac only. Not on iPhone.

---

## Jumping straight to a screen

Any screen can be opened directly with a launch argument, which is how CI screenshots each
one without simulating taps:

```bash
xcrun simctl launch booted com.prototype.carshare -startScreen trips
```

Valid values: `welcome`, `explore`, `saved`, `trips`, `inbox`, `profile`, `host`,
`hostListings`, `hostRequests`, `hostEarnings`. In Xcode, set the same thing under
**Product → Scheme → Edit Scheme → Arguments**.

---

## What's built

### Guest side

| Screen | What works |
| --- | --- |
| Welcome | Rotating hero, routes into guest or host mode |
| Explore | Collapsing search header, live filter chips, result list, empty and loading states |
| Search | Place search with recents and suggestions, date/time range, quick durations, discount preview |
| Filters | Two-thumb price slider, vehicle type, seats, rating, transmission, fuel, 20 features, sort — with a live "show N cars" count on an uncommitted draft |
| Map | MapKit with price pins, two-way sync between pin selection and the card deck |
| Listing detail | Parallax photo carousel, specs, ratings breakdown, features, availability calendar, price breakdown, host card, reviews, location map, rules, cancellation policy |
| Reviews | Star-distribution bars, filter by rating, host replies |
| Host profile | Verification, response stats, their other cars, all their reviews |
| Booking | Five steps — dates (validates minimum trip length and blocked dates), pickup vs delivery, three protection tiers, six extras with quantities, review and pay with a licence-verification gate |
| Confirmation | Differs for instant-book vs request, with next steps |
| Trips | Booked and history, featured next-trip card with countdown |
| Trip detail | Live status, progress timeline, handoff map, receipt, and stage-appropriate actions |
| Check-in | Six-angle photo capture, fuel/charge slider, odometer, damage notes |
| Extend / review / cancel | All wired, all mutate real state |
| Inbox | Threads with unread badges, chat with quick replies and a simulated reply |
| Saved | Favourites with swipe-to-remove context menu |
| Profile | Verification progress, payment methods, settings, host switch |

### Host side

A separate tab set, because hosting is a different job from browsing.

| Screen | What works |
| --- | --- |
| Dashboard | Earnings tiles, pending requests, upcoming trips, vehicle carousel |
| Requests | Approve/decline, which moves the trip and updates earnings |
| Vehicles | Per-listing stats, editor for price, minimum trip, mileage, instant book, delivery |
| Add a car | Six steps — vehicle, spec, photos, features, price, publish — with a live earnings estimate and a preview of the guest-facing card. Publishing inserts a real listing. |
| Earnings | Interactive 12-month bar chart, payout history, performance scores |

### One pricing path

Every screen that shows money reads a `PriceQuote` from `AppState.quote(...)` — length
discounts, protection rate, extras, delivery, trip fee, tax, and the host's 75% cut. The
detail page, checkout, receipt and host payout cannot disagree, because there is only one
calculation.

---

## Design notes

No stock photography, so vehicle imagery is **generated**: a studio gradient per paint
colour, one light source that moves between frames, an SF Symbol silhouette and a floor
reflection. Five framings give a listing a believable five-photo gallery, and a car keeps
its colour across the list, the detail page and the trip card.

Type pairs SF for the interface with **New York** (`design: .serif`) for display headings
only, at three sizes and nowhere else — the thing that stops it reading as a default
template.

Motion follows a few rules: entrances ease out over ~260ms, exits are faster at ~160ms,
nothing in the UI runs past 300ms, pressable surfaces scale to 0.97 on a spring, nothing
animates in from `scale(0)`, and list entrances stagger by 35ms with an 8-item cap. Reduced
Motion drops movement but keeps fades.

Colour is defined once in `Palette` as dynamic `UIColor`s, so dark mode is handled by the
system rather than by branching in views.

---

## Layout

```
Carshare/
  CarshareApp.swift          @main
  Design/
    Theme.swift              colour, type, spacing, motion, elevation
    Components.swift         buttons, chips, cards, ratings, wrap layout, toast
    CarArtwork.swift         procedural vehicle imagery, carousel, map pins
  Models/
    Models.swift             domain types
    SampleData.swift         14 cars, 6 hosts, 27 reviews, 11 trips, 5 threads
  State/
    AppState.swift           single @Observable store, pricing, all mutations
  Utilities/
    Formatting.swift         money, dates, symbol fallbacks, avatars, entrances
    LaunchConfig.swift       -startScreen launch argument
  Features/
    Root/ Explore/ Listing/ Booking/ Trips/ Inbox/ Favourites/ Profile/ Host/
```

Newer vehicle SF Symbols are resolved through `Symbols.resolve(_:fallback:)`, which falls
back rather than rendering a blank glyph on an older runtime.

## Known limits

It is a prototype. Nothing persists across launches, there is no network layer or auth,
photo capture is simulated by tapping placeholder tiles, and blocked dates are displayed but
not editable from the host listing editor.
