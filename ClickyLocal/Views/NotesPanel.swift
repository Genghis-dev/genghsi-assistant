import SwiftUI
import SwiftData

struct NotesPanelView: View {
    var panelState: PanelState = .shared

    @State private var notes: [Note] = []
    @State private var activeNote: Note?
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool
    let store = DataStore.shared

    var filteredNotes: [Note] {
        let sorted = notes.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.updatedAt > b.updatedAt
        }
        if searchQuery.isEmpty { return sorted }
        return sorted.filter { $0.content.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let note = activeNote {
                NoteDetailView(
                    note: note,
                    panelState: panelState,
                    onBack: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            activeNote = nil
                            refreshNotes()
                        }
                    },
                    onDelete: {
                        deleteNote(note)
                    },
                    onTogglePin: {
                        togglePin(note)
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                noteListView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .onAppear { refreshNotes() }
    }

    // MARK: - List View

    private var noteListView: some View {
        VStack(spacing: 0) {
            // Search bar + new note button
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)

                    TextField("Search notes...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($isSearchFocused)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSearchFocused ? Color.primary.opacity(0.06) : Color.primary.opacity(0.04))
                )

                Button(action: addNote) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("New note")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            if filteredNotes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredNotes) { note in
                            NoteListRow(
                                note: note,
                                onTap: {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        activeNote = note
                                    }
                                },
                                onPin: { togglePin(note) },
                                onDelete: { deleteNote(note) }
                            )

                            if note.id != filteredNotes.last?.id {
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            if searchQuery.isEmpty {
                Image(systemName: "note.text")
                    .font(.system(size: 24))
                    .foregroundStyle(.quaternary)

                Text("Capture your first thought")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)

                Button(action: addNote) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                        Text("New Note")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.85))
                    )
                }
                .buttonStyle(.plain)

                Text("Double-tap ⌃ anywhere to quick-capture")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(.quaternary)

                Text("No matching notes")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func addNote() {
        let note = store.createNote()
        refreshNotes()
        withAnimation(.easeOut(duration: 0.15)) {
            activeNote = note
        }
    }

    private func togglePin(_ note: Note) {
        note.isPinned.toggle()
        note.updatedAt = Date()
        store.save()
        refreshNotes()
    }

    private func deleteNote(_ note: Note) {
        if activeNote?.id == note.id {
            withAnimation(.easeOut(duration: 0.15)) {
                activeNote = nil
            }
        }
        store.deleteNote(note)
        refreshNotes()
    }

    private func refreshNotes() {
        notes = store.fetchNotes()
    }
}

// MARK: - List Row with swipe actions

struct NoteListRow: View {
    let note: Note
    var onTap: () -> Void
    var onPin: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isHovered = false

