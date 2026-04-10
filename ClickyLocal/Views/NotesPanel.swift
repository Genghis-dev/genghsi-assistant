import SwiftUI
import SwiftData

struct NotesPanelView: View {
    @State private var notes: [Note] = []
    @State private var selectedNote: Note?
    @State private var isEditing = false
    let store = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: addNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            if notes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No notes yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(notes) { note in
                            NoteRowView(note: note, onDelete: {
                                store.deleteNote(note)
                                refreshNotes()
                            })
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 260, height: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .onAppear { refreshNotes() }
    }

    private func addNote() {
        _ = store.createNote()
        refreshNotes()
    }

    private func refreshNotes() {
        notes = store.fetchNotes()
    }
}

struct NoteRowView: View {
    @Bindable var note: Note
    var onDelete: () -> Void
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                }

                TextEditor(text: $note.content)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .frame(minHeight: 32, maxHeight: 80)
                    .onChange(of: note.content) {
                        note.updatedAt = Date()
                        DataStore.shared.save()
                    }

                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isFocused ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
        )
        .onHover { isHovered = $0 }
    }
}
