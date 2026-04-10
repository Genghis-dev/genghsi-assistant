import Foundation
import AppKit

@Observable
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    var entries: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxEntries = 50

    private init() {}

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let content = pasteboard.string(forType: .string),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Don't duplicate the last entry
        if entries.first?.content == content { return }

        let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        let item = ClipboardItem(content: content, appSource: appName)

        entries.insert(item, at: 0)
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }

    func search(_ query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let appSource: String
    let capturedAt = Date()

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 { return trimmed }
        return String(trimmed.prefix(57)) + "..."
    }
}
