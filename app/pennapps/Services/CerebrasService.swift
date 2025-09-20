//
//  CerebrasService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

// MARK: - Secrets loader (editor-agnostic)
// Reads API key from (1) Environment Variable, then (2) Info.plist, then optional AppSecrets.plist in bundle.
// No separate Config.swift is required.
private enum Secrets {
    static var cerebrasAPIKey: String? {
        // 1) Xcode Scheme / Process env (useful for local dev & tests)
        if let env = ProcessInfo.processInfo.environment["CEREBRAS_API_KEY"], !env.isEmpty {
            return env
        }
        // 2) Info.plist (works in Xcode, VS Code, and on device)
        if let key = Bundle.main.object(forInfoDictionaryKey: "CEREBRAS_API_KEY") as? String, !key.isEmpty {
            return key
        }
        // 3) Optional AppSecrets.plist (if you prefer to .gitignore real secrets)
        if let url = Bundle.main.url(forResource: "AppSecrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = dict["CEREBRAS_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }
        return nil
    }

    static var hasValidCerebrasKey: Bool {
        guard let k = cerebrasAPIKey else { return false }
        return !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func status() -> String {
        hasValidCerebrasKey ? "✅ CEREBRAS_API_KEY present" : "⚠️ CEREBRAS_API_KEY missing"
    }
}

/// Service for interacting with Cerebras AI API
class CerebrasService: ObservableObject {

    private let baseURL = "https://api.cerebras.ai/v1/chat/completions"

    private var apiKey: String? {
        return Secrets.cerebrasAPIKey
    }

    // MARK: - Skin Condition Analysis

    /// Analyze skin conditions and return UV sensitivity severity score (0-5)
    func analyzeSkinConditionSeverity(conditions: String) async throws -> Int {
        print("🔍 Analyzing skin conditions: '\(conditions)'")

        let cleanedConditions = conditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Handle empty or "none" conditions immediately
        if cleanedConditions.isEmpty {
            print("✅ No skin conditions provided - returning severity 0")
            return 0
        }

        // Check for common "none" variations
        let noneVariations = [
            "none", "n/a", "na", "no", "nothing", "normal", "normal skin",
            "no conditions", "none specified", "not applicable"
        ]

        for variation in noneVariations {
            if cleanedConditions == variation || cleanedConditions.contains(variation) {
                print("✅ User indicated no skin conditions ('\(conditions)') - returning severity 0")
                return 0
            }
        }

        // Check if API key is properly configured
        guard let apiKey = apiKey else {
            print("⚠️ Cerebras API key not configured. Using default severity score of 1.")
            print("💡 Set CEREBRAS_API_KEY in your Scheme env, Info.plist, or AppSecrets.plist")
            return 1 // Default severity for testing
        }

        guard Secrets.hasValidCerebrasKey else {
            print("⚠️ Cerebras API key appears to be a placeholder. Using default severity score of 1.")
            return 1
        }

        let prompt = """
        Analyze the following skin conditions and rate the overall UV sensitivity risk on a scale of 0-5:

        0 = No additional UV risk (normal skin, "none", "n/a", no conditions)
        1 = Minimal UV risk (minor conditions)
        2 = Low UV risk (mild sensitivity)
        3 = Moderate UV risk (needs standard protection)
        4 = High UV risk (needs extra protection)
        5 = Severe UV risk (very photosensitive, burns easily)

        Skin conditions: "\(conditions)"

        IMPORTANT: If the user wrote "none", "n/a", "normal", "no conditions", or similar, return 0.

        Consider these conditions for higher scores:
        - Acne medications (tretinoin, isotretinoin) = higher risk
        - Eczema/dermatitis = compromised skin barrier
        - Psoriasis = often on photosensitizing treatments
        - Rosacea = sun triggers flares
        - Melasma = worsens with UV
        - Lupus = severe photosensitivity
        - Vitiligo = depigmented areas burn easily
        - Any photosensitive medications
        - History of skin cancer

        Respond with ONLY a single number (0-5).
        """

        let requestBody: [String: Any] = [
            "model": "llama3.1-8b",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 10,
            "temperature": 0.1
        ]

        guard let url = URL(string: baseURL) else {
            throw CerebrasError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CerebrasError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw CerebrasError.parseError
        }

        let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let severity = Int(cleanedContent), severity >= 0, severity <= 5 else {
            return 1 // Default to minimal risk if parsing fails
        }

        print("✅ Cerebras Analysis: '\(conditions)' → Severity: \(severity)")
        return severity
    }

    // MARK: - User Summary Generation

