import Cocoa
import SwiftUI

final class ToolPanelController {
    private var panels: [CompanionTool: NSPanel] = [:]

    func show(tool: CompanionTool, near point: CGPoint) {
        // If already open, toggle it off
        if let existing = panels[tool], existing.isVisible {
            existing.orderOut(nil)
            panels.removeValue(forKey: tool)
            updateToolPanelState()
            return
        }

        let contentView: NSView
        let panelSize: NSSize
        switch tool {
        case .notes:
            contentView = NSHostingView(rootView: NotesPanelView())
            panelSize = NSSize(width: 280, height: 380)
        case .chat:
            contentView = NSHostingView(rootView: ChatView())
            panelSize = NSSize(width: 300, height: 400)
        case .screenRead:
            contentView = NSHostingView(rootView: ChatView(captureScreenOnAppear: true))
            panelSize = NSSize(width: 300, height: 400)
        case .rewrite:
            contentView = NSHostingView(rootView: RewriteView())
            panelSize = NSSize(width: 280, height: 380)
        case .clipboard:
            contentView = NSHostingView(rootView: ClipboardPanelView())
            panelSize = NSSize(width: 270, height: 360)
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.hidesOnDeactivate = false
        panel.contentView = contentView
        panel.backgroundColor = .clear

        // Stack panels with offset so they don't overlap exactly
        let offset = CGFloat(panels.count) * 30
        let x = point.x + 40 + offset
        let y = point.y - 170 - offset
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()

        panels[tool] = panel
        updateToolPanelState()
    }

    func hideAll() {
        for (_, panel) in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        updateToolPanelState()
    }

    private func updateToolPanelState() {
        CompanionManager.shared.isToolPanelOpen = !panels.isEmpty
    }
}
