import SwiftUI

struct ChatView: View {
    var captureScreenOnAppear = false

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var streamingResponse = ""
    @State private var screenCaptured = false
    @FocusState private var isInputFocused: Bool

    private let gemma = GemmaClient.shared
    private let screenCapture = ScreenCaptureManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(gemma.isConnected ? Color.primary.opacity(0.5) : Color.primary.opacity(0.15))
                    .frame(width: 5, height: 5)

                Text("Genghsi")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                if !messages.isEmpty {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }

                        // Streaming response
                        if !streamingResponse.isEmpty {
                            MessageBubble(message: ChatMessage(role: "assistant", content: streamingResponse))
                                .id("streaming")
                        }

                        if gemma.isGenerating && streamingResponse.isEmpty {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.5)
                                Text("Thinking...")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .onChange(of: streamingResponse) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }

            Divider()
                .padding(.horizontal, 10)

            // Input
            HStack(spacing: 8) {
                TextField("Ask Genghsi...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                    .disabled(gemma.isGenerating)

                if gemma.isGenerating {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(inputText.isEmpty ? .quaternary : .primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .onAppear {
            isInputFocused = true
            Task { await gemma.checkConnection() }
            if captureScreenOnAppear && !screenCaptured {
                screenCaptured = true
                Task { await captureAndDescribe() }
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""
        streamingResponse = ""

        gemma.streamChat(
            messages: messages,
            systemPrompt: Prompts.companion,
            onToken: { token in
                streamingResponse += token
            },
            onComplete: {
                if !streamingResponse.isEmpty {
                    messages.append(ChatMessage(role: "assistant", content: streamingResponse))
                }
                streamingResponse = ""
            },
            onError: { error in
                messages.append(ChatMessage(role: "assistant", content: "⚠️ \(error.localizedDescription). Make sure Docker Desktop is running with Model Runner enabled."))
                streamingResponse = ""
            }
        )
    }

    private func captureAndDescribe() async {
        do {
            let base64 = try await screenCapture.captureScreen()
            let userMessage = ChatMessage(role: "user", content: "[Screenshot captured] Describe what you see on my screen.")
            messages.append(userMessage)
            streamingResponse = ""

            gemma.streamChat(
                messages: messages,
                systemPrompt: Prompts.companion + "\n\nThe user has shared a screenshot (base64 JPEG, \(base64.count) chars). Describe what you see and offer to help.",
                onToken: { token in streamingResponse += token },
                onComplete: {
                    if !streamingResponse.isEmpty {
                        messages.append(ChatMessage(role: "assistant", content: streamingResponse))
                    }
                    streamingResponse = ""
                },
                onError: { error in
                    messages.append(ChatMessage(role: "assistant", content: "Could not read screen: \(error.localizedDescription)"))
                    streamingResponse = ""
                }
            )
        } catch {
            messages.append(ChatMessage(role: "assistant", content: "Screen capture failed: \(error.localizedDescription). Check that screen recording permission is granted in System Settings > Privacy & Security."))
        }
    }

    private func clearChat() {
        messages.removeAll()
        streamingResponse = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            Text(message.content)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isUser ? Color.primary.opacity(0.85) : Color.primary.opacity(0.05))
                )
                .foregroundStyle(isUser ? Color(.windowBackgroundColor) : .primary)
                .textSelection(.enabled)

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
