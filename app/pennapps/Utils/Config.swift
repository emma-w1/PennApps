import Foundation
import SwiftUI

/// Comprehensive configuration manager for app settings and API keys
/// makes sensitive .env file available to app parts
class Config {
    static let shared = Config()
    
    private var environment: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    /// Load environment variables from .env file
    private func loadEnvironmentVariables() {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found in bundle")
            loadFromProcessEnvironment()
            return
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath)
            parseEnvironmentContent(envContent)
        } catch {
            print("⚠️ Failed to read .env file: \(error)")
            loadFromProcessEnvironment()
        }
    }
    
    /// Parse .env file content
    private func parseEnvironmentContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Parse KEY=VALUE format
            let components = trimmedLine.components(separatedBy: "=")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                environment[key] = value
            }
        }
        
        print("✅ Loaded \(environment.count) environment variables from .env file")
    }
    
    /// Fallback to process environment variables
    private func loadFromProcessEnvironment() {
        environment["GEMINI_API_KEY"] = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        
        print("📱 Loaded environment variables from process environment")
    }
    
    
    /// Securely get API key with validation
    private func getAPIKey(_ key: String) -> String? {
        let value = environment[key]
        
        // Validate that it's not a placeholder
        if let value = value,
           !value.isEmpty,
           !value.contains("your_") && !value.contains("_here") {
            return value
        }
        
        return nil
    }
        
    /// Get Gemini API Key
    var geminiAPIKey: String? {
        return getAPIKey("GEMINI_API_KEY")
    }
    
    /// Check if Gemini key is properly configured
    var hasValidGeminiKey: Bool {
        return geminiAPIKey != nil
    }
        
    /// Initialize app configurations
    func initializeApp() {
        print("🚀 Initializing app configuration...")
        print(getConfigurationStatus())
        print("✅ App configuration completed")
    }
        
    /// Get comprehensive configuration status for debugging
    func getConfigurationStatus() -> String {
        var status = "🔐 App Configuration Status:\n"
        
        // Gemini Status
        if let key = geminiAPIKey {
            let maskedKey = String(key.prefix(10)) + "..." + String(key.suffix(4))
            status += "✅ Gemini API Key: \(maskedKey)\n"
        } else {
            status += "❌ Gemini API Key: Not configured\n"
        }
        
        return status
    }
    
    /// Get safe status for production logging
    func getSafeStatus() -> String {
        return """
        🔐 Configuration Status:
        Gemini: \(hasValidGeminiKey ? "✅ Ready" : "❌ Missing")
        """
    }
    
    /// Test function to verify Gemini integration
    func testGeminiIntegration() async {
        print("🧪 Testing Gemini Integration...")
        print(getConfigurationStatus())
        
        let gemini = GeminiService()
        
        // Test cases
        let testCases = [
            "none",
            "acne",
            "eczema, sensitive skin",
            "lupus, photosensitive"
        ]
        
        for testCase in testCases {
            do {
                let result = try await gemini.analyzeSkinConditionSeverity(conditions: testCase)
                print("✅ Test: '\(testCase)' → Severity: \(result)")
            } catch {
                print("❌ Test failed for '\(testCase)': \(error.localizedDescription)")
            }
        }
    }
}

/// Gemini service using the unified configuration
class GeminiService: ObservableObject {
    private let apiKey: String?
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
    private let config = Config.shared
    
    init() {
        self.apiKey = config.geminiAPIKey
        print("🤖 Gemini Service initialized - Key available: \(config.hasValidGeminiKey)")
    }
    
