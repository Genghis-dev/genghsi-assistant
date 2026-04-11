import SwiftUI

struct UnifiedPanelView: View {
    var panelState: PanelState

    @Namespace private var tabIndicator

    var body: some View {
        VStack(spacing: 0) {
            // Title bar area — native traffic lights float over this region
            Color.clear
                .frame(height: 28)

            // Tab bar
            tabBar

            Divider()
                .opacity(0.3)

            // Content area
            contentArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(CompanionTool.allCases) { tool in
                tabItem(for: tool)
            }
        }
        .frame(height: 32)
    }

    private func tabItem(for tool: CompanionTool) -> some View {
        let isActive = panelState.activeTab == tool

        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                panelState.switchTo(tool)
            }
        }) {
            VStack(spacing: 0) {
                Text(tool.rawValue)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)

                // Active indicator underline
                if isActive {
                    Capsule()
                        .fill(Color(red: 0.71, green: 0.83, blue: 0.95))
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "tabIndicator", in: tabIndicator)
                } else {
                    Color.clear
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        Group {
            switch panelState.activeTab {
            case .chat:
                ChatView(panelState: panelState)
            case .notes:
                NotesPanelView(panelState: panelState)
            case .rewrite:
                RewriteView(panelState: panelState)
            }
        }
        .id(panelState.activeTab)
        .transition(tabTransition)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: panelState.activeTab)
    }

    private var tabTransition: AnyTransition {
        guard let prev = panelState.previousTab else {
            return .opacity
        }
        let movesRight = (panelState.activeTab.index > prev.index)
        return .asymmetric(
            insertion: .move(edge: movesRight ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: movesRight ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

// MARK: - Tool Index for directional transitions

private extension CompanionTool {
    var index: Int {
        switch self {
        case .chat: return 0
        case .notes: return 1
        case .rewrite: return 2
        }
    }
}
