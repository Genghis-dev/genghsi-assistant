import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: String
    let content: String

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case role, content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

@Observable
final class GemmaClient {
    static let shared = GemmaClient()

    private let baseURL = "http://localhost:12434/engines/v1"
    private let model = "ai/gemma4"

    var isConnected = false
    var isGenerating = false

    private init() {
        Task { await checkConnection() }
    }

    func checkConnection() async {
        // Try a lightweight request to see if Docker Model Runner is up
        guard let url = URL(string: "\(baseURL)/models") else {
            isConnected = false
            return
        }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            isConnected = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            isConnected = false
        }
    }

    /// Send a chat request and stream the response token-by-token
    func streamChat(
        messages: [ChatMessage],
        systemPrompt: String? = nil,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else { return }

        var allMessages: [[String: String]] = []

        if let system = systemPrompt {
            allMessages.append(["role": "system", "content": system])
        }

        for msg in messages {
            allMessages.append(["role": msg.role, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "stream": true,
            "max_tokens": 2048,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        isGenerating = true

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isGenerating = false
            }

            if let error {
                DispatchQueue.main.async { onError(error) }
                return
            }

            guard let data, let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { onComplete() }
                return
            }

            // Parse SSE lines
            let lines = text.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data: ") else { continue }
                let jsonStr = String(trimmed.dropFirst(6))

                if jsonStr == "[DONE]" { break }

                guard let jsonData = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any],
                      let content = delta["content"] as? String else { continue }

                DispatchQueue.main.async {
                    onToken(content)
                }
            }

            DispatchQueue.main.async { onComplete() }
        }

        task.resume()
    }

    /// Non-streaming single response (for todo extraction, rewriting, etc.)
    func chat(messages: [ChatMessage], systemPrompt: String? = nil) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw GemmaError.invalidURL
        }

        var allMessages: [[String: String]] = []

        if let system = systemPrompt {
            allMessages.append(["role": "system", "content": system])
        }

        for msg in messages {
            allMessages.append(["role": msg.role, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "stream": false,
            "max_tokens": 2048,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GemmaError.invalidResponse
        }

        return content
    }
}

enum GemmaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case notConnected

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Could not parse response from Gemma"
        case .notConnected: return "Docker Model Runner is not running"
        }
    }
}
