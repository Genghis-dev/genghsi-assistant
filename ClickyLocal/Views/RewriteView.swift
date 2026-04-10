import SwiftUI

struct RewriteView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool

    private let rewriter = Rewriter.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Rewrite")
                    .font(.system(size: 13, weight: .medium))
                Spacer()

                if !outputText.isEmpty {
                    Button(action: copyResult) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy result")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            // Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Original")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)

                TextEditor(text: $inputText)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .frame(maxHeight: 100)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Rewrite button
            Button(action: rewrite) {
                HStack(spacing: 6) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    Text(isProcessing ? "Rewriting..." : "Rewrite in my tone")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(inputText.isEmpty ? Color.primary.opacity(0.08) : Color.primary.opacity(0.85))
                )
                .foregroundStyle(inputText.isEmpty ? .secondary : Color(.windowBackgroundColor))
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || isProcessing)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Output
            if !outputText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rewritten")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)

                    Text(outputText)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            Spacer()
        }
        .frame(width: 280, height: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .onAppear {
            // Auto-populate from clipboard
            if let clipboard = NSPasteboard.general.string(forType: .string), !clipboard.isEmpty {
                inputText = clipboard
            }
            isInputFocused = true
        }
    }

    private func rewrite() {
        isProcessing = true
        Task {
            if let result = await rewriter.rewrite(text: inputText) {
                outputText = result
            }
            isProcessing = false
        }
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
    }
}
