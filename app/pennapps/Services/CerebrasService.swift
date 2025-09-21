//
//  CerebrasService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

// MARK: - Models for Cerebras API (OpenAI-compatible)
private struct ChatMessage: Codable {
    let role: String    // "system" | "user" | "assistant"
    let content: String
}

private struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let max_tokens: Int?
}

private struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Msg: Codable { let role: String; let content: String }
        let index: Int
        let message: Msg
        let finish_reason: String?
    }
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
}

// MARK: - Service
final class CerebrasService: ObservableObject {
    private let apiKey: String?
    private let config = Config.shared

    // Endpoint: Cerebras uses an OpenAI-compatible endpoint
    // See: https://api.cerebras.ai/v1/chat/completions
    private let endpoint = URL(string: "https://api.cerebras.ai/v1/chat/completions")!

    init() {
        self.apiKey = config.getCerebrasAPIKey()
        print("🤖 Cerebras Service initialized - Key available: \(config.hasCerebrasKey())")
    }

    // MARK: - Public API

    /// Returns an integer 0...5 where 0 = none, 5 = max photosensitivity risk
    func analyzeSkinConditionSeverity(conditions: String) async throws -> Int {
        let cleaned = conditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // quick outs
        if cleaned.isEmpty { return 0 }
        let noneWords = ["none","n/a","na","no","nothing","normal","normal skin","no conditions","none specified","not applicable"]
        if noneWords.contains(where: { cleaned == $0 || cleaned.contains($0) }) { return 0 }

        guard let apiKey, config.hasCerebrasKey(), apiKey.isEmpty == false else {
            print("⚠️ Missing/placeholder Cerebras key. Using fallback rules.")
            return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
        }

        // Ask the model to output ONLY an integer 0-5
        let system = """
        You are a medical-risk classifier (NOT a doctor). Given a short string of skin conditions,
        return ONLY an integer 0-5 indicating sun/UV photosensitivity risk:
        0 none/minimal, 1 low, 2 mild, 3 moderate, 4 high, 5 very high.
        No words, no units, no explanation—just the digit.
        """
        let user = "Conditions: \(conditions)"

        do {
            let content = try await chatCompletion(
                apiKey: apiKey,
                messages: [
                    ChatMessage(role: "system", content: system),
                    ChatMessage(role: "user", content: user)
                ],
                // A small max_tokens is fine because we expect a single token/digit
                temperature: 0.0,
                maxTokens: 8
            )

            // Parse first integer in the response
            if let intVal = extractFirstInt(in: content), (0...5).contains(intVal) {
                return intVal
            } else {
                print("⚠️ Unexpected LLM output for severity: \(content). Falling back.")
                return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
            }
        } catch {
            print("❌ Cerebras severity call failed: \(error.localizedDescription). Falling back.")
            return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
        }
    }

    /// Summarize a user's profile & give guidance. Uses API if available; else fallback text.
    func generateUserSummary(
        age: Int,
        skinConditions: [String],
        baselineRiskScore: Double? = nil,
        baselineRiskCategory: String? = nil
    ) async throws -> String {

        guard let apiKey, config.hasCerebrasKey(), apiKey.isEmpty == false else {
            return generateFallbackSummary(
                age: age,
                skinConditions: skinConditions,
                baselineRiskScore: baselineRiskScore,
                baselineRiskCategory: baselineRiskCategory
            )
        }

        let baselineText: String = {
            if let c = baselineRiskCategory, !c.isEmpty { return "baseline risk category: \(c)" }
            if let s = baselineRiskScore { return "baseline risk score: \(String(format: "%.2f", s))" }
            return "baseline risk unknown"
        }()

        let system = """
        You are a concise sun-safety coach. Write a short, direct paragraph for a mobile app.
        Include: age impact, conditions impact, and clear sunscreen/clothing/shade advice.
        Avoid disclaimers and medical diagnoses. Keep it to ~4 sentences.
        """
        let user = """
        age: \(age)
        conditions: \(skinConditions.joined(separator: ", ").ifEmpty("none"))
        \(baselineText)
        """

        do {
            let content = try await chatCompletion(
                apiKey: apiKey,
                messages: [
                    ChatMessage(role: "system", content: system),
                    ChatMessage(role: "user", content: user)
                ],
                temperature: 0.3,
                maxTokens: 260
            )
            // Basic guard against super long responses
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("❌ Cerebras summary call failed: \(error.localizedDescription). Using fallback.")
            return generateFallbackSummary(
                age: age,
                skinConditions: skinConditions,
                baselineRiskScore: baselineRiskScore,
                baselineRiskCategory: baselineRiskCategory
            )
        }
    }

