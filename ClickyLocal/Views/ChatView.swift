import SwiftUI

struct ChatView: View {
    var panelState: PanelState = .shared

    @State private var inputText = ""
    @State private var streamingResponse = ""
    @State private var showingHistory = false
    @FocusState private var isInputFocused: Bool

    private let gemma = GemmaClient.shared
    private let store = DataStore.shared
    private let chatStore = ChatStore.shared

    private var messages: [ChatMessage] {
        chatStore.messages
    }

    var body: some View {
        VStack(spacing: 0) {
            if showingHistory {
                historyView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                chatContentView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onAppear {
            isInputFocused = true
            Task { await gemma.checkConnection() }
        }
    }

    // MARK: - Chat Content

    private var chatContentView: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            // Note context banner
            if let note = panelState.attachedNote {
                noteContextBanner(note)
            }

            // Messages or empty state
            if messages.isEmpty && streamingResponse.isEmpty && !gemma.isGenerating {
                emptyState
            } else {
                messageList
            }

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 10)

            // Input bar
            inputBar
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showingHistory = true
                }
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Chat history")

            Text(chatStore.currentSession?.title ?? "New chat")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button(action: newChat) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("New chat")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Note Context Banner

    private func noteContextBanner(_ note: Note) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "paperclip")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text(note.content.split(separator: "\n").first.map(String.init) ?? "Note")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button(action: { panelState.attachedNote = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(red: 0.71, green: 0.83, blue: 0.95).opacity(0.08))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkle")
                .font(.system(size: 24))
                .foregroundStyle(.quaternary)

            Text("What can I help with?")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            // Suggestion chips
            VStack(spacing: 8) {
                suggestionChip("Help me brainstorm...")
                suggestionChip("Summarize my notes")
                suggestionChip("What should I focus on today?")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button(action: {
            if text == "What should I focus on today?" {
                sendDailyDigest()
            } else {
                inputText = text
                isInputFocused = true
            }
        }) {
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }

                    // Streaming response
                    if !streamingResponse.isEmpty {
                        MessageBubble(
                            message: ChatMessage(role: "assistant", content: streamingResponse),
                            isStreaming: true
                        )
                        .id("streaming")
                    }

                    if gemma.isGenerating && streamingResponse.isEmpty {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.5)
                            Text("Thinking...")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .onChange(of: streamingResponse) {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask Genghsi...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isInputFocused)
                .onSubmit { sendMessage() }
                .disabled(gemma.isGenerating)

            if gemma.isGenerating {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(inputText.isEmpty ? .quaternary : .primary)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        chatStore.append(ChatMessage(role: "user", content: text))
        inputText = ""
        streamingResponse = ""

        gemma.streamChat(
            messages: chatStore.messages,
            systemPrompt: buildSystemPrompt(),
            onToken: { token in
                streamingResponse += token
            },
            onComplete: {
                if !streamingResponse.isEmpty {
                    chatStore.append(ChatMessage(role: "assistant", content: streamingResponse))
                }
                streamingResponse = ""
            },
            onError: { error in
                chatStore.append(ChatMessage(role: "assistant", content: "Genghsi is offline — start Docker Desktop with Model Runner enabled."))
                streamingResponse = ""
            }
        )
    }

    private func sendDailyDigest() {
        let todos = store.fetchTodos()

        var context = "\n\nPending todos:\n"
        if todos.isEmpty {
            context += "(none)\n"
        } else {
            for todo in todos.prefix(10) {
                context += "- \(todo.title)\n"
            }
        }

        inputText = ""
        chatStore.append(ChatMessage(role: "user", content: "What should I focus on today?"))
        streamingResponse = ""

        gemma.streamChat(
            messages: chatStore.messages,
            systemPrompt: Prompts.dailyDigest + "\n\n" + buildNotesContext() + context,
            onToken: { token in streamingResponse += token },
            onComplete: {
                if !streamingResponse.isEmpty {
                    chatStore.append(ChatMessage(role: "assistant", content: streamingResponse))
                }
                streamingResponse = ""
            },
            onError: { error in
                chatStore.append(ChatMessage(role: "assistant", content: "Genghsi is offline — start Docker Desktop with Model Runner enabled."))
                streamingResponse = ""
            }
        )
    }

    // MARK: - Context Building

    /// Build the full system prompt with notes context and any attached note.
    private func buildSystemPrompt() -> String {
        var prompt = Prompts.companion
        prompt += "\n\n" + buildNotesContext()

        if let note = panelState.attachedNote {
            prompt += "\n\nThe user is currently viewing this note — focus on it:\n\"\"\"\n\(note.content)\n\"\"\""
        }
        return prompt
    }

    /// Serialize all of the user's notes into a compact context block.
    private func buildNotesContext() -> String {
        let notes = store.fetchNotes()
        guard !notes.isEmpty else {
            return "The user has no notes yet."
        }

        var context = "The user's notes (\(notes.count) total):\n"
        let maxNotes = 30
        let maxCharsPerNote = 800

        for (index, note) in notes.prefix(maxNotes).enumerated() {
            let content = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { continue }

            let truncated = content.count > maxCharsPerNote
                ? String(content.prefix(maxCharsPerNote)) + "…"
                : content

            let pinMark = note.isPinned ? " 📌" : ""
            context += "\n--- Note \(index + 1)\(pinMark) ---\n\(truncated)\n"
        }

        if notes.count > maxNotes {
            context += "\n(\(notes.count - maxNotes) older notes not shown)"
        }
        return context
    }

    private func newChat() {
        chatStore.newSession()
        streamingResponse = ""
        inputText = ""
        panelState.attachedNote = nil
        isInputFocused = true
    }

    // MARK: - History View

    private var historyView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        showingHistory = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Chat history")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: {
                    newChat()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        showingHistory = false
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("New chat")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            // Session list
            if chatStore.sessions.isEmpty {
                Spacer()
                Text("No chat history yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(chatStore.sortedSessions) { session in
                            ChatSessionRow(
                                session: session,
                                isActive: session.id == chatStore.currentSessionId,
                                onTap: {
                                    chatStore.selectSession(session.id)
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        showingHistory = false
                                    }
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        chatStore.deleteSession(session.id)
                                    }
                                }
                            )

                            if session.id != chatStore.sortedSessions.last?.id {
                                Divider()
                                    .opacity(0.3)
                                    .padding(.leading, 14)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Chat Session Row

private struct ChatSessionRow: View {
    let session: ChatSession
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isHovered = false

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(session.updatedAt)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    private var subtitle: String {
        let count = session.messages.count
        if count == 0 { return timeAgo }
        return "\(timeAgo) · \(count) message\(count == 1 ? "" : "s")"
    }

    private var isRevealed: Bool { offset < -10 }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action
            if isRevealed {
                HStack(spacing: 0) {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { offset = 0 }
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 56)
                            .background(Color.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }

            // Row content
            HStack(spacing: 10) {
                // Active indicator
                if isActive {
                    Circle()
                        .fill(Color(red: 0.71, green: 0.83, blue: 0.95))
                        .frame(width: 5, height: 5)
                        .frame(width: 10)
                } else {
                    Color.clear.frame(width: 10)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(.system(size: 13, weight: isActive ? .medium : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Hover delete button (alternative to swipe for discoverability)
                if isHovered && !isRevealed {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Delete chat")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(isHovered ? Color.primary.opacity(0.05) : .clear)
                    )
            )
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -44)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            if value.translation.width < -22 {
                                offset = -44
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 56)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            if offset < 0 {
                withAnimation(.spring(response: 0.2)) { offset = 0 }
            } else {
                onTap()
            }
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    var isStreaming = false

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 50) }

            HStack(spacing: 0) {
                // Accent bar for assistant messages
                if !isUser {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.71, green: 0.83, blue: 0.95).opacity(0.3))
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(message.content + (isStreaming ? "│" : ""))
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isUser ? Color.primary.opacity(0.85) : Color.primary.opacity(0.04))
            )
            .foregroundStyle(isUser ? Color(.windowBackgroundColor) : .primary)

            if !isUser { Spacer(minLength: 50) }
        }
    }
}
