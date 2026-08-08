import Foundation
import SwiftUI
import UIKit

// MARK: - Money

enum Money {
    private static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Full precision — totals, line items.
    static func full(_ value: Double) -> String {
        currency.string(from: value as NSNumber) ?? "$0.00"
    }

    /// Rounded — daily rates, badges, anywhere cents are noise.
    static func short(_ value: Double) -> String {
        whole.string(from: value.rounded() as NSNumber) ?? "$0"
    }

    /// Compact form for earnings tiles: $1.2k
    static func compact(_ value: Double) -> String {
        if value >= 1000 {
            return "$" + String(format: "%.1fk", value / 1000)
        }
        return short(value)
    }
}

// MARK: - Dates

enum DateText {
    private static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let weekdayDayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    static func short(_ date: Date) -> String { dayMonth.string(from: date) }
    static func withWeekday(_ date: Date) -> String { weekdayDayMonth.string(from: date) }
    static func clock(_ date: Date) -> String { time.string(from: date) }
    static func month(_ date: Date) -> String { monthYear.string(from: date) }
    static func full(_ date: Date) -> String { fullDate.string(from: date) }

    /// "Mar 4 – 8" when the months match, "Mar 28 – Apr 2" when they do not.
    static func range(_ start: Date, _ end: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            let day = calendar.component(.day, from: end)
            return "\(dayMonth.string(from: start)) – \(day)"
        }
        return "\(dayMonth.string(from: start)) – \(dayMonth.string(from: end))"
    }

    static func rangeWithTimes(_ start: Date, _ end: Date) -> String {
        "\(withWeekday(start)) · \(clock(start)) → \(withWeekday(end)) · \(clock(end))"
    }

    /// Relative label for message lists: "2m", "4h", "Yesterday", "Mar 3".
    static func relative(_ date: Date) -> String {
        let now = Date()
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        if seconds < 604_800 { return "\(Int(seconds / 86_400))d" }
        return short(date)
    }

    static func days(from start: Date, to end: Date) -> Int {
        max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    static func countdown(to date: Date) -> String {
        let seconds = date.timeIntervalSinceNow
        if seconds <= 0 { return "Started" }
        let days = Int(seconds / 86_400)
        if days >= 1 { return "in \(days) day\(days == 1 ? "" : "s")" }
        let hours = Int(seconds / 3600)
        if hours >= 1 { return "in \(hours) hr\(hours == 1 ? "" : "s")" }
        return "in \(max(1, Int(seconds / 60))) min"
    }
}

// MARK: - Symbol safety
//
// The artwork leans on newer vehicle symbols. Rather than risk a blank glyph on an
// older runtime, every symbol goes through here and falls back to one that has
// shipped since iOS 16.

enum Symbols {
    private static var cache: [String: String] = [:]

    static func resolve(_ name: String, fallback: String = "car.side.fill") -> String {
        if let cached = cache[name] { return cached }
        let resolved = UIImage(systemName: name) != nil ? name : fallback
        cache[name] = resolved
        return resolved
    }
}

// MARK: - Small view conveniences

extension View {
    /// Standard page gutter.
    func pageGutter() -> some View {
        padding(.horizontal, Space.gutter)
    }

    /// Fade-and-rise entrance with an optional stagger index. Movement is dropped
    /// when the system asks for reduced motion; the fade is kept because it still
    /// communicates that something arrived.
    func appear(_ index: Int = 0, isActive: Bool = true) -> some View {
        modifier(AppearModifier(index: index, isActive: isActive))
    }

    @ViewBuilder
    func hidden(_ condition: Bool) -> some View {
        if condition { hidden() } else { self }
    }
}

private struct AppearModifier: ViewModifier {
    let index: Int
    let isActive: Bool
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared || !isActive ? 1 : 0)
            .offset(y: (hasAppeared || !isActive || reduceMotion) ? 0 : 10)
            .onAppear {
                guard isActive, !hasAppeared else { return }
                withAnimation(Motion.enter.delay(Motion.stagger(index))) {
                    hasAppeared = true
                }
            }
    }
}

extension Color {
    /// Deterministic avatar tint so a given person keeps the same colour everywhere.
    static func avatarTint(seed: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.15, green: 0.38, blue: 0.31),
            Color(red: 0.36, green: 0.24, blue: 0.45),
            Color(red: 0.52, green: 0.29, blue: 0.18),
            Color(red: 0.16, green: 0.30, blue: 0.47),
            Color(red: 0.45, green: 0.20, blue: 0.27),
            Color(red: 0.27, green: 0.35, blue: 0.20)
        ]
        return palette[abs(seed) % palette.count]
    }
}

// MARK: - Avatar

struct Avatar: View {
    let initials: String
    var seed: Int = 0
    var size: CGFloat = 44
    var isVerified: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.avatarTint(seed: seed).opacity(0.95), Color.avatarTint(seed: seed + 3).opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .frame(width: size, height: size)

            if isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(Palette.accent)
                    .background(Circle().fill(Palette.surface).frame(width: size * 0.3, height: size * 0.3))
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: size, height: size)
    }
}
