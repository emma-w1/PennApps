import Foundation

enum GeminiError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case noAPIKey
    case requestFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .noAPIKey:
            return "API key not found"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        }
    }
}

class GeminiService: ObservableObject {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
    private var apiKey: String? {
        return Config.shared.getGeminiAPIKey()
    }
    
    init() {}
    
    func analyzeSkinConditionSeverity(conditions: String) async throws -> Int {
        guard let apiKey = apiKey else {
            print("⚠️ No Gemini API key found, using fallback")
            return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let prompt = """
        Analyze the following skin conditions and provide a UV risk severity score from 0-5:
        - 0: No risk (normal skin)
        - 1: Very low risk
        - 2: Low risk  
        - 3: Medium risk
        - 4: High risk
        - 5: Very high risk (requires immediate protection)
        
        Skin conditions: \(conditions)
        
        Return only the number (0-5), no explanation needed.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.requestFailed("Failed to encode request: \(error)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(errorBody)")
                return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                throw GeminiError.invalidResponse
            }
            
            let severityText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let severity = Int(severityText), severity >= 0 && severity <= 5 {
                print("✅ Gemini analysis: '\(conditions)' → Severity: \(severity)")
                return severity
            } else {
                print("⚠️ Invalid Gemini response: '\(severityText)', using fallback")
                return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
            }
            
        } catch {
            print("❌ Gemini request failed: \(error), using fallback")
            return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
        }
    }
    
    private func fallbackAnalyzeSkinConditionSeverity(conditions: String) -> Int {
        let lowerConditions = conditions.lowercased()
        
        if lowerConditions.contains("none") || lowerConditions.isEmpty {
            return 0
        } else if lowerConditions.contains("acne") || lowerConditions.contains("blackhead") {
            return 2
        } else if lowerConditions.contains("eczema") || lowerConditions.contains("dermatitis") {
            return 3
        } else if lowerConditions.contains("psoriasis") || lowerConditions.contains("rosacea") {
            return 4
        } else if lowerConditions.contains("melanoma") || lowerConditions.contains("cancer") {
            return 5
        } else {
            return 1 // Default for unknown conditions
        }
    }
    
    func generateUserSummary(age: Int, skinConditions: [String]) async throws -> String {
        guard let apiKey = apiKey else {
            print("⚠️ No Gemini API key found, using fallback")
            return fallbackGenerateUserSummary(age: age, skinConditions: skinConditions)
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let conditionsString = skinConditions.joined(separator: ", ")
        let prompt = """
        Generate a personalized skincare summary for a user with the following profile:
        - Age: \(age)
        - Skin Conditions: \(conditionsString.isEmpty ? "None" : conditionsString)
        
        Provide a brief, friendly summary (2-3 sentences) with:
        1. General skin health assessment
        2. Key recommendations for their age and conditions
        3. UV protection advice based on their profile
        
        Keep it encouraging and practical.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.requestFailed("Failed to encode request: \(error)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(errorBody)")
                return fallbackGenerateUserSummary(age: age, skinConditions: skinConditions)
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                throw GeminiError.invalidResponse
            }
            
            print("✅ Gemini summary generated successfully")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            print("❌ Gemini request failed: \(error), using fallback")
            return fallbackGenerateUserSummary(age: age, skinConditions: skinConditions)
        }
    }
    
    private func fallbackGenerateUserSummary(age: Int, skinConditions: [String]) -> String {
        let hasConditions = !skinConditions.isEmpty && skinConditions != ["none"]
        
        if age < 25 {
            if hasConditions {
                return "Your young skin is resilient! Focus on gentle cleansing and consistent moisturizing to manage your current skin concerns. Don't forget daily SPF 30+ to protect against future damage."
            } else {
                return "Your skin looks great! At your age, prevention is key. Stick to a simple routine with gentle cleanser, moisturizer, and daily SPF 30+ to maintain healthy skin for years to come."
            }
        } else if age < 40 {
            if hasConditions {
                return "Your skin is entering its prime years. Address your current concerns with targeted treatments while maintaining a consistent routine. SPF 30+ daily is crucial for preventing further issues."
            } else {
                return "Your skin is in good shape! Focus on maintaining hydration and protection. A consistent routine with antioxidants and daily SPF 30+ will help preserve your skin's health."
            }
        } else {
            if hasConditions {
                return "Mature skin requires extra care and attention. Focus on hydrating, nourishing treatments for your specific concerns. Daily SPF 30+ and gentle, effective products are your best allies."
            } else {
                return "Your skin looks wonderful! Maintain its health with rich moisturizers, gentle treatments, and consistent SPF 30+ protection. Your good habits are clearly paying off."
            }
        }
    }
}