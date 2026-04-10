import SwiftUI

struct CompanionView: View {
    @Bindable var manager: CompanionManager

    @State private var isPressed = false
    @State private var showCursor = true
    @State private var breathe = false

    var body: some View {
        ZStack {
            Color.clear

            if manager.isVisible {
                if manager.isPinned && !manager.isRadialMenuOpen && showCursor {
                    MiniModeView(manager: manager)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 0) {
                        if manager.isRadialMenuOpen {
                            RadialMenuView(manager: manager)
                                .transition(.scale.combined(with: .opacity))
                        }

                        if showCursor {
                            avatarView
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: 400, height: 400)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: manager.isVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isRadialMenuOpen)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isPinned)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showCursor)
        .onChange(of: manager.isRadialMenuOpen) { _, isOpen in
            if isOpen {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
        }
        .onChange(of: manager.selectedTool) { _, tool in
            if tool != nil {
                withAnimation(.easeOut(duration: 0.2)) {
                    showCursor = false
                }
            }
        }
        .onChange(of: manager.isToolPanelOpen) { _, open in
            if !open {
                withAnimation(.easeIn(duration: 0.2)) {
                    showCursor = true
                }
            }
        }
        .onChange(of: manager.isVisible) { _, visible in
            if visible {
                showCursor = true
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            // Soft outer glow — breathes slowly
            Circle()
                .fill(.primary.opacity(0.03))
                .frame(width: 20, height: 20)
                .scaleEffect(breathe ? 1.8 : 1.2)
                .opacity(breathe ? 0.6 : 0.3)

            // Main dot
            Circle()
                .fill(.primary.opacity(0.8))
                .frame(width: 10, height: 10)
                .scaleEffect(isPressed ? 0.7 : 1.0)
                .animation(.spring(response: 0.12, dampingFraction: 0.5), value: isPressed)
        }
    }
}
