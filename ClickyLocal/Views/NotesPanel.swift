import SwiftUI
import SwiftData

struct NotesPanelView: View {
    @State private var notes: [Note] = []
    @State private var activeNote: Note?
    let store = DataStore.shared

    var sortedNotes: [Note] {
        notes.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.updatedAt > b.updatedAt
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if activeNote != nil {
                    Button(action: { withAnimation(.easeOut(duration: 0.15)) { activeNote = nil; refreshNotes() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Notes")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Notes")
                        .font(.system(size: 13, weight: .medium))
                }

                Spacer()

                if let note = activeNote {
                    HStack(spacing: 12) {
                        Button(action: { togglePin(note) }) {
                            Image(systemName: note.isPinned ? "pin.slash.fill" : "pin.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary.opacity(note.isPinned ? 0.8 : 1))
                        }
                        .buttonStyle(.plain)
                        .help(note.isPinned ? "Unpin" : "Pin")

                        Button(action: { deleteNote(note) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                } else {
                    Button(action: addNote) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.4)
                .padding(.horizontal, 12)

            if let note = activeNote {
                NoteDetailView(note: note)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                noteListView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 280, height: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .onAppear { refreshNotes() }
    }

    private var noteListView: some View {
        Group {
            if notes.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 20))
                        .foregroundStyle(.quaternary)
                    Text("No notes")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedNotes) { note in
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

                            if note.id != sortedNotes.last?.id {
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

// MARK: - List row with swipe actions

struct NoteListRow: View {
    let note: Note
    var onTap: () -> Void
    var onPin: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isHovered = false

    private var firstLine: String {
        let text = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "New Note" }
        return String(text.split(separator: "\n", maxSplits: 1).first ?? "New Note")
    }

    private var bodyPreview: String? {
        let lines = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: true)
        guard lines.count > 1 else { return nil }
        return String(lines[1].prefix(50))
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(note.updatedAt)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action background
            HStack(spacing: 0) {
                Spacer()

                // Pin action
                Button(action: {
                    withAnimation(.spring(response: 0.2)) { offset = 0 }
                    onPin()
                }) {
                    Image(systemName: note.isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.5))

                // Delete action
                Button(action: {
                    withAnimation(.spring(response: 0.2)) { offset = 0 }
                    onDelete()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color.red.opacity(0.8))
            }
            .clipShape(Rectangle())

            // Main row content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(.secondary)
                        }

                        Text(firstLine)
                            .font(.system(size: 13, weight: .regular))
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text(timeAgo)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        if let preview = bodyPreview {
                            Text(preview)
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(isHovered ? Color.primary.opacity(0.03) : Color(.windowBackgroundColor).opacity(0.01))
            )
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -100)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            if value.translation.width < -50 {
                                offset = -100
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 52)
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

// MARK: - Detail view

struct NoteDetailView: View {
    @Bindable var note: Note
    @FocusState private var isFocused: Bool

    private var charCount: String {
        let count = note.content.count
        if count == 0 { return "" }
        return "\(count) characters"
    }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $note.content)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .onChange(of: note.content) {
                    note.updatedAt = Date()
                    DataStore.shared.save()
                }

            if !charCount.isEmpty {
                HStack {
                    Spacer()
                    Text(charCount)
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .onAppear { isFocused = true }
    }
}