    private var title: String {
        let text = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "New note" }
        let firstLine = text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? "New note"
        return firstLine.trimmingCharacters(in: .whitespaces)
    }

    private var preview: String? {
        let text = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
        guard lines.count > 1 else { return nil }
        let rest = String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard rest.count > 1 else { return nil }
        return String(rest.prefix(60))
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(note.updatedAt)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    private var isRevealed: Bool { offset < -10 }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action background — only rendered when revealed
            if isRevealed {
                HStack(spacing: 0) {
                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { offset = 0 }
                        onPin()
                    }) {
                        Image(systemName: note.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 56)
                            .background(Color.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)

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

            // Main row content
            HStack(spacing: 10) {
                // Pin indicator
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(red: 0.71, green: 0.83, blue: 0.95))
                        .frame(width: 10)
                } else {
                    Color.clear.frame(width: 10)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: note.isPinned ? .medium : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let preview = preview {
                        Text(preview)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Text(timeAgo)
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
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
                            offset = max(value.translation.width, -88)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            if value.translation.width < -44 {
                                offset = -88
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

// MARK: - Detail View

struct NoteDetailView: View {
    @Bindable var note: Note
    var panelState: PanelState
    var onBack: () -> Void
    var onDelete: () -> Void
    var onTogglePin: () -> Void

    @State private var isRewriting = false
    @State private var previousContent: String?
    @State private var showUndoRewrite = false
    @State private var isRecording = false
    @State private var extractedTodos: [Todo] = []
    @State private var showTodos = false
    @State private var isExtractingTodos = false
    @FocusState private var isFocused: Bool

    private let rewriter = Rewriter.shared
    private let speech = SpeechRecognizer.shared
    private let store = DataStore.shared

    private var wordCount: Int {
        note.content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private var charCount: Int {
        note.content.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Action bar
            actionBar

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            // Rewrite progress indicator
            if isRewriting {
                ProgressView()
                    .scaleEffect(0.4)
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
                    .tint(Color(red: 0.71, green: 0.83, blue: 0.95))
            }

            // Editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $note.content)
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .disabled(isRewriting)
                    .opacity(isRewriting ? 0.5 : 1)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .onChange(of: note.content) {
                        note.updatedAt = Date()
                        store.save()
                    }

                // Placeholder
                if note.content.isEmpty && !isFocused {
                    Text("Start writing...")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }

            // Undo rewrite link
            if showUndoRewrite {
                Button(action: undoRewrite) {
                    Text("Undo rewrite")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(red: 0.71, green: 0.83, blue: 0.95))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Status bar
            statusBar

            // Extracted todos section
            if showTodos && !extractedTodos.isEmpty {
                todoSection
            }
        }
        .onAppear {
            isFocused = true
            loadTodos()
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Notes")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Voice input
            ActionButton(
                icon: isRecording ? "mic.fill" : "mic",
                color: isRecording ? .red : .secondary,
                help: isRecording ? "Stop recording" : "Dictate"
            ) {
                toggleVoiceInput()
            }

            // Inline rewrite
            ActionButton(
                icon: "pencil.and.outline",
                color: .secondary,
                help: "Rewrite with AI"
            ) {
                rewriteInline()
            }
            .disabled(note.content.isEmpty || isRewriting)

            // Extract todos
            ActionButton(
                icon: "checklist",
                color: .secondary,
                help: "Extract todos"
            ) {
                extractTodos()
            }
            .disabled(note.content.isEmpty || isExtractingTodos)

            // Pin
            ActionButton(
                icon: note.isPinned ? "pin.slash.fill" : "pin.fill",
                color: .secondary,
                help: note.isPinned ? "Unpin" : "Pin"
            ) {
                onTogglePin()
            }

            // Delete
            ActionButton(
                icon: "trash",
                color: .secondary,
                help: "Delete"
            ) {
                onDelete()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text("Recording...")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            }

            Spacer()

            if charCount > 0 {
                Text("\(wordCount) words · \(charCount) characters")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Todo Section

    private var todoSection: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)

            HStack(spacing: 6) {
                Text("Extracted todos")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(action: { withAnimation { showTodos.toggle() } }) {
                    Image(systemName: showTodos ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            if showTodos {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(extractedTodos) { todo in
                            TodoRowView(
                                todo: todo,
                                onToggle: {
                                    todo.toggleCompleted()
                                    store.save()
                                },
                                onDelete: {
                                    store.deleteTodo(todo)
                                    extractedTodos.removeAll { $0.id == todo.id }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .frame(maxHeight: 120)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func rewriteInline() {
        previousContent = note.content
        isRewriting = true

        Task {
            if let result = await rewriter.rewrite(text: note.content) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    note.content = result
                    note.updatedAt = Date()
                    store.save()
                    isRewriting = false
                    showUndoRewrite = true
                }

                // Auto-hide undo after 10s
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        showUndoRewrite = false
                        previousContent = nil
                    }
                }
            } else {
                isRewriting = false
            }
        }
    }

    private func undoRewrite() {
        guard let previous = previousContent else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            note.content = previous
            note.updatedAt = Date()
            store.save()
            showUndoRewrite = false
            previousContent = nil
        }
    }

    private func toggleVoiceInput() {
        if speech.isListening {
            speech.stopListening()
            isRecording = false
        } else {
            isRecording = true
            speech.startListening()
            // Observe transcript changes
            Task {
                var lastLength = speech.transcript.count
                while speech.isListening {
                    try? await Task.sleep(for: .milliseconds(200))
                    if speech.transcript.count > lastLength {
                        let newText = String(speech.transcript.dropFirst(lastLength))
                        note.content += newText
                        note.updatedAt = Date()
                        store.save()
                        lastLength = speech.transcript.count
                    }
                }
            }
        }
    }

    private func extractTodos() {
        isExtractingTodos = true
        let extractor = TodoExtractor()

        Task {
            await extractor.extractTodos(from: note)
            await MainActor.run {
                loadTodos()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showTodos = true
                    isExtractingTodos = false
                }
            }
        }
    }

    private func loadTodos() {
        let allTodos = store.fetchTodos(includeCompleted: true)
        extractedTodos = allTodos.filter { todo in
            if case .extractedFromNote(let noteId) = todo.source {
                return noteId == note.id
            }
            return false
        }
        if !extractedTodos.isEmpty {
            showTodos = true
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    var color: Color = .secondary
    var help: String = ""
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
    }
}
