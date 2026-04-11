import Cocoa

final class HotkeyManager {
    var onToggle: (() -> Void)?
    var onEscape: (() -> Void)?
    var onToolSelect: ((CompanionTool) -> Void)?
    var onNewNote: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var flagsMonitor: Any?

    // Double-tap Control detection
    private var lastControlPress: Date?
    private let doubleTapThreshold: TimeInterval = 0.3

    func start() {
        // Key events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKey(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKey(event)
            return event
        }

        // Modifier flags (for detecting Control key press/release)
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
        }
        // Also need local flags monitor
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
            return event
        }
    }

    private func handleKey(_ event: NSEvent) {
        guard event.type == .keyDown else { return }

        // Escape
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        // Ctrl+number shortcuts for tool selection
        if event.modifierFlags.contains(.control) {
            switch event.keyCode {
            case 18: // Ctrl+1 → Chat
                onToolSelect?(.chat)
            case 19: // Ctrl+2 → Notes
                onToolSelect?(.notes)
            case 20: // Ctrl+3 → Rewrite
                onToolSelect?(.rewrite)
            case 45: // Ctrl+N → New note
                onNewNote?()
            default:
                break
            }
        }
    }

    private func handleFlags(_ event: NSEvent) {
        // Detect Control key press (flag appears) then release (flag disappears)
        let controlPressed = event.modifierFlags.contains(.control)

        if !controlPressed {
            // Control was released — check if this is a tap (press+release)
            // Only count it if no other modifiers are held
            let otherMods = event.modifierFlags.intersection([.command, .shift, .option])
            guard otherMods.isEmpty else { return }

            let now = Date()
            if let last = lastControlPress, now.timeIntervalSince(last) < doubleTapThreshold {
                // Double tap detected
                lastControlPress = nil
                onToggle?()
            } else {
                lastControlPress = now
            }
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        if let m = flagsMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
        flagsMonitor = nil
    }

    deinit { stop() }
}
