import Foundation

@Observable
final class Rewriter {
    static let shared = Rewriter()

    var isRewriting = false
    var lastResult: String?

    private let gemma = GemmaClient.shared
    private init() {}

    func rewrite(text: String, styleSamples: [String] = []) async -> String? {
        guard !text.isEmpty else { return nil }

        isRewriting = true
        defer { isRewriting = false }

        var prompt = Prompts.rewriter
        if !styleSamples.isEmpty {
            prompt += "\n\nStyle samples:\n"
            for (i, sample) in styleSamples.enumerated() {
                prompt += "\n--- Sample \(i + 1) ---\n\(sample)\n"
            }
        }

        do {
            let result = try await gemma.chat(
                messages: [ChatMessage(role: "user", content: "Rewrite this:\n\n\(text)")],
                systemPrompt: prompt
            )
            lastResult = result
            return result
        } catch {
            print("Rewrite failed: \(error)")
            return nil
        }
    }
}
