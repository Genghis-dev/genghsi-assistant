import SwiftUI

struct CompanionView: View {
    @Bindable var manager: CompanionManager
    var onOpenPanel: ((CompanionTool) -> Void)?

    var body: some View {
        ZStack {
            Color.clear

            if manager.isVisible {
                ToolbarView(manager: manager, onOpenPanel: onOpenPanel)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .frame(width: 260, height: 60)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: manager.isVisible)
    }
}
