import Cocoa
import SwiftUI

final class ToolPanelController {
    private var panel: NSPanel?
    private var currentTool: CompanionTool?

    func show(tool: CompanionTool, near point: CGPoint) {
        // If same tool, toggle off
        if currentTool == tool, panel?.isVisible == true {
            hide()
            return
        }

        hide()
        currentTool = tool

        let contentView: NSView
        let panelSize: NSSize
        switch tool {
        case .notes:
            contentView = NSHostingView(rootView: NotesPanelView())
            panelSize = NSSize(width: 260, height: 340)
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

        // Position to the right of the companion
        let x = point.x + 40
        let y = point.y - 170
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()

        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        currentTool = nil
    }
}

struct PlaceholderToolView: View {
    let tool: CompanionTool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(tool.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 260, height: 340)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
