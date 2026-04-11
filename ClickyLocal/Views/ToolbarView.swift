import SwiftUI

struct ToolbarView: View {
    @Bindable var manager: CompanionManager
    var onOpenPanel: ((CompanionTool) -> Void)?

    @State private var breathe = false

    private let gemma = GemmaClient.shared

    var body: some View {
        HStack(spacing: 0) {
            // Brand dot — doubles as connection indicator
            brandDot
                .padding(.leading, 12)
                .padding(.trailing, 10)

            // Divider
            Divider()
                .frame(height: 16)
                .opacity(0.3)

            // Tab buttons
            HStack(spacing: 2) {
                ForEach(CompanionTool.allCases) { tool in
                    tabButton(for: tool)
                }
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 38)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: - Brand Dot

    private var brandDot: some View {
        ZStack {
            // Breathing halo
            Circle()
                .fill(dotColor.opacity(0.25))
                .frame(width: 14, height: 14)
                .scaleEffect(breathe ? 1.4 : 1.0)
                .opacity(breathe ? 0.6 : 0.3)

            // Core dot
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
        }
        .frame(width: 18, height: 18)
        .help(gemma.isConnected ? "Connected to Gemma" : "Gemma offline — start Docker Desktop")
    }

    private var dotColor: Color {
        gemma.isConnected
            ? Color(red: 0.71, green: 0.83, blue: 0.95)
            : Color.orange
    }

    // MARK: - Tab Buttons

    private func tabButton(for tool: CompanionTool) -> some View {
        TabButtonView(
            tool: tool,
            isActive: manager.selectedTool == tool,
            action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    manager.selectTool(tool)
                }
                onOpenPanel?(tool)
            }
        )
    }
}

// MARK: - Tab Button

private struct TabButtonView: View {
    let tool: CompanionTool
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tool.icon)
                    .font(.system(size: 11))

                Text(tool.rawValue)
                    .font(.system(size: 11, weight: isActive ? .semibold : .medium))
            }
            .foregroundStyle(isActive ? .primary : (isHovered ? .primary : .secondary))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? Color.primary.opacity(0.08) : (isHovered ? Color.primary.opacity(0.04) : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
