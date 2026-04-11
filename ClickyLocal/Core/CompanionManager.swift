import Foundation
import AppKit

@Observable
final class CompanionManager {
    static let shared = CompanionManager()

    var isVisible = false
    var position: CGPoint = .zero
    var isPinned = false
    var selectedTool: CompanionTool?
    var isToolPanelOpen = false

    private init() {}

    func summon(at point: CGPoint) {
        position = point
        isVisible = true
        selectedTool = nil
    }

    func dismiss() {
        if isPinned { return }
        isVisible = false
        selectedTool = nil
    }

    func togglePin() {
        isPinned.toggle()
    }

    func forceDissmiss() {
        isPinned = false
        isVisible = false
        selectedTool = nil
    }

    func selectTool(_ tool: CompanionTool) {
        selectedTool = tool
    }
}

enum CompanionTool: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case notes = "Notes"
    case rewrite = "Rewrite"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chat: return "bubble.left.fill"
        case .notes: return "note.text"
        case .rewrite: return "pencil.and.outline"
        }
    }
}
