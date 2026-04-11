import Foundation

@Observable
final class PanelState {
    static let shared = PanelState()

    var activeTab: CompanionTool = .chat
    var prefillText: String?
    var attachedNote: Note?
    var previousTab: CompanionTool?

    private init() {}

    func switchTo(_ tab: CompanionTool) {
        previousTab = activeTab
        activeTab = tab
    }

    func switchToRewrite(withText text: String) {
        prefillText = text
        switchTo(.rewrite)
    }
}