    // MARK: - Low-level HTTP

    private func chatCompletion(
        apiKey: String,
        messages: [ChatMessage],
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Cerebras uses Bearer like OpenAI
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Choose any available Cerebras model; llama3.1-8b is widely enabled.
        let body = ChatRequest(
            model: "llama3.1-8b",
            messages: messages,
            temperature: temperature,
            max_tokens: maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CerebrasError.apiError
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw CerebrasError.invalidResponse
        }
        return content
    }

    // MARK: - Fallbacks (your existing logic)

    private func fallbackAnalyzeSkinConditionSeverity(conditions: String) -> Int {
        let c = conditions.lowercased()
        if c.contains("lupus") || c.contains("photosensitive") { return 5 }
        else if c.contains("melasma") || c.contains("vitiligo") { return 4 }
        else if c.contains("rosacea") || c.contains("psoriasis") { return 3 }
        else if c.contains("eczema") || c.contains("dermatitis") { return 2 }
        else if c.contains("acne") || c.contains("sensitive") { return 1 }
        else { return 0 }
    }

    private func generateFallbackSummary(
        age: Int,
        skinConditions: [String],
        baselineRiskScore: Double? = nil,
        baselineRiskCategory: String? = nil
    ) -> String {

        let baselineInfo: String
        if let c = baselineRiskCategory, !c.isEmpty {
            baselineInfo = "The baseline risk score is \(c).\n\n"
        } else if let s = baselineRiskScore {
            baselineInfo = "The baseline risk score is \(String(format: "%.2f", s)).\n\n"
        } else {
            baselineInfo = ""
        }

        let conditionsText = skinConditions.isEmpty ? "no significant skin conditions" : skinConditions.joined(separator: ", ")

        let ageImpact: String
        switch age {
        case ..<18: ageImpact = "young age contributes to lower risk"
        case ..<30: ageImpact = "age contributes moderately to risk"
        case ..<50: ageImpact = "age increases baseline risk"
        default:    ageImpact = "age significantly increases risk"
        }

        let recs: String
        if skinConditions.contains(where: { $0.lowercased().contains("lupus") }) {
            recs = "Maximum protection required: SPF 50+, protective clothing, wide-brim hat, sunglasses, and minimize sun exposure."
        } else if skinConditions.contains(where: { $0.lowercased().contains("melasma") }) {
            recs = "Use SPF 50+, protective clothing, wide-brim hat, and avoid peak sun hours."
        } else if skinConditions.contains(where: { $0.lowercased().contains("rosacea") }) {
            recs = "Use SPF 30–50, protective clothing, and limit sun exposure."
        } else {
            recs = "Use SPF 30+ broad-spectrum sunscreen and seek shade during peak hours."
        }

        return """
        \(baselineInfo)Your skin profile shows you have \(conditionsText) at age \(age). These factors affect your risk through \(ageImpact).

        Advice: \(recs) Reapply every 2 hours and seek shade during peak UV hours (10 AM–4 PM).
        """
    }

    // MARK: - Helpers

    private func extractFirstInt(in text: String) -> Int? {
        let digits = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Grab first run of digits in the string
        if let match = digits.range(of: #"\d+"#, options: .regularExpression) {
            return Int(digits[match])
        }
        return nil
    }
}

// MARK: - Errors
enum CerebrasError: Error {
    case invalidURL
    case apiError
    case parseError
    case invalidResponse

    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .apiError: return "API request failed"
        case .parseError: return "Failed to parse response"
        case .invalidResponse: return "Invalid response content"
        }
    }
}

// MARK: - Tiny extension
private extension String {
    func ifEmpty(_ replacement: String) -> String {
        isEmpty ? replacement : self
    }
}
