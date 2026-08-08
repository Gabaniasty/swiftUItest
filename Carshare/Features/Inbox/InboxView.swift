import SwiftUI

// MARK: - Inbox

struct InboxView: View {
    @Environment(AppState.self) private var state
    @State private var selected: Conversation?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                if state.conversations.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No messages",
                        message: "Book a car and your conversation with the host starts here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(state.conversations.enumerated()), id: \.element.id) { index, conversation in
                                Button {
                                    Haptics.tap()
                                    state.markRead(conversation.id)
                                    selected = conversation
                                } label: {
                                    ConversationRow(conversation: conversation)
                                }
                                .buttonStyle(PressableStyle(scale: 0.995, dimsOnPress: false))
                                .appear(index)

                                if index < state.conversations.count - 1 {
                                    Hairline(inset: 74)
                                }
                            }
                        }
                        .padding(.vertical, Space.xs)
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selected) { conversation in
                ChatView(conversationID: conversation.id)
            }
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    @Environment(AppState.self) private var state

    private var car: Car? { conversation.carID.flatMap { state.car($0) } }

    var body: some View {
        HStack(alignment: .top, spacing: Space.sm) {
            ZStack(alignment: .topLeading) {
                Avatar(
                    initials: conversation.participantName
                        .split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined(),
                    seed: conversation.participantSeed,
                    size: 46
                )
                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(Palette.accent)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Palette.canvas, lineWidth: 2))
                        .offset(x: -2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Space.xs) {
                    Text(conversation.participantName)
                        .font(conversation.unreadCount > 0 ? Typo.bodySemibold : Typo.bodyMedium)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    if conversation.isHostThread {
                        Badge(text: "Guest", tint: Palette.info)
                    }

                    Spacer(minLength: 0)

                    if let last = conversation.lastMessage {
                        Text(DateText.relative(last.sentAt))
                            .font(Typo.caption)
                            .foregroundStyle(Palette.inkTertiary)
                    }
                }

                if let car {
                    Text(car.title)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                }

                if let last = conversation.lastMessage {
                    Text(last.isSystem ? last.text : (last.isFromMe ? "You: \(last.text)" : last.text))
                        .font(Typo.caption)
                        .foregroundStyle(conversation.unreadCount > 0 ? Palette.ink : Palette.inkSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.vertical, Space.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Chat
//
// Reads the thread out of app state by id so a faked reply lands live while the sheet
// is open.

struct ChatView: View {
    let conversationID: UUID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var conversation: Conversation? {
        state.conversations.first { $0.id == conversationID }
    }

    private var car: Car? { conversation?.carID.flatMap { state.car($0) } }

    private let quickReplies = [
        "What time works for pickup?",
        "Is the car ready to collect?",
        "Running about 15 minutes late.",
        "Thanks — see you then!"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let car {
                        carStrip(car)
                        Hairline()
                    }

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Space.xs) {
                                ForEach(conversation?.messages ?? []) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(.horizontal, Space.gutter)
                            .padding(.vertical, Space.md)
                        }
                        .onChange(of: conversation?.messages.count) { _, _ in
                            withAnimation(Motion.enter) { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                        .onAppear {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }

                    composer
                }
            }
            .navigationTitle(conversation?.participantName ?? "Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.font(Typo.bodyMedium)
                }
            }
        }
    }

    private func carStrip(_ car: Car) -> some View {
        HStack(spacing: Space.sm) {
            CarThumb(car: car, height: 44, radius: Radius.sm)
                .frame(width: 64)
            VStack(alignment: .leading, spacing: 1) {
                Text(car.title)
                    .font(Typo.captionMedium)
                    .foregroundStyle(Palette.ink)
                Text("\(Money.short(car.dailyPrice))/day · \(car.location.name)")
                    .font(Typo.micro)
                    .foregroundStyle(Palette.inkTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.vertical, Space.xs)
        .background(Palette.surface)
    }

    private var composer: some View {
        VStack(spacing: Space.xs) {
            Hairline()

            if draft.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Space.xs) {
                        ForEach(quickReplies, id: \.self) { reply in
                            Button {
                                Haptics.select()
                                draft = reply
                            } label: {
                                Text(reply)
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.ink)
                                    .padding(.horizontal, Space.sm)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Palette.surfaceSunken))
                            }
                            .buttonStyle(PressableStyle(scale: 0.95, dimsOnPress: false))
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                }
                .transition(.opacity)
            }

            HStack(alignment: .bottom, spacing: Space.xs) {
                TextField("Message…", text: $draft, axis: .vertical)
                    .font(Typo.body)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, Space.sm)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .stroke(Palette.hairlineStrong, lineWidth: 1)
                    )

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.inkInverted)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(draft.isEmpty ? Palette.inkTertiary : Palette.accent))
                }
                .buttonStyle(PressableStyle(scale: 0.9, dimsOnPress: false))
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(Motion.snap, value: draft.isEmpty)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.xs)
        }
        .background(.regularMaterial)
        .animation(Motion.snap, value: draft.isEmpty)
    }

    private func send() {
        let text = draft
        draft = ""
        Haptics.tap()
        state.send(text, to: conversationID)
    }
}

// MARK: - Bubble

private struct MessageBubble: View {
    let message: Message

    var body: some View {
        if message.isSystem {
            Text(message.text)
                .font(Typo.caption)
                .foregroundStyle(Palette.inkTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.xs)
        } else {
            HStack {
                if message.isFromMe { Spacer(minLength: 44) }

                VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 3) {
                    Text(message.text)
                        .font(Typo.body)
                        .foregroundStyle(message.isFromMe ? Palette.inkInverted : Palette.ink)
                        .padding(.horizontal, Space.sm)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(message.isFromMe ? Palette.accent : Palette.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(message.isFromMe ? .clear : Palette.hairline, lineWidth: 1)
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Text(DateText.clock(message.sentAt))
                        .font(Typo.micro)
                        .foregroundStyle(Palette.inkTertiary)
                }

                if !message.isFromMe { Spacer(minLength: 44) }
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                )
            )
        }
    }
}
