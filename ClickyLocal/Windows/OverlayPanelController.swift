import Cocoa
import SwiftUI

final class OverlayPanelController {
    private var panel: NSPanel?
    private let companionManager: CompanionManager
    var onOpenPanel: ((CompanionTool) -> Void)?

    init(companionManager: CompanionManager) {
        self.companionManager = companionManager
    }

    private func setupPanel() {
        let contentView = NSHostingView(
            rootView: CompanionView(
                manager: companionManager,
                onOpenPanel: { [weak self] tool in
                    self?.onOpenPanel?(tool)
                }
            )
        )

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 60),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.hidesOnDeactivate = false
        newPanel.contentView = contentView
        newPanel.isMovableByWindowBackground = false
        newPanel.ignoresMouseEvents = false

        self.panel = newPanel
    }

    func show(at point: CGPoint) {
        if panel == nil {
            setupPanel()
        }
        guard let panel = panel, NSScreen.main != nil else { return }

        // Position toolbar centered horizontally on cursor, slightly above
        let panelSize = panel.frame.size
        let x = point.x - panelSize.width / 2
        let y = point.y - panelSize.height / 2 + 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
