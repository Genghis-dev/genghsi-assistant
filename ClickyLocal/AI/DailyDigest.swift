import Foundation

struct DailyDigest {
    private let gemma = GemmaClient.shared
    private let store = DataStore.shared

    private static let lastDigestKey = "lastDigestDate"

    var shouldShowDigest: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastDigestKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }

    func generate() async -> String? {
        let todos = await MainActor.run { store.fetchTodos(includeCompleted: false) }
        let notes = await MainActor.run {
            store.fetchNotes().prefix(5)
        }

        guard !todos.isEmpty || !notes.isEmpty else {
            return "Hey! You're all clear — no pending todos or recent notes. Fresh start today."
        }

        var context = "Pending todos:\n"
        for todo in todos {
            context += "- \(todo.title)\n"
        }

        if !notes.isEmpty {
            context += "\nRecent notes:\n"
            for note in notes {
                let preview = String(note.content.prefix(100))
                context += "- \(preview)\n"
            }
        }

        do {
            let result = try await gemma.chat(
                messages: [ChatMessage(role: "user", content: context)],
                systemPrompt: Prompts.dailyDigest
            )
            UserDefaults.standard.set(Date(), forKey: Self.lastDigestKey)
            return result
        } catch {
            print("Daily digest failed: \(error)")
            return nil
        }
    }
}