    func generateUserSummary(age: String, skinConditions: String, severityScore: Int) async throws -> String {
        // Check if API key is properly configured
        guard let apiKey = apiKey else {
            print("⚠️ Cerebras API key not configured. Returning fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore)
        }

        guard Secrets.hasValidCerebrasKey else {
            print("⚠️ Cerebras API key appears to be a placeholder. Returning fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore)
        }

        let prompt = """
        Generate a personalized skincare and sun protection summary for this user:

        Age: \(age)
        Skin Conditions: \(skinConditions.isEmpty ? "None" : skinConditions)
        UV Risk Score: \(severityScore)/5

        Provide:
        1. Brief analysis of their UV risk level
        2. Specific sunscreen recommendations (SPF level)
        3. Additional protection tips
        4. Skincare considerations for their age and conditions

        Keep it concise, friendly, and actionable. Limit to 150-200 words.
        """

        let requestBody: [String: Any] = [
            "model": "llama3.1-8b",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]

        guard let url = URL(string: baseURL) else {
            throw CerebrasError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CerebrasError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw CerebrasError.parseError
        }

        let summary = content.trimmingCharacters(in: .whitespacesAndNewlines)
        print("✅ Cerebras Summary Generated for age \(age), conditions: \(skinConditions)")
        return summary
    }

    // MARK: - Fallback Methods

    private func generateFallbackSummary(age: String, skinConditions: String, severityScore: Int) -> String {
        let ageInt = Int(age) ?? 0
        let cleanedConditions = skinConditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Determine age group
        let ageGroup: String
        let ageSpecificAdvice: String

        switch ageInt {
        case 0...12:
            ageGroup = "child"
            ageSpecificAdvice = "Children's skin is especially sensitive. Use gentle, mineral-based sunscreens and ensure protective clothing."
        case 13...19:
            ageGroup = "teenager"
            ageSpecificAdvice = "Teen skin may be oily or acne-prone. Use non-comedogenic sunscreens and establish good sun protection habits."
        case 20...35:
            ageGroup = "young adult"
            ageSpecificAdvice = "This is the perfect time to establish preventive skincare habits to maintain healthy skin long-term."
        case 36...55:
            ageGroup = "adult"
            ageSpecificAdvice = "Focus on anti-aging prevention and consistent sun protection to prevent premature aging and skin damage."
        default:
            ageGroup = "mature adult"
            ageSpecificAdvice = "Mature skin requires extra gentle care and strong sun protection to prevent age spots and further damage."
        }

        // Determine condition-specific advice
        let conditionAdvice: String
        if cleanedConditions.contains("acne") || cleanedConditions.contains("pimple") {
            conditionAdvice = "For acne-prone skin, use non-comedogenic sunscreens and avoid oil-based products."
        } else if cleanedConditions.contains("eczema") || cleanedConditions.contains("dermatitis") {
            conditionAdvice = "Eczema-prone skin needs gentle, fragrance-free products and extra moisturizing."
        } else if cleanedConditions.contains("rosacea") {
            conditionAdvice = "Rosacea is sun-sensitive. Use mineral sunscreens and avoid harsh ingredients."
        } else if cleanedConditions.contains("sensitive") {
            conditionAdvice = "Sensitive skin benefits from mineral sunscreens with zinc oxide or titanium dioxide."
        } else {
            conditionAdvice = "Maintain a consistent skincare routine with gentle cleansing and regular moisturizing."
        }

        // Generate SPF recommendation based on severity
        let spfRecommendation: String
        switch severityScore {
        case 0...1:
            spfRecommendation = "SPF 30+ daily"
        case 2...3:
            spfRecommendation = "SPF 50+ daily"
        case 4...5:
            spfRecommendation = "SPF 50+ with frequent reapplication and protective clothing"
        default:
            spfRecommendation = "SPF 30+ daily"
        }

        return """
        📊 Your Personalized Summary

        Risk Level: \(UVRiskLevel(rawValue: severityScore)?.description ?? "Moderate")

        🧴 Recommended Protection: \(spfRecommendation)

        👤 For your age group (\(ageGroup)): \(ageSpecificAdvice)

        🎯 Skin-specific tip: \(conditionAdvice)

        💡 Remember: Reapply sunscreen every 2 hours, wear protective clothing, and seek shade during peak sun hours (10 AM - 4 PM).
        """
    }
}

// MARK: - Error Handling

enum CerebrasError: LocalizedError {
    case invalidURL
    case apiError
    case parseError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Cerebras API URL"
        case .apiError:
            return "Cerebras API request failed"
        case .parseError:
            return "Failed to parse Cerebras API response"
        case .missingAPIKey:
            return "Cerebras API key not configured"
        }
    }
}
