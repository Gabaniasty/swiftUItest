import SwiftUI
import UIKit

// MARK: - Press feedback
//
// Every pressable surface in the app scales to 0.97. It is the single cheapest thing
// that makes an interface feel like it is listening.

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var dimsOnPress: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? scale : 1))
            .opacity(configuration.isPressed && dimsOnPress ? 0.88 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension View {
    /// For non-Button surfaces (rows, cards) that still need press feedback.
    func pressable(_ scale: CGFloat = 0.98) -> some View {
        buttonStyle(PressableStyle(scale: scale))
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warn() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Space.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Palette.inkInverted)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(Typo.bodySemibold)
            }
            .foregroundStyle(Palette.inkInverted)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? Space.md : Space.lg)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Palette.accent)
            )
            .opacity(isEnabled ? 1 : 0.38)
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled || isLoading)
        .animation(Motion.snap, value: isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Space.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(Typo.bodySemibold)
            }
            .foregroundStyle(isDestructive ? Palette.danger : Palette.ink)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? Space.md : Space.lg)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isDestructive ? Palette.danger.opacity(0.4) : Palette.hairlineStrong, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

struct TertiaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Space.xxs) {
                Text(title).font(Typo.bodySemibold)
                if let icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(Palette.accent)
        }
        .buttonStyle(PressableStyle(scale: 0.96, dimsOnPress: true))
    }
}

/// Circular icon button used over photography (back, favourite, share).
struct GlassIconButton: View {
    let icon: String
    var isActive: Bool = false
    var activeColor: Color = Palette.danger
    var size: CGFloat = 36
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(isActive ? activeColor : Palette.ink)
                .frame(width: size, height: size)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Palette.hairline, lineWidth: 0.5))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressableStyle(scale: 0.9, dimsOnPress: false))
    }
}

// MARK: - Chips

struct Chip: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    var showsChevron: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                }
                Text(title).font(Typo.captionMedium)
                if showsChevron {
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? Palette.inkInverted : Palette.ink)
            .padding(.horizontal, Space.sm)
            .frame(height: 34)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Palette.ink : Palette.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? .clear : Palette.hairlineStrong, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle(scale: 0.95, dimsOnPress: false))
        .animation(Motion.snap, value: isSelected)
    }
}

/// Static, non-tappable label (EV, Instant Book, All-Star Host…).
struct Badge: View {
    let text: String
    var icon: String? = nil
    var tint: Color = Palette.accent

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 9, weight: .bold))
            }
            Text(text.uppercased())
                .font(Typo.micro)
                .tracking(0.6)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

// MARK: - Containers

struct Card<Content: View>: View {
    var padding: CGFloat = Space.md
    var radius: CGFloat = Radius.lg
    var elevation: Elevation = .low
    /// Card surfaces are opaque, so a tinted card has to be set here rather than by
    /// layering a `.background` behind it — that would sit under the fill and never show.
    var fill: Color = Palette.surface
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
            .elevation(elevation)
    }
}

struct SectionHeader: View {
    let title: String
    var eyebrow: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(Typo.eyebrow)
                        .tracking(1.1)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text(title)
                    .font(Typo.sectionTitle)
                    .foregroundStyle(Palette.ink)
            }
            Spacer(minLength: Space.sm)
            if let actionTitle, let action {
                TertiaryButton(title: actionTitle, action: action)
            }
        }
    }
}

struct Hairline: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// Label / value row used in price breakdowns and spec lists.
struct DetailRow: View {
    let label: String
    let value: String
    var labelIcon: String? = nil
    var isEmphasised: Bool = false
    var valueColor: Color? = nil
    var strikethrough: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.sm) {
            HStack(spacing: 6) {
                if let labelIcon {
                    Image(systemName: labelIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text(label)
                    .font(isEmphasised ? Typo.bodySemibold : Typo.body)
                    .foregroundStyle(isEmphasised ? Palette.ink : Palette.inkSecondary)
            }
            Spacer(minLength: Space.xs)
            Text(value)
                .font(isEmphasised ? Typo.numeric(17) : Typo.numeric(15, weight: .medium))
                .strikethrough(strikethrough, color: Palette.inkTertiary)
                .foregroundStyle(valueColor ?? Palette.ink)
        }
    }
}

// MARK: - Rating

struct RatingLabel: View {
    let rating: Double
    var tripCount: Int? = nil
    var size: CGFloat = 13
    var showsWord: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: size - 2))
                .foregroundStyle(Palette.star)
            Text(String(format: "%.2f", rating))
                .font(Typo.numeric(size, weight: .semibold))
                .foregroundStyle(Palette.ink)
            if let tripCount {
                Text(showsWord ? "(\(tripCount) trips)" : "(\(tripCount))")
                    .font(.system(size: size - 1))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
    }
}