    func analyzeSkinConditionSeverity(conditions: String) async throws -> Int {
        let cleanedConditions = conditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Handle empty or "none" cases immediately
        if cleanedConditions.isEmpty {
            print("✅ No skin conditions provided - returning severity 0")
            return 0
        }
        
        // Check for common "none" variations
        let noneVariations = ["none", "n/a", "na", "no", "nothing", "normal", "normal skin", "no conditions", "none specified", "not applicable"]
        
        for variation in noneVariations {
            if cleanedConditions == variation || cleanedConditions.contains(variation) {
                print("✅ User indicated no skin conditions ('\(conditions)') - returning severity 0")
                return 0
            }
        }
        
        // Check if API key is properly configured
        guard let apiKey = apiKey else {
            print("⚠️ Gemini API key not configured. Using default severity score of 1.")
            print("💡 Please set GEMINI_API_KEY in your .env file")
            return 1 // Default severity for testing
        }
        
        guard config.hasValidGeminiKey else {
            print("⚠️ Gemini API key appears to be a placeholder. Using default severity score of 1.")
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
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 10,
                "temperature": 0.1
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.apiError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        let cleanedContent = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let severity = Int(cleanedContent), severity >= 0, severity <= 5 else {
            return 1 // Default to minimal risk if parsing fails
        }
        
        print("✅ Gemini Analysis: '\(conditions)' → Severity: \(severity)")
        return severity
    }
    
    func generateUserSummary(age: String, skinConditions: String, severityScore: Int, riskScoreBaseline: String?, skinToneIndex: Int) async throws -> String {
        // Check if API key is properly configured
        guard let apiKey = apiKey else {
            print("⚠️ Gemini API key not configured. Using fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore, riskScoreBaseline: riskScoreBaseline, skinToneIndex: skinToneIndex)
        }
        
        guard config.hasValidGeminiKey else {
            print("⚠️ Gemini API key appears to be a placeholder. Using fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore, riskScoreBaseline: riskScoreBaseline, skinToneIndex: skinToneIndex)
        }
        
        let prompt = """
        Create a personalized skin care summary using this EXACT format:
        
        "Your baseline risk score is [RISK_SCORE]. This is affected by your age ([AGE]), past skin history of [SKIN_CONDITIONS], and your [SKIN_TONE] skin. These factors affect your risk through [EXPLAIN_AGE_IMPACT], [EXPLAIN_CONDITION_IMPACT], and [EXPLAIN_SKIN_TONE_IMPACT]. 
        
        Advice: [SPECIFIC_PRODUCT_RECOMMENDATIONS]. [ADDITIONAL_PRACTICAL_TIPS]. 🌞"
        
        User Profile:
        - Age: \(age) years old
        - Skin Conditions: \(skinConditions)
        - Skin Tone Index: \(skinToneIndex) (1=very light, 6=very dark)
        - Baseline Risk Score: \(riskScoreBaseline ?? "Unknown")
        - UV Risk Score: \(severityScore)/5
        
        Fill in the brackets with appropriate information. Keep it to 1-2 short paragraphs maximum. Be specific about how each factor affects their risk.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 400,
                "temperature": 0.7
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.apiError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        let summary = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("✅ Gemini Summary Generated for age \(age), conditions: \(skinConditions)")
        return summary
    }
        
    private func generateFallbackSummary(age: String, skinConditions: String, severityScore: Int, riskScoreBaseline: String?, skinToneIndex: Int) -> String {
        let ageInt = Int(age) ?? 0
        let cleanedConditions = skinConditions.trimmingCharacters(in: .whitespacesAndNewlines)
        let baselineRisk = riskScoreBaseline ?? "Low (not yet calculated)"
        
        // Determine skin tone description
        let skinToneDescription: String
        switch skinToneIndex {
        case 1: skinToneDescription = "very light skin"
        case 2: skinToneDescription = "light skin"
        case 3: skinToneDescription = "medium-light skin"
        case 4: skinToneDescription = "medium skin"
        case 5: skinToneDescription = "medium-dark skin"
        case 6: skinToneDescription = "dark skin"
        default: skinToneDescription = "medium skin"
        }
        
        // Determine condition history
        let conditionHistory: String
        if cleanedConditions.isEmpty || cleanedConditions.lowercased().contains("none") || cleanedConditions.lowercased().contains("normal") {
            conditionHistory = "no significant skin conditions"
        } else {
            conditionHistory = cleanedConditions
        }
        
        // Determine age impact
        let ageImpact: String
        if ageInt < 18 {
            ageImpact = "young age contributes to lower risk"
        } else if ageInt < 30 {
            ageImpact = "age contributes moderately to risk"
        } else if ageInt < 50 {
            ageImpact = "age increases baseline risk"
        } else {
            ageImpact = "age significantly increases risk"
        }
        
        // Determine tone impact
        let toneImpact: String
        if skinToneIndex <= 2 {
            toneImpact = "lighter skin increases risk significantly"
        } else if skinToneIndex <= 4 {
            toneImpact = "moderate skin tone affects risk moderately"
        } else {
            toneImpact = "darker skin provides some natural protection"
        }
        
        // Determine product recommendations
        let productRec: String
        if skinToneIndex <= 2 && severityScore >= 3 {
            productRec = "SPF 50+ mineral sunscreen, UPF clothing"
        } else if skinToneIndex <= 3 {
            productRec = "SPF 30-50 broad-spectrum sunscreen"
        } else {
            productRec = "SPF 30+ broad-spectrum sunscreen"
        }
        
        // Generate shorter, formatted summary
        let summary = """
        Your baseline risk score is \(baselineRisk). This is affected by your age (\(ageInt)), past skin history of \(conditionHistory), and your \(skinToneDescription). These factors affect your risk through \(ageImpact), \(conditionHistory == "no significant skin conditions" ? "no conditions keeping risk lower" : "conditions increasing susceptibility"), and \(toneImpact). 
        
        Advice: \(productRec). Reapply every 2 hours and seek shade during peak UV hours (10 AM - 4 PM). 🌞
        """
        
        print("✅ Personalized Risk Summary Generated - Baseline: \(baselineRisk), Age: \(age), Conditions: \(skinConditions), Skin Tone: \(skinToneIndex)")
        return summary
    }
}

enum GeminiError: Error {
    case invalidURL
    case apiError
    case parseError
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .apiError:
            return "API request failed"
        case .parseError:
            return "Failed to parse response"
        case .invalidResponse:
            return "Invalid severity score received"
        }
    }
}
