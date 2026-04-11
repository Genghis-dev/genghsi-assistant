import Cocoa
import SwiftUI

final class ToolPanelController {
    private var panel: NSPanel?
    private let panelState = PanelState.shared

    func show(tool: CompanionTool, near point: CGPoint) {
        // If panel already exists, just switch tab
        if let existing = panel, existing.isVisible {
            panelState.switchTo(tool)
            return
        }

        let contentView = NSHostingView(
            rootView: UnifiedPanelView(panelState: panelState)
        )
        let panelSize = NSSize(width: 340, height: 488)

        let newPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.animationBehavior = .utilityWindow
        newPanel.hidesOnDeactivate = false
        newPanel.contentView = contentView
        newPanel.backgroundColor = .clear
        newPanel.isOpaque = false
        newPanel.hasShadow = true

        // Force-show native traffic lights (NSPanel hides them by default)
        newPanel.standardWindowButton(.closeButton)?.isHidden = false
        newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = false
        newPanel.standardWindowButton(.zoomButton)?.isHidden = false

        let x = point.x + 40
        let y = point.y - 170
        newPanel.setFrameOrigin(NSPoint(x: x, y: y))
        newPanel.orderFrontRegardless()

        panelState.switchTo(tool)
        panel = newPanel
        updateToolPanelState()
    }

    func hideAll() {
        panel?.orderOut(nil)
        panel = nil
        updateToolPanelState()
    }

    private func updateToolPanelState() {
        CompanionManager.shared.isToolPanelOpen = panel != nil
    }
}
