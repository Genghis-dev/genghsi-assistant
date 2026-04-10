import Foundation

struct TodoExtractor {
    private let gemma = GemmaClient.shared
    private let store = DataStore.shared

    func extractTodos(from note: Note) async {
        guard !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            let response = try await gemma.chat(
                messages: [ChatMessage(role: "user", content: note.content)],
                systemPrompt: Prompts.todoExtractor
            )

            // Parse JSON array from response
            let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = cleaned.data(using: .utf8),
                  let items = try? JSONDecoder().decode([String].self, from: data) else {
                return
            }

            await MainActor.run {
                for title in items where !title.isEmpty {
                    _ = store.createTodo(title: title, source: .extractedFromNote(note.id))
                }
            }
        } catch {
            print("Todo extraction failed: \(error)")
        }
    }
}
