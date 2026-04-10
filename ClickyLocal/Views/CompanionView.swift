import SwiftUI

struct CompanionView: View {
    @Bindable var manager: CompanionManager

    @State private var showClickSparks = false
    @State private var showCursor = true

    var body: some View {
        ZStack {
            Color.clear

            if manager.isVisible {
                if manager.isPinned && !manager.isRadialMenuOpen && showCursor {
                    // Mini mode when pinned
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
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
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
                triggerClickAnimation()
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
    }

    private func triggerClickAnimation() {
        showClickSparks = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showClickSparks = false
        }
    }

    private var avatarView: some View {
        ZStack {
            // Click spark lines — three dashes radiating from top-left
            ClickSparksView(isActive: showClickSparks)

            // Main cursor arrow — drawn as a filled triangle shape
            CursorArrowShape()
                .fill(.primary.opacity(0.9))
                .frame(width: 22, height: 28)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .scaleEffect(showClickSparks ? 0.92 : 1.0)
                .animation(.spring(response: 0.15, dampingFraction: 0.6), value: showClickSparks)
        }
        .frame(width: 50, height: 50)
    }
}

// MARK: - Custom cursor arrow shape matching the image

struct CursorArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Arrow pointer — filled triangle with a slight tail
        path.move(to: CGPoint(x: w * 0.08, y: 0))               // top-left tip
        path.addLine(to: CGPoint(x: w * 0.08, y: h * 0.78))     // down left side
        path.addLine(to: CGPoint(x: w * 0.30, y: h * 0.62))     // notch inward
        path.addLine(to: CGPoint(x: w * 0.55, y: h))             // tail bottom-right
        path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.88))     // tail top-right
        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.55))     // notch back
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.52))     // right wing
        path.closeSubpath()                                       // back to tip

        return path
    }
}

// MARK: - Click spark animation

struct ClickSparksView: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            // Three spark lines at different angles, like in the reference image
            SparkLine(angle: -55, length: 8)
                .offset(x: -6, y: -10)

            SparkLine(angle: -25, length: 7)
                .offset(x: 2, y: -14)

            SparkLine(angle: -80, length: 6)
                .offset(x: -12, y: -4)
        }
        .opacity(isActive ? 1 : 0)
        .scaleEffect(isActive ? 1 : 0.3)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
    }
}

struct SparkLine: View {
    let angle: Double
    let length: CGFloat

    var body: some View {
        Capsule()
            .fill(.primary.opacity(0.85))
            .frame(width: 2.5, height: length)
            .rotationEffect(.degrees(angle))
    }
}
