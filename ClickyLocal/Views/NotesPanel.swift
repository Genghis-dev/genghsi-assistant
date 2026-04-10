import SwiftUI
import SwiftData

struct NotesPanelView: View {
    @State private var notes: [Note] = []
    @State private var activeNote: Note?
    let store = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if activeNote != nil {
                    Button(action: { withAnimation(.easeOut(duration: 0.15)) { activeNote = nil } }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(activeNote != nil ? "" : "Notes")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                if activeNote == nil {
                    Button(action: addNote) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { deleteNote(activeNote!) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.5)
                .padding(.horizontal, 12)

            if let note = activeNote {
                // Detail view
                NoteDetailView(note: note)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // List view
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
                    LazyVStack(spacing: 1) {
                        ForEach(notes) { note in
                            NoteListRow(note: note, onTap: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    activeNote = note
                                }
                            }, onDelete: {
                                deleteNote(note)
                            })
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
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

// MARK: - List row

struct NoteListRow: View {
    let note: Note
    var onTap: () -> Void
    var onDelete: () -> Void

    @State private var isHovered = false

    private var preview: String {
        let text = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "Empty note" }
        return String(text.prefix(60))
    }

    private var firstLine: String {
        let text = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "Empty note" }
        return String(text.split(separator: "\n", maxSplits: 1).first ?? "Empty note")
    }

    private var secondLine: String? {
        let lines = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: true)
        guard lines.count > 1 else { return nil }
        return String(lines[1].prefix(40))
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(note.updatedAt)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(firstLine)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeAgo)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    if let sub = secondLine {
                        Text(sub)
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            }

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Detail view

struct NoteDetailView: View {
    @Bindable var note: Note
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $note.content)
            .font(.system(size: 13))
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .onChange(of: note.content) {
                note.updatedAt = Date()
                DataStore.shared.save()
            }
            .onAppear { isFocused = true }
    }
}
