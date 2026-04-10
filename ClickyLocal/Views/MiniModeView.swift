import SwiftUI

struct MiniModeView: View {
    @Bindable var manager: CompanionManager

    var body: some View {
        HStack(spacing: 8) {
            // Quick chat
            Button(action: { manager.selectTool(.chat) }) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 12)

            // Quick note button
            Button(action: { manager.selectTool(.notes) }) {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 12)

            // Expand to full
            Button(action: { manager.toggleRadialMenu() }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}
