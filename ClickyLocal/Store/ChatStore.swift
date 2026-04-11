import Foundation

struct ChatSession: Codable, Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "New chat", messages: [ChatMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Observable
final class ChatStore {
    static let shared = ChatStore()

    var sessions: [ChatSession] = []
    var currentSessionId: UUID?

    private let fileURL: URL
    private let legacyFileURL: URL
    private let maxMessagesPerSession = 100

    // MARK: - Computed

    var currentSession: ChatSession? {
        guard let id = currentSessionId else { return nil }
        return sessions.first { $0.id == id }
    }

    var messages: [ChatMessage] {
        currentSession?.messages ?? []
    }

    var sortedSessions: [ChatSession] {
        sessions.sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Genghsi", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("chat_sessions.json")
        self.legacyFileURL = dir.appendingPathComponent("chat_history.json")
        load()

        // Ensure at least one session exists
        if sessions.isEmpty {
            let session = ChatSession()
            sessions.append(session)
            currentSessionId = session.id
            save()
        } else if currentSessionId == nil {
            currentSessionId = sortedSessions.first?.id
        }
    }

    // MARK: - Session management

    @discardableResult
    func newSession() -> ChatSession {
        let session = ChatSession()
        sessions.append(session)
        currentSessionId = session.id
        save()
        return session
    }

    func selectSession(_ id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        currentSessionId = id
    }

    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }

        // If we deleted the current session, pick another or create a new one
        if currentSessionId == id {
            if let next = sortedSessions.first {
                currentSessionId = next.id
            } else {
                let session = ChatSession()
                sessions.append(session)
                currentSessionId = session.id
            }
        }
        save()
    }

    // MARK: - Message management

    func append(_ message: ChatMessage) {
        guard let id = currentSessionId,
              let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        sessions[index].messages.append(message)
        sessions[index].updatedAt = Date()

        // Auto-title from first user message
        if sessions[index].title == "New chat",
           message.role == "user",
           !message.content.isEmpty {
            sessions[index].title = Self.generateTitle(from: message.content)
        }

        // Trim to keep file bounded
        if sessions[index].messages.count > maxMessagesPerSession {
            sessions[index].messages = Array(sessions[index].messages.suffix(maxMessagesPerSession))
        }

        save()
    }

    func clearCurrent() {
        guard let id = currentSessionId,
              let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].messages.removeAll()
        sessions[index].title = "New chat"
        sessions[index].updatedAt = Date()
        save()
    }

    private static func generateTitle(from text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = cleaned.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? cleaned
        if firstLine.count <= 40 { return firstLine }
        return String(firstLine.prefix(40)) + "…"
    }

    // MARK: - Persistence

    private func load() {
        // Try the new format first
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = decoded
            return
        }

        // Migrate from legacy single-history file
        if let data = try? Data(contentsOf: legacyFileURL),
           let legacy = try? JSONDecoder().decode([ChatMessage].self, from: data),
           !legacy.isEmpty {
            let migrated = ChatSession(
                title: Self.generateTitle(from: legacy.first { $0.role == "user" }?.content ?? "Previous chat"),
                messages: legacy
            )
            sessions = [migrated]
            currentSessionId = migrated.id
            save()
            try? FileManager.default.removeItem(at: legacyFileURL)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
