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
    
    func generateUserSummary(age: String, skinConditions: String, severityScore: Int) async throws -> String {
        // Check if API key is properly configured
        guard let apiKey = apiKey else {
            print("⚠️ Gemini API key not configured. Using fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore)
        }
        
        guard config.hasValidGeminiKey else {
            print("⚠️ Gemini API key appears to be a placeholder. Using fallback summary.")
            return generateFallbackSummary(age: age, skinConditions: skinConditions, severityScore: severityScore)
        }
        
        let prompt = """
        Create a personalized skin care summary and UV protection tips for a user with the following profile:
        
        Age: \(age) years old
        Skin Conditions: \(skinConditions)
        UV Risk Score: \(severityScore)/5 (where 0=no risk, 5=severe risk)
        
        Please provide:
        1. A brief summary of their skin profile
        2. Specific UV protection recommendations based on their age and conditions
        3. 3-4 actionable skincare tips
        4. Any specific precautions for their skin conditions
        
        Keep the response under 300 words, friendly, and practical. Use emojis to make it engaging.
        Format with clear sections but don't use markdown headers.
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
        
    private func generateFallbackSummary(age: String, skinConditions: String, severityScore: Int) -> String {
        let ageInt = Int(age) ?? 0
        let cleanedConditions = skinConditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Determine age group
        let ageGroup: String
        let ageSpecificAdvice: String
        if ageInt < 18 {
            ageGroup = "teenager"
            ageSpecificAdvice = "🌟 As a teenager, your skin is still developing. Consistent sunscreen use now will prevent long-term damage and maintain healthy skin for decades to come!"
        } else if ageInt < 30 {
            ageGroup = "young adult"
            ageSpecificAdvice = "🌱 Your skin is in its prime! Establishing good habits now will keep your skin looking youthful and healthy as you age."
        } else if ageInt < 50 {
            ageGroup = "adult"
            ageSpecificAdvice = "💪 Prevention is key at this stage. Consistent protection will help maintain your skin's health and prevent premature aging."
        } else {
            ageGroup = "mature adult"
            ageSpecificAdvice = "✨ Your skin may be more sensitive now. Gentle, consistent care with proper UV protection is essential for maintaining skin health."
        }
        
        // Determine skin condition advice
        let conditionAdvice: String
        let conditionEmoji: String
        if cleanedConditions.isEmpty || cleanedConditions.contains("none") || cleanedConditions.contains("normal") {
            conditionAdvice = "Your skin appears to be in good condition. Continue with gentle care and consistent UV protection."
            conditionEmoji = "✨"
        } else if cleanedConditions.contains("acne") {
            conditionAdvice = "If you have acne-prone skin, choose non-comedogenic sunscreens and avoid heavy, oily formulas. Look for 'oil-free' and 'non-comedogenic' labels."
            conditionEmoji = "🩹"
        } else if cleanedConditions.contains("sensitive") || cleanedConditions.contains("irritat") {
            conditionAdvice = "For sensitive skin, choose mineral sunscreens with zinc oxide or titanium dioxide. Avoid chemical sunscreens that may cause irritation."
            conditionEmoji = "🤲"
        } else if cleanedConditions.contains("dry") {
            conditionAdvice = "Dry skin needs extra hydration. Choose sunscreens with moisturizing ingredients and apply moisturizer before sunscreen."
            conditionEmoji = "💧"
        } else if cleanedConditions.contains("oily") {
            conditionAdvice = "For oily skin, choose lightweight, matte-finish sunscreens. Look for 'oil-free' and 'mattifying' formulas."
            conditionEmoji = "🛢️"
        } else {
            conditionAdvice = "With your specific skin conditions, consult with a dermatologist for personalized sunscreen recommendations."
            conditionEmoji = "👨‍⚕️"
        }
        
        // Determine risk level advice
        let riskAdvice: String
        let riskEmoji: String
        switch severityScore {
        case 0:
            riskAdvice = "Your UV risk is minimal. Standard SPF 30+ sunscreen is sufficient for daily protection."
            riskEmoji = "🟢"
        case 1:
            riskAdvice = "You have a low UV risk. SPF 30+ sunscreen with broad-spectrum protection is recommended."
            riskEmoji = "🟡"
        case 2:
            riskAdvice = "You have a moderate UV risk. Use SPF 30-50+ sunscreen and reapply every 2 hours when outdoors."
            riskEmoji = "🟠"
        case 3:
            riskAdvice = "You have an elevated UV risk. Use SPF 50+ sunscreen, wear protective clothing, and seek shade during peak hours (10 AM - 4 PM)."
            riskEmoji = "🔴"
        case 4:
            riskAdvice = "You have a high UV risk. Use SPF 50+ sunscreen, wear UPF clothing, wide-brimmed hats, and avoid peak sun hours when possible."
            riskEmoji = "🔴"
        case 5:
            riskAdvice = "You have a very high UV risk. Use maximum protection: SPF 50+ sunscreen, UPF clothing, hats, sunglasses, and minimize sun exposure during peak hours."
            riskEmoji = "🔴"
        default:
            riskAdvice = "Use standard SPF 30+ sunscreen for daily protection."
            riskEmoji = "🟡"
        }
        
        // Generate personalized summary
        let summary = """
        🧴 **Your Personalized Skin Care Summary**
        
        **👤 Profile:** \(ageInt)-year-old \(ageGroup)
        **🎯 UV Risk Level:** \(severityScore)/5 \(riskEmoji)
        **💡 Skin Condition:** \(conditionEmoji) \(conditionAdvice)
        
        **🛡️ UV Protection Recommendations:**
        \(riskAdvice)
        
        **🌟 Age-Specific Advice:**
        \(ageSpecificAdvice)
        
        **📋 Daily Routine Tips:**
        • Apply sunscreen 15-30 minutes before sun exposure
        • Reapply every 2 hours, or after swimming/sweating
        • Use a broad-spectrum sunscreen (protects against UVA & UVB)
        • Don't forget your neck, ears, and hands!
        
        **⏰ Best Practices:**
        • Peak UV hours: 10 AM - 4 PM (seek shade during these times)
        • UV index 3+: Sunscreen recommended
        • UV index 6+: Extra protection needed
        • UV index 8+: Avoid outdoor activities if possible
        
        Remember: Consistent protection is key to maintaining healthy, youthful skin! 🌞✨
        """
        
        print("✅ Fallback Summary Generated for age \(age), conditions: \(skinConditions), severity: \(severityScore)")
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
