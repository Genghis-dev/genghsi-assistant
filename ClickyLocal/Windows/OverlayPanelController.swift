import Cocoa
import SwiftUI

final class OverlayPanelController {
    private var panel: NSPanel?
    private let companionManager: CompanionManager

    init(companionManager: CompanionManager) {
        self.companionManager = companionManager
        setupPanel()
    }

    private func setupPanel() {
        let contentView = NSHostingView(rootView: CompanionView(manager: companionManager))

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.contentView = contentView
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true

        self.panel = panel
    }

    func show(at point: CGPoint) {
        guard let panel = panel, NSScreen.main != nil else { return }

        // Convert from global screen coordinates (origin bottom-left) to window position
        // Center the panel on the cursor
        let panelSize = panel.frame.size
        let x = point.x - panelSize.width / 2
        let y = point.y - panelSize.height / 2

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func updatePosition(_ point: CGPoint) {
        guard let panel = panel else { return }
        let panelSize = panel.frame.size
        let x = point.x - panelSize.width / 2
        let y = point.y - panelSize.height / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
