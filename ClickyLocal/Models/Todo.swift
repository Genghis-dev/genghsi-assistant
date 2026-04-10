import Foundation
import SwiftData

enum TodoSource: Codable {
    case manual
    case extractedFromNote(UUID)
}

@Model
final class Todo {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var source: TodoSource
    var createdAt: Date
    var completedAt: Date?

    init(title: String, source: TodoSource = .manual) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.source = source
        self.createdAt = Date()
        self.completedAt = nil
    }

    func toggleCompleted() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
