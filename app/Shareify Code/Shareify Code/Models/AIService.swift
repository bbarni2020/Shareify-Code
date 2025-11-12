import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
    let model: String?
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case messages
        case model
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatChoice: Codable {
    let message: ChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct ChatResponse: Codable {
    let id: String?
    let choices: [ChatChoice]
    let model: String?
}

struct AIModel: Codable, Identifiable {
    let id: String
    let object: String?
    let created: Int?
    let ownedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
    }
}

struct ModelsResponse: Codable {
    let data: [AIModel]
}

enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

final class AIService {
    static let shared = AIService()
    
    private let baseURL = "https://ai.hackclub.com"
    private let session: URLSession
    private let systemPrompt: String
    private func resolveAPIKey() -> String {
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String, !plistKey.isEmpty { return plistKey }
        if let envKey = ProcessInfo.processInfo.environment["AI_API_KEY"], !envKey.isEmpty { return envKey }
        if let stored = KeychainHelper.get(service: "ShareifyAI", account: "hackclub_ai_api_key"), !stored.isEmpty { return stored }
        return ""
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        
        if let modelMDURL = Bundle.main.url(forResource: "model", withExtension: "md"),
           let instructions = try? String(contentsOf: modelMDURL, encoding: .utf8) {
            self.systemPrompt = instructions
        } else {
            self.systemPrompt = """
            You are SharAI, an AI assistant for Shareify Code, an iOS code editor.
            You help developers write, debug, and improve code.
            Be concise, helpful, and provide working code examples.
            Always explain your reasoning.
            """
        }
    }
    
    func fetchModels() async throws -> [AIModel] {
        #if DEBUG
        print("[AIService] build=DEBUG")
        #else
        print("[AIService] build=RELEASE")
        #endif
        let apiKey = resolveAPIKey()
        let plistKeyVal = Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String ?? "nil"
        let envKeyStatus = ProcessInfo.processInfo.environment["AI_API_KEY"] != nil ? "set" : "unset"
        print("[AIService] fetchModels preflight keyLen=\(apiKey.count) plistKey=\(plistKeyVal) envKey=\(envKeyStatus)")
        #if DEBUG
        assert(!apiKey.isEmpty, "AI_API_KEY is missing (set in xcconfig / Info.plist).")
        #endif
        guard !apiKey.isEmpty else {
            print("[AIService] fetchModels abort: missing key")
            throw AIServiceError.serverError("Missing AI API key")
        }
        guard let url = URL(string: "\(baseURL)/proxy/v1/models") else {
            throw AIServiceError.invalidURL
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            print("[AIService] fetchModels keyLen=\(apiKey.count) url=\(url.absoluteString)")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AIServiceError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
            return modelsResponse.data
        } catch let error as AIServiceError {
            throw error
        } catch let error as DecodingError {
            throw AIServiceError.decodingError(error)
        } catch {
            throw AIServiceError.networkError(error)
        }
    }
    
    func sendMessage(
        messages: [ChatMessage],
        model: String = "meta-llama/llama-4-maverick",
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> String {
        #if DEBUG
        print("[AIService] build=DEBUG")
        #else
        print("[AIService] build=RELEASE")
        #endif
        let apiKey = resolveAPIKey()
        let plistKeyVal = Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String ?? "nil"
        let envKeyStatus = ProcessInfo.processInfo.environment["AI_API_KEY"] != nil ? "set" : "unset"
        print("[AIService] sendMessage preflight keyLen=\(apiKey.count) plistKey=\(plistKeyVal) envKey=\(envKeyStatus)")
        #if DEBUG
        assert(!apiKey.isEmpty, "AI_API_KEY is missing (set in xcconfig / Info.plist).")
        #endif
        guard !apiKey.isEmpty else {
            print("[AIService] sendMessage abort: missing key")
            throw AIServiceError.serverError("Missing AI API key")
        }
        guard let url = URL(string: "\(baseURL)/proxy/v1/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var fullMessages = [ChatMessage(role: "system", content: systemPrompt)]
        fullMessages.append(contentsOf: messages)
        
        let chatRequest = ChatRequest(
            messages: fullMessages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
            print("[AIService] sendMessage keyLen=\(apiKey.count) model=\(model) messages=\(messages.count) bodyBytes=\(request.httpBody?.count ?? 0) url=\(url.absoluteString)")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.serverError("Status \(httpResponse.statusCode): \(errorMessage)")
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            guard let firstChoice = chatResponse.choices.first else {
                throw AIServiceError.invalidResponse
            }
            
            return firstChoice.message.content
        } catch let error as AIServiceError {
            throw error
        } catch let error as DecodingError {
            throw AIServiceError.decodingError(error)
        } catch {
            throw AIServiceError.networkError(error)
        }
    }
}
