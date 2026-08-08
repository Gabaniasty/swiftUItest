# Agent notes

Context for anyone — human or agent — picking this repo up. Read this before changing code.

## What this is

An interactive SwiftUI prototype of a peer-to-peer car rental marketplace (Turo-like), iOS
only, deliberately unbranded. No backend, no persistence, no third-party dependencies.
Everything is driven by one in-memory `@Observable` store, so actions genuinely mutate state
for the rest of the session.

- iOS 17.0+, iPhone, portrait only
- SwiftUI + Observation + MapKit
- Bundle ID `com.prototype.carshare`
- ~10,700 lines across 30 Swift files

## Building

Requires macOS with **Xcode 16 or newer**. The project uses `objectVersion = 77` with
`PBXFileSystemSynchronizedRootGroup`, so every `.swift` file under `Carshare/` is compiled
automatically — **do not add file references when creating files**, just create them.

```bash
xcodebuild build -project Carshare.xcodeproj -scheme Carshare \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  ARCHS="x86_64 arm64" ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO
```

`ARCHS`/`ONLY_ACTIVE_ARCH` matter: on Apple Silicon a default Debug build yields an
arm64-only simulator binary, which cannot run on x86_64 simulator hosts. It hangs on load
rather than erroring, which is painful to diagnose. Keep the universal build.

Verify the slices before shipping a build anywhere:

```bash
lipo -archs build/Build/Products/Debug-iphonesimulator/Carshare.app/Carshare
```

## Jumping to a screen

Any screen opens directly via a launch argument, read in `Utilities/LaunchConfig.swift`:

```bash
xcrun simctl launch booted com.prototype.carshare -startScreen hostEarnings
```

Values: `welcome`, `explore`, `saved`, `trips`, `inbox`, `profile`, `host`, `hostListings`,
`hostRequests`, `hostEarnings`. CI uses this to screenshot every screen without driving taps.

## CI

`codemagic.yaml` is the working route (free tier, real Mac). When adding the app in
Codemagic, its repo scanner **cannot parse `objectVersion = 77`** and reports "doesn't seem
to contain a mobile application" — click *Set type manually* → iOS. The build is unaffected.

`.github/workflows/ios.yml` is correct but Actions is blocked on this account (no runner is
ever assigned, even for a trivial ubuntu job on a public repo).

## Conventions that must hold

**Design tokens only.** Colour, type, spacing, radii, motion and elevation come from
`Design/Theme.swift`. No literal hex values, font sizes or magic padding in feature views.
`Palette` values are dynamic `UIColor`s, so never branch on colour scheme in a view.

**One pricing path.** Every screen showing money reads a `PriceQuote` from
`AppState.quote(...)`. Do not compute prices in a view — the detail page, checkout, receipt
and host payout must never disagree.

**Motion rules.** Entrances ease out ~260ms, exits are faster ~160ms, nothing in the UI
exceeds 300ms. Pressable surfaces use `PressableStyle` (0.97 spring). Never animate in from
`scale(0)`. List entrances stagger via `.appear(index)` at 35ms, capped at 8. Honour
`accessibilityReduceMotion` by dropping movement while keeping fades.

**Typography.** New York serif (`Typo.display/title/sectionTitle`) for display headings
*only*; SF everywhere else. Prices and counts use `Typo.numeric` for tabular figures so
values don't jitter when they change.

**SF Symbols.** Newer vehicle symbols go through `Symbols.resolve(_:fallback:)`, which falls
back instead of rendering a blank glyph.

**Vehicle imagery is procedural.** `Design/CarArtwork.swift` generates it from a `CarPaint`
plus an `ArtVariant` framing. There is no bundled photography; don't add placeholder greys.

**Purity in state.** `AppState.results(for:)` is deliberately pure so the filter sheet can
preview a match count for an uncommitted draft. Never mutate observable state during view
body evaluation — it causes invalidation loops.

**Card tinting.** `Card` surfaces are opaque. Pass `fill:` to tint one; layering a
`.background` behind it does nothing.

## Layout

```
Carshare/
  CarshareApp.swift          @main
  Design/                    Theme, Components, CarArtwork
  Models/                    Models, SampleData
  State/AppState.swift       single store, pricing, all mutations
  Utilities/                 Formatting, LaunchConfig
  Features/                  Root, Explore, Listing, Booking, Trips, Inbox, Favourites,
                             Profile, Host
```

## Known limits

Nothing persists across launches. No network or auth layer. Photo capture is simulated by
tapping placeholder tiles. Blocked dates render in the host listing editor but aren't
editable there.