struct StarRow: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating.rounded() ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(Palette.star)
            }
        }
    }
}

/// Horizontal bar used in the ratings breakdown (cleanliness, comms…).
struct ScoreBar: View {
    let label: String
    let score: Double

    var body: some View {
        HStack(spacing: Space.sm) {
            Text(label)
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 96, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.surfaceSunken)
                    Capsule()
                        .fill(Palette.ink)
                        .frame(width: max(4, geo.size.width * (score / 5)))
                }
            }
            .frame(height: 5)
            Text(String(format: "%.1f", score))
                .font(Typo.numeric(12, weight: .medium))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

// MARK: - Controls

struct CounterControl: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...5

    var body: some View {
        HStack(spacing: Space.sm) {
            stepButton("minus", enabled: value > range.lowerBound) {
                value = max(range.lowerBound, value - 1)
            }
            Text("\(value)")
                .font(Typo.numeric(16))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 20)
                .contentTransition(.numericText())
            stepButton("plus", enabled: value < range.upperBound) {
                value = min(range.upperBound, value + 1)
            }
        }
        .animation(Motion.snap, value: value)
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Palette.ink : Palette.inkTertiary.opacity(0.5))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(enabled ? Palette.hairlineStrong : Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.9, dimsOnPress: false))
        .disabled(!enabled)
    }
}

/// Radio-style selectable row used for protection plans and payment methods.
struct SelectableRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    @ViewBuilder var trailing: () -> Trailing
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(alignment: .top, spacing: Space.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Palette.accent : Palette.hairlineStrong, lineWidth: isSelected ? 6 : 1.5)
                        .frame(width: 20, height: 20)
                }
                .frame(width: 20, height: 20)
                .padding(.top, 2)
                .animation(Motion.snap, value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.inkSecondary)
                        }
                        Text(title)
                            .font(Typo.bodySemibold)
                            .foregroundStyle(Palette.ink)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: Space.xs)
                trailing()
            }
            .padding(Space.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isSelected ? Palette.accentWash : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isSelected ? Palette.accent.opacity(0.5) : Palette.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle(scale: 0.99, dimsOnPress: false))
        .animation(Motion.snap, value: isSelected)
    }
}

extension SelectableRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, icon: icon, isSelected: isSelected, trailing: { EmptyView() }, action: action)
    }
}

/// Navigation-style settings row.
struct NavRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var accessory: String? = "chevron.right"
    var tint: Color = Palette.ink
    var badgeText: String? = nil

    var body: some View {
        HStack(spacing: Space.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(tint == Palette.ink ? Palette.inkSecondary : tint)
                    .frame(width: 26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Typo.bodyMedium)
                    .foregroundStyle(tint)
                if let subtitle {
                    Text(subtitle)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            Spacer(minLength: Space.xs)
            if let badgeText {
                Text(badgeText)
                    .font(Typo.micro)
                    .foregroundStyle(Palette.inkInverted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.danger))
            }
            if let accessory {
                Image(systemName: accessory)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty & loading states

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Space.md) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 68, height: 68)
                .background(Circle().fill(Palette.surfaceSunken))

            VStack(spacing: Space.xxs) {
                Text(title)
                    .font(Typo.sectionTitle)
                    .foregroundStyle(Palette.ink)
                Text(message)
                    .font(Typo.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, fullWidth: false, action: action)
                    .padding(.top, Space.xxs)
            }
        }
        .frame(maxWidth: 300)
        .padding(Space.xl)
    }
}

/// Sweeping highlight used while faked network work is in flight.
struct Shimmer: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Palette.ink.opacity(0.06), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.6)
            .offset(x: phase * geo.size.width * 1.6)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SkeletonBlock: View {
    var height: CGFloat = 14
    var width: CGFloat? = nil
    var radius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Palette.surfaceSunken)
            .frame(width: width, height: height)
            .overlay(Shimmer().clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous)))
    }
}

// MARK: - Toast
//
// Enters and exits from the same edge so a swipe-to-dismiss would feel natural.

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: Space.sm) {
            Image(systemName: toast.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(toast.style.tint)
            Text(toast.message)
                .font(Typo.bodyMedium)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, Space.sm)
        .background(
            Capsule(style: .continuous)
                .fill(Palette.surfaceRaised)
        )
        .overlay(Capsule(style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .elevation(.high)
        .padding(.horizontal, Space.gutter)
    }
}

// MARK: - Layout helper
//
// Wrapping flow layout for feature/amenity tags. Layout protocol, iOS 16+.

struct WrapLayout: Layout {
    var spacing: CGFloat = Space.xs
    var lineSpacing: CGFloat = Space.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
