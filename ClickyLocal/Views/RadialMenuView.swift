import SwiftUI

struct RadialMenuView: View {
    @Bindable var manager: CompanionManager
    let radius: CGFloat = 80

    var body: some View {
        ZStack {
            ForEach(Array(CompanionTool.allCases.enumerated()), id: \.element.id) { index, tool in
                let angle = angleForIndex(index, total: CompanionTool.allCases.count)

                RadialSliceView(tool: tool, isSelected: manager.selectedTool == tool)
                    .offset(
                        x: cos(angle) * radius,
                        y: sin(angle) * radius
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            manager.selectTool(tool)
                        }
                    }
            }
        }
        .frame(width: radius * 2 + 60, height: radius * 2 + 60)
    }

    private func angleForIndex(_ index: Int, total: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2  // start from top
        let step = (2 * .pi) / CGFloat(total)
        return startAngle + step * CGFloat(index)
    }
}

struct RadialSliceView: View {
    let tool: CompanionTool
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                .overlay(
                    Circle()
                        .fill(isHovered || isSelected ? Color.primary.opacity(0.08) : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )

            Image(systemName: tool.icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(isHovered || isSelected ? .primary : .secondary)
        }
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
