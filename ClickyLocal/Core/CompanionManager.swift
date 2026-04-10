import Foundation
import AppKit

@Observable
final class CompanionManager {
    static let shared = CompanionManager()

    var isVisible = false
    var position: CGPoint = .zero
    var isRadialMenuOpen = false
    var isPinned = false
    var selectedTool: CompanionTool?

    private init() {}

    func summon(at point: CGPoint) {
        position = point
        isVisible = true
        isRadialMenuOpen = false
        selectedTool = nil
    }

    func dismiss() {
        if isPinned { return } // Don't dismiss when pinned
        isVisible = false
        isRadialMenuOpen = false
        selectedTool = nil
    }

    func togglePin() {
        isPinned.toggle()
    }

    func forceDissmiss() {
        isPinned = false
        isVisible = false
        isRadialMenuOpen = false
        selectedTool = nil
    }

    func toggleRadialMenu() {
        isRadialMenuOpen.toggle()
    }

    func selectTool(_ tool: CompanionTool) {
        selectedTool = tool
        isRadialMenuOpen = false
    }
}

enum CompanionTool: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case notes = "Notes"
    case rewrite = "Rewrite"
    case screenRead = "Screen"
    case clipboard = "Clipboard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chat: return "bubble.left.fill"
        case .notes: return "note.text"
        case .rewrite: return "pencil.and.outline"
        case .screenRead: return "eye.fill"
        case .clipboard: return "doc.on.clipboard"
        }
    }
}
