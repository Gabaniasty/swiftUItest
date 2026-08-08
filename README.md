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

### 2. No Mac → Codemagic build, then a browser iPhone (verified working)

This is the route that was actually used to get the app running from a Windows PC. Cost:
nothing.

1. Sign in at [codemagic.io](https://codemagic.io) with GitHub and add this repo.
2. Codemagic's scanner reports **"doesn't seem to contain a mobile application"** — its repo
   parser can't read Xcode 16's `objectVersion = 77` project format. Click **Set type
   manually → iOS**. Leave project path `.`. The build itself is unaffected.
3. Pick the **ios-simulator** workflow from `codemagic.yaml` and start a build. It compiles,
   checks the binary is universal, screenshots every screen, and zips the app.
4. From **Artifacts**, download **`Carshare-sim.zip`** — a zip with `Carshare.app` at its
   root. Screenshots come down as separate PNGs.
5. Upload that zip to a free [appetize.io](https://appetize.io) account. You get a URL
   hosting a real iPhone in a browser — open it on the PC or in iPhone Safari and use the app
   properly. Free tier is roughly 100 minutes a month.

Optional: set `APPETIZE_TOKEN` as a Codemagic environment variable and the build uploads
itself, printing the URL in the log.

**The one non-obvious requirement:** the build must produce a **universal** simulator binary
(`ARCHS="x86_64 arm64" ONLY_ACTIVE_ARCH=NO`). Codemagic builds on Apple Silicon, where a
default Debug build is arm64-only — and an arm64-only binary on an x86_64 simulator host
doesn't error, it just spins on "loading" forever. `codemagic.yaml` handles this and asserts
the `x86_64` slice exists after building.

Appetize only offering iOS 26 is fine; the deployment target is 17.0.

### 2b. GitHub Actions

`.github/workflows/ios.yml` does the same job and is correct, but Actions is blocked on the
account this was set up under — runs create jobs and no runner is ever assigned, including
for a trivial ubuntu job on a public repo. That points at billing or account verification.
If Actions works on your account, this workflow needs no changes; set `APPETIZE_TOKEN` as a
repository secret to get automatic uploads.

Note if you adapt it: the `secrets` context is **not** allowed in a step-level `if:` — it
makes the whole workflow fail to parse. Surface the token as a job-level `env` var and test
`env.APPETIZE_TOKEN != ''` instead.

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
