import SwiftUI
import UIKit

// MARK: - Palette
//
// One source of truth for colour. Every value is defined as a dynamic UIColor so
// light/dark mode is handled by the system rather than by branching in views.
//
// Direction: warm off-white paper, near-black ink, deep emerald accent. Deliberately
// not the purple of the app this prototype is modelled on — no branding yet.

enum Palette {

    // Backgrounds
    static let canvas = dynamic(light: 0xFBFAF8, dark: 0x0B0C0E)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x16181C)
    static let surfaceSunken = dynamic(light: 0xF2F0EC, dark: 0x1E2126)
    static let surfaceRaised = dynamic(light: 0xFFFFFF, dark: 0x22262C)

    // Ink
    static let ink = dynamic(light: 0x14161A, dark: 0xF6F5F3)
    static let inkSecondary = dynamic(light: 0x5C6169, dark: 0xA2A8B2)
    static let inkTertiary = dynamic(light: 0x8B9199, dark: 0x767D87)
    static let inkInverted = dynamic(light: 0xFFFFFF, dark: 0x0B0C0E)

    // Accent
    static let accent = dynamic(light: 0x14624F, dark: 0x2E9373)
    static let accentSunken = dynamic(light: 0x0E4D3E, dark: 0x246E58)
    static let accentWash = dynamic(light: 0xE8F1ED, dark: 0x14302A)

    // Semantic
    static let star = dynamic(light: 0xB9821F, dark: 0xE0A94B)
    static let danger = dynamic(light: 0xB3261E, dark: 0xE5766D)
    static let success = dynamic(light: 0x1D6B47, dark: 0x4FB489)
    static let info = dynamic(light: 0x1F4E79, dark: 0x6BA8DE)

    // Lines & scrims
    static let hairline = Color.primary.opacity(0.09)
    static let hairlineStrong = Color.primary.opacity(0.16)
    static let scrim = Color.black.opacity(0.42)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    fileprivate convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Typography
//
// SF for everything functional; New York (design: .serif) for display headings only.
// The serif is what stops this reading like a default template — it appears at three
// sizes and nowhere else.

enum Typo {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static let hero = Font.system(size: 40, weight: .semibold, design: .serif)
    static let title = Font.system(size: 26, weight: .semibold, design: .serif)
    static let sectionTitle = Font.system(size: 19, weight: .semibold, design: .serif)

    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .medium)
    static let bodySemibold = Font.system(size: 15, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
    static let captionMedium = Font.system(size: 13, weight: .medium)
    static let micro = Font.system(size: 11, weight: .medium)

    /// Tabular figures so prices and totals never jitter as they change.
    static func numeric(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }

    /// Wide-tracked all-caps label used for eyebrow text above sections.
    static let eyebrow = Font.system(size: 11, weight: .semibold)
}

// MARK: - Layout scale

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 44

    /// Horizontal page gutter. Every screen uses this, nothing else.
    static let gutter: CGFloat = 20
}

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Motion
//
// Durations and curves follow one rule: entrances are fast and ease-out, exits are
// faster still, and nothing in the UI runs past 300ms. Custom curves because the
// stock ones are too limp to read as intentional.

enum Motion {
    /// Strong ease-out. Default for anything appearing.
    static let enter = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.26)
    /// Exits are quicker than entrances — the system should get out of the way.
    static let exit = Animation.timingCurve(0.4, 0, 1, 1, duration: 0.16)
    /// On-screen movement / morphing.
    static let move = Animation.timingCurve(0.77, 0, 0.175, 1, duration: 0.28)
    /// Small state flips: toggles, chips, selection.
    static let snap = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.18)
    /// Press feedback. A spring so an interrupted press keeps its velocity.
    static let press = Animation.spring(duration: 0.22, bounce: 0.18)
    /// iOS drawer curve, for full-height sheets and page pushes.
    static let drawer = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.42)
    /// Content that arrives from the network (faked here). Slightly softer.
    static let content = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.34)

    /// Stagger step for lists. Short — long ladders make a screen feel slow.
    static func stagger(_ index: Int, step: Double = 0.035, cap: Int = 8) -> Double {
        Double(min(index, cap)) * step
    }
}

// MARK: - Elevation

struct Elevation {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double

    static let none = Elevation(radius: 0, y: 0, opacity: 0)
    static let low = Elevation(radius: 10, y: 3, opacity: 0.06)
    static let mid = Elevation(radius: 20, y: 8, opacity: 0.09)
    static let high = Elevation(radius: 34, y: 16, opacity: 0.14)
}

extension View {
    func elevation(_ level: Elevation) -> some View {
        shadow(color: .black.opacity(level.opacity), radius: level.radius, x: 0, y: level.y)
    }
}
