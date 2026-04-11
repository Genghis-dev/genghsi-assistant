import SwiftUI

struct RewriteView: View {
    var panelState: PanelState = .shared

    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @State private var copiedFeedback = false
    @State private var savedFeedback = false
    @FocusState private var isInputFocused: Bool

    private let rewriter = Rewriter.shared
    private let store = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            if inputText.isEmpty && outputText.isEmpty {
                emptyState
            } else {
                contentView
            }
        }
        .onAppear {
            // Prefill from cross-tab or clipboard
            if let prefill = panelState.prefillText, !prefill.isEmpty {
                inputText = prefill
                panelState.prefillText = nil
            } else if inputText.isEmpty, let clipboard = NSPasteboard.general.string(forType: .string), !clipboard.isEmpty {
                inputText = clipboard
            }
            isInputFocused = true
        }
        .onChange(of: panelState.activeTab) {
            if panelState.activeTab == .rewrite, let prefill = panelState.prefillText, !prefill.isEmpty {
                inputText = prefill
                panelState.prefillText = nil
                isInputFocused = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "pencil.and.outline")
                .font(.system(size: 24))
                .foregroundStyle(.quaternary)

            Text("Paste or type text to rewrite")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            Text("Tip: Rewrite directly from a note with ✏️")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = true
            // Force show the content view by adding a space that user can type into
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Input section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)

                    TextEditor(text: $inputText)
                        .font(.system(size: 12))
                        .lineSpacing(3)
                        .scrollContentBackground(.hidden)
                        .focused($isInputFocused)
                        .frame(minHeight: 60, maxHeight: 120)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

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
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(inputText.isEmpty ? Color.primary.opacity(0.08) : Color.primary.opacity(0.85))
                    )
                    .foregroundStyle(inputText.isEmpty ? .secondary : Color(.windowBackgroundColor))
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || isProcessing)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                // Output section
                if !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rewritten")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)

                        Text(outputText)
                            .font(.system(size: 12))
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )

                        // Action buttons
                        HStack(spacing: 12) {
                            // Copy button
                            Button(action: copyResult) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                    Text(copiedFeedback ? "Copied" : "Copy")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(copiedFeedback ? .green : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)

                            // Save to Notes button
                            Button(action: saveToNotes) {
                                HStack(spacing: 4) {
                                    Image(systemName: savedFeedback ? "checkmark" : "note.text.badge.plus")
                                        .font(.system(size: 11))
                                    Text(savedFeedback ? "Saved" : "Save to Notes")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(savedFeedback ? .green : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    // MARK: - Actions

    private func rewrite() {
        isProcessing = true
        Task {
            if let result = await rewriter.rewrite(text: inputText) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    outputText = result
                }
            }
            isProcessing = false
        }
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)

        withAnimation(.easeOut(duration: 0.15)) { copiedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.15)) { copiedFeedback = false }
        }
    }

    private func saveToNotes() {
        _ = store.createNote(content: outputText)

        withAnimation(.easeOut(duration: 0.15)) { savedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.15)) { savedFeedback = false }
        }
    }
}
