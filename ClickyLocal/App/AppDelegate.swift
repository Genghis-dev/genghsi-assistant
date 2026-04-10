import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let companionManager = CompanionManager.shared
    private let hotkeyManager = HotkeyManager()
    private var overlayController: OverlayPanelController?
    private var toolPanelController = ToolPanelController()
    private var onboardingWindow: NSWindow?
    private var toolObserverTimer: Timer?
    private var cursorTracker: Timer?
    private var rightClickMonitor: Any?

    private static let onboardingCompleteKey = "onboardingComplete"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        setupOverlay()
        setupHotkey()
        setupRightClickMonitor()
        startToolObserver()
        ClipboardMonitor.shared.start()
        ContextZoneDetector.shared.start()

        if !UserDefaults.standard.bool(forKey: Self.onboardingCompleteKey) {
            showOnboarding()
        }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)

        let onboardingView = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.onboardingCompleteKey)
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 540),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: onboardingView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.onboardingWindow = window
    }

    @objc private func showOnboardingMenu() {
        UserDefaults.standard.set(false, forKey: Self.onboardingCompleteKey)
        showOnboarding()
    }

    // MARK: - MenuBar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Genghsi")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Genghsi (Double-tap ⌃)", action: #selector(toggleCompanion), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Setup Permissions...", action: #selector(showOnboardingMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - Overlay

    private func setupOverlay() {
        overlayController = OverlayPanelController(companionManager: companionManager)
    }

    // MARK: - Hotkey & Input

    private func setupHotkey() {
        hotkeyManager.onToggle = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleCompanion()
            }
        }
        hotkeyManager.onEscape = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.companionManager.isRadialMenuOpen {
                    self.companionManager.isRadialMenuOpen = false
                } else {
                    self.dismissAll()
                }
            }
        }
        hotkeyManager.start()
    }

    private func setupRightClickMonitor() {
        // Global right-click to open radial menu
        rightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.companionManager.isVisible else { return }
                self.companionManager.toggleRadialMenu()
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            DispatchQueue.main.async {
                guard let self, self.companionManager.isVisible else { return }
                self.companionManager.toggleRadialMenu()
            }
            return event
        }
    }

    // MARK: - Cursor Tracking (with easing)

    private var smoothX: CGFloat = 0
    private var smoothY: CGFloat = 0
    private let easingFactor: CGFloat = 0.15 // lower = smoother/laggier

    private func startCursorTracking() {
        let mouseLocation = NSEvent.mouseLocation
        smoothX = mouseLocation.x
        smoothY = mouseLocation.y

        cursorTracker = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self, self.companionManager.isVisible else { return }

            // Don't follow cursor when radial menu is open
            guard !self.companionManager.isRadialMenuOpen else { return }

            let target = NSEvent.mouseLocation
            // Lerp toward target position
            self.smoothX += (target.x - self.smoothX) * self.easingFactor
            self.smoothY += (target.y - self.smoothY) * self.easingFactor

            // Offset 20px right and 20px down (subtract Y because macOS Y is bottom-up)
            let smoothed = CGPoint(x: self.smoothX + 20, y: self.smoothY - 20)
            self.companionManager.position = smoothed
            self.overlayController?.updatePosition(smoothed)
        }
    }

    private func stopCursorTracking() {
        cursorTracker?.invalidate()
        cursorTracker = nil
    }

    // MARK: - Tool Observer

    private func startToolObserver() {
        toolObserverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if let tool = self.companionManager.selectedTool {
                self.companionManager.selectedTool = nil
                self.toolPanelController.show(tool: tool, near: self.companionManager.position)
            }
        }
    }

    // MARK: - Toggle

    @objc private func toggleCompanion() {
        if companionManager.isVisible {
            dismissAll()
        } else {
            let mouseLocation = NSEvent.mouseLocation
            companionManager.summon(at: mouseLocation)
            overlayController?.show(at: mouseLocation)
            startCursorTracking()
        }
    }

    private func dismissAll() {
        stopCursorTracking()
        companionManager.forceDissmiss()
        overlayController?.hide()
        toolPanelController.hide()
    }
}
