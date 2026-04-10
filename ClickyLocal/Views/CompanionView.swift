import SwiftUI

struct CompanionView: View {
    @Bindable var manager: CompanionManager

    var body: some View {
        ZStack {
            Color.clear

            if manager.isVisible {
                if manager.isPinned && !manager.isRadialMenuOpen {
                    // Mini mode when pinned
                    MiniModeView(manager: manager)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 0) {
                        if manager.isRadialMenuOpen {
                            RadialMenuView(manager: manager)
                                .transition(.scale.combined(with: .opacity))
                        }

                        avatarView
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: 400, height: 400)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: manager.isVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isRadialMenuOpen)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isPinned)
    }

    private var avatarView: some View {
        ZStack(alignment: .topLeading) {
            Image(systemName: "cursorarrow")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary.opacity(0.85))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)

            Circle()
                .fill(.primary.opacity(0.7))
                .frame(width: 6, height: 6)
                .offset(x: 18, y: 18)
        }
    }
}
