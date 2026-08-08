import SwiftUI

// MARK: - Search sheet
//
// Two decisions — where and when. Kept on one sheet because splitting them into steps
// makes changing a date feel like starting a booking over.

struct SearchSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var place: String = ""
    @State private var start: Date = Date()
    @State private var end: Date = Date()
    @State private var isEditingPlace = false
    @FocusState private var placeFocused: Bool

    private let suggestions = [
        ("San Francisco, CA", "City centre", "building.2.fill"),
        ("SFO Airport", "Terminal pickup available", "airplane"),
        ("Oakland, CA", "Across the bay", "building.2.fill"),
        ("Lake Tahoe, CA", "Mountains · 3.5 hr drive", "mountain.2.fill"),
        ("Napa Valley, CA", "Wine country · 1.5 hr drive", "leaf.fill"),
        ("Los Angeles, CA", "Southern California", "sun.max.fill")
    ]

    private var filteredSuggestions: [(String, String, String)] {
        guard !place.isEmpty else { return suggestions }
        return suggestions.filter { $0.0.localizedCaseInsensitiveContains(place) }
    }

    private var dayCount: Int { DateText.days(from: start, to: end) }

    private var isValid: Bool {
        !place.trimmingCharacters(in: .whitespaces).isEmpty && end > start
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    placeField

                    if isEditingPlace || place.isEmpty {
                        suggestionList
                    } else {
                        dateSection
                        summary
                    }
                }
                .pageGutter()
                .padding(.vertical, Space.md)
            }
            .background(Palette.canvas)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(Typo.bodyMedium)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        place = state.query.place
                        start = state.query.startDate
                        end = state.query.endDate
                    }
                    .font(Typo.bodyMedium)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Hairline()
                    PrimaryButton(title: "Show cars", icon: "magnifyingglass", isEnabled: isValid) {
                        state.query.place = place
                        state.query.startDate = start
                        state.query.endDate = end
                        state.rememberSearch(place)
                        state.runSearch()
                        dismiss()
                    }
                    .padding(Space.md)
                }
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.large])
        .onAppear {
            place = state.query.place
            start = state.query.startDate
            end = state.query.endDate
        }
    }

    // MARK: Place

    private var placeField: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Where")
                .font(Typo.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Palette.inkTertiary)

            HStack(spacing: Space.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.inkSecondary)

                TextField("City, airport or address", text: $place)
                    .font(Typo.bodyLarge)
                    .foregroundStyle(Palette.ink)
                    .focused($placeFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onChange(of: placeFocused) { _, focused in
                        withAnimation(Motion.content) { isEditingPlace = focused }
                    }
                    .onSubmit {
                        placeFocused = false
                    }

                if !place.isEmpty {
                    Button {
                        place = ""
                        Haptics.tap()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
            }
            .padding(.horizontal, Space.md)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(placeFocused ? Palette.accent : Palette.hairlineStrong, lineWidth: placeFocused ? 1.5 : 1)
            )
            .animation(Motion.snap, value: placeFocused)
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            if !state.recentSearches.isEmpty, place.isEmpty {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Recent")
                        .font(Typo.eyebrow)
                        .tracking(1.2)
                        .foregroundStyle(Palette.inkTertiary)

                    ForEach(state.recentSearches, id: \.self) { recent in
                        Button {
                            select(recent)
                        } label: {
                            HStack(spacing: Space.sm) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.inkTertiary)
                                    .frame(width: 24)
                                Text(recent)
                                    .font(Typo.bodyMedium)
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle(scale: 0.99))
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text(place.isEmpty ? "Popular" : "Matches")
                    .font(Typo.eyebrow)
                    .tracking(1.2)
                    .foregroundStyle(Palette.inkTertiary)

                if filteredSuggestions.isEmpty {
                    Text("No places match “\(place)”. Search anyway — we'll look for hosts nearby.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .padding(.vertical, Space.xs)
                }

                ForEach(Array(filteredSuggestions.enumerated()), id: \.offset) { index, suggestion in
                    Button {
                        select(suggestion.0)
                    } label: {
                        HStack(spacing: Space.sm) {
                            Image(systemName: suggestion.2)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Palette.accentWash))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(suggestion.0)
                                    .font(Typo.bodyMedium)
                                    .foregroundStyle(Palette.ink)
                                Text(suggestion.1)
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.inkTertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle(scale: 0.99))
                    .appear(index)
                }
            }
        }
    }

    private func select(_ value: String) {
        Haptics.select()
        place = value
        placeFocused = false
        withAnimation(Motion.content) { isEditingPlace = false }
    }

    // MARK: Dates

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("When")
                .font(Typo.eyebrow)
                .tracking(1.2)
                .foregroundStyle(Palette.inkTertiary)

            Card(padding: Space.md) {
                VStack(spacing: Space.sm) {
                    DatePicker(
                        "Pick up",
                        selection: $start,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(Typo.bodyMedium)
                    .onChange(of: start) { _, newValue in
                        // Never let the return fall behind the pickup.
                        if end <= newValue {
                            end = Calendar.current.date(byAdding: .day, value: 1, to: newValue) ?? newValue
                        }
                    }

                    Hairline()

                    DatePicker(
                        "Return",
                        selection: $end,
                        in: (Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(Typo.bodyMedium)
                }
            }

            HStack(spacing: Space.xs) {
                ForEach([1, 2, 3, 7], id: \.self) { days in
                    Chip(
                        title: days == 7 ? "1 week" : "\(days) day\(days == 1 ? "" : "s")",
                        isSelected: dayCount == days
                    ) {
                        withAnimation(Motion.snap) {
                            end = Calendar.current.date(byAdding: .day, value: days, to: start) ?? start
                        }
                    }
                }
            }
        }
    }

    private var summary: some View {
        Card(padding: Space.md, elevation: .none, fill: Palette.surfaceSunken) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dayCount) day\(dayCount == 1 ? "" : "s")")
                        .font(Typo.bodySemibold)
                        .foregroundStyle(Palette.ink)
                    Text(DateText.rangeWithTimes(start, end))
                        .font(Typo.caption)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Space.xs)
                if dayCount >= 3 {
                    Badge(text: dayCount >= 7 ? "15% off" : "7% off", icon: "tag.fill")
                }
            }
        }
    }
}
