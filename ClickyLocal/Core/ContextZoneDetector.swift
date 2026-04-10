import Foundation
import AppKit

@Observable
final class ContextZoneDetector {
    static let shared = ContextZoneDetector()

    var currentApp: String = ""
    var suggestedTools: [CompanionTool] = CompanionTool.allCases

    private var timer: Timer?

    private init() {}

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.detectFrontmostApp()
        }
        detectFrontmostApp()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func detectFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let name = app.localizedName ?? ""
        guard name != currentApp else { return }
        currentApp = name
        suggestedTools = toolsForApp(name)
    }

    private func toolsForApp(_ name: String) -> [CompanionTool] {
        let lowered = name.lowercased()

        // Code editors — prioritize chat + screen read
        if lowered.contains("xcode") || lowered.contains("code") || lowered.contains("terminal") || lowered.contains("iterm") {
            return [.chat, .screenRead, .notes, .clipboard, .rewrite]
        }

        // Communication — prioritize rewrite
        if lowered.contains("slack") || lowered.contains("discord") || lowered.contains("messages") || lowered.contains("mail") || lowered.contains("teams") {
            return [.rewrite, .chat, .clipboard, .notes, .screenRead]
        }

        // Browsers — prioritize screen read + notes
        if lowered.contains("safari") || lowered.contains("chrome") || lowered.contains("firefox") || lowered.contains("arc") {
            return [.screenRead, .notes, .chat, .clipboard, .rewrite]
        }

        return CompanionTool.allCases
    }
}
