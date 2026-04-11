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

    private static let onboardingCompleteKey = "onboardingComplete"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        setupOverlay()
        setupHotkey()
        startToolObserver()
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
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
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
        overlayController?.onOpenPanel = { [weak self] tool in
            guard let self else { return }
            self.toolPanelController.show(tool: tool, near: self.companionManager.position)
        }
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
                self?.handleEscape()
            }
        }
        hotkeyManager.onToolSelect = { [weak self] tool in
            DispatchQueue.main.async {
                self?.openTool(tool)
            }
        }
        hotkeyManager.onNewNote = { [weak self] in
            DispatchQueue.main.async {
                self?.createNewNote()
            }
        }
        hotkeyManager.start()
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
        }
    }

    private func openTool(_ tool: CompanionTool) {
        if !companionManager.isVisible {
            let mouseLocation = NSEvent.mouseLocation
            companionManager.summon(at: mouseLocation)
            overlayController?.show(at: mouseLocation)
        }
        toolPanelController.show(tool: tool, near: companionManager.position)
    }

    @MainActor private func createNewNote() {
        let store = DataStore.shared
        _ = store.createNote()

        if !companionManager.isVisible {
            let mouseLocation = NSEvent.mouseLocation
            companionManager.summon(at: mouseLocation)
            overlayController?.show(at: mouseLocation)
        }
        toolPanelController.show(tool: .notes, near: companionManager.position)
    }

    // MARK: - Escape Hierarchy

    private func handleEscape() {
        // Progressive dismissal:
        // 1. If panel is open → close panel (toolbar stays)
        // 2. If toolbar is visible → dismiss everything
        if companionManager.isToolPanelOpen {
            toolPanelController.hideAll()
        } else if companionManager.isVisible {
            dismissAll()
        }
    }

    private func dismissAll() {
        companionManager.forceDissmiss()
        overlayController?.hide()
        toolPanelController.hideAll()
    }
}
