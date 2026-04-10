import Foundation
import SwiftData

@MainActor
final class DataStore {
    static let shared = DataStore()

    let container: ModelContainer

    init() {
        let schema = Schema([Note.self, Todo.self])
        let config = ModelConfiguration("Genghsi", isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var context: ModelContext {
        container.mainContext
    }

    // MARK: - Notes

    func fetchNotes() -> [Note] {
        var descriptor = FetchDescriptor<Note>()
        descriptor.sortBy = [SortDescriptor(\Note.updatedAt, order: .reverse)]
        let results = (try? context.fetch(descriptor)) ?? []
        // Pinned notes first
        return results.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
    }

    func createNote(content: String = "") -> Note {
        let note = Note(content: content)
        context.insert(note)
        try? context.save()
        return note
    }

    func deleteNote(_ note: Note) {
        context.delete(note)
        try? context.save()
    }

    // MARK: - Todos

    func fetchTodos(includeCompleted: Bool = false) -> [Todo] {
        let descriptor: FetchDescriptor<Todo>
        if includeCompleted {
            descriptor = FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        } else {
            descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { !$0.isCompleted },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    func createTodo(title: String, source: TodoSource = .manual) -> Todo {
        let todo = Todo(title: title, source: source)
        context.insert(todo)
        try? context.save()
        return todo
    }

    func deleteTodo(_ todo: Todo) {
        context.delete(todo)
        try? context.save()
    }

    func save() {
        try? context.save()
    }
}
