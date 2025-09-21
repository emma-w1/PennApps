//
//  CerebrasService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

//cerebras ai
class CerebrasService: ObservableObject {
    private let apiKey: String?
    private let config = Config.shared
    
    init() {
        self.apiKey = config.getCerebrasAPIKey()
        print("🤖 Cerebras Service initialized - Key available: \(config.hasCerebrasKey())")
    }
    
    func analyzeSkinConditionSeverity(conditions: String) async throws -> Int {
        let cleanedConditions = conditions.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // hand empty or "none" cases 
        if cleanedConditions.isEmpty {
            print("✅ No skin conditions provided - returning severity 0")
            return 0
        }
        
        // check for "none" variations
        let noneVariations = ["none", "n/a", "na", "no", "nothing", "normal", "normal skin", "no conditions", "none specified", "not applicable"]
        
        for variation in noneVariations {
            if cleanedConditions == variation || cleanedConditions.contains(variation) {
                print("✅ User indicated no skin conditions ('\(conditions)') - returning severity 0")
                return 0
            }
        }
        
        // config api key?
        guard let apiKey = apiKey else {
            print("⚠️ Cerebras API key not configured. Using default severity score of 1.")
            print("💡 Please set CEREBRAS_API_KEY in your .env file")
            return 1
        }
        
        guard config.hasCerebrasKey() else {
            print("⚠️ Cerebras API key appears to be a placeholder. Using default severity score of 1.")
            return 1
        }
        
        // fallback analysis if needed
        return fallbackAnalyzeSkinConditionSeverity(conditions: conditions)
    }
    
    //user summary
    func generateUserSummary(age: Int, skinConditions: [String], baselineRiskScore: Double? = nil, baselineRiskCategory: String? = nil) async throws -> String {
//        guard let apiKey = apiKey else {
//            print("⚠️ Cerebras API key not configured. Using fallback summary.")
//            return generateFallbackSummary(age: age, skinConditions: skinConditions, baselineRiskScore: baselineRiskScore, baselineRiskCategory: baselineRiskCategory)
//        }
//        
//        guard config.hasCerebrasKey() else {
//            print("⚠️ Cerebras API key appears to be a placeholder. Using fallback summary.")
//            return generateFallbackSummary(age: age, skinConditions: skinConditions, baselineRiskScore: baselineRiskScore, baselineRiskCategory: baselineRiskCategory)
//        }
        
        // fallback summary
        return generateFallbackSummary(age: age, skinConditions: skinConditions, baselineRiskScore: baselineRiskScore, baselineRiskCategory: baselineRiskCategory)
    }
    
    private func fallbackAnalyzeSkinConditionSeverity(conditions: String) -> Int {
        let cleanedConditions = conditions.lowercased()
        
        // rule-based analysis
        if cleanedConditions.contains("lupus") || cleanedConditions.contains("photosensitive") {
            return 5
        } else if cleanedConditions.contains("melasma") || cleanedConditions.contains("vitiligo") {
            return 4
        } else if cleanedConditions.contains("rosacea") || cleanedConditions.contains("psoriasis") {
            return 3
        } else if cleanedConditions.contains("eczema") || cleanedConditions.contains("dermatitis") {
            return 2
        } else if cleanedConditions.contains("acne") || cleanedConditions.contains("sensitive") {
            return 1
        } else {
            return 0
        }
    }
    
    private func generateFallbackSummary(age: Int, skinConditions: [String], baselineRiskScore: Double? = nil, baselineRiskCategory: String? = nil) -> String {
        // baseline risk info
        let baselineInfo: String
        if let baselineRiskCategory = baselineRiskCategory, !baselineRiskCategory.isEmpty {
            baselineInfo = "The baseline risk score is \(baselineRiskCategory).\n\n"
        } else if let baselineRiskScore = baselineRiskScore {
            baselineInfo = "The baseline risk score is \(String(format: "%.2f", baselineRiskScore)).\n\n"
        } else {
            baselineInfo = ""
        }
        
        let conditionsText = skinConditions.isEmpty ? "no significant skin conditions" : skinConditions.joined(separator: ", ")
        
        let ageImpact: String
        if age < 18 {
            ageImpact = "young age contributes to lower risk"
        } else if age < 30 {
            ageImpact = "age contributes moderately to risk"
        } else if age < 50 {
            ageImpact = "age increases baseline risk"
        } else {
            ageImpact = "age significantly increases risk"
        }
        
        let recommendations: String
        if skinConditions.contains(where: { $0.lowercased().contains("lupus") }) {
            recommendations = "Maximum protection required: SPF 50+, protective clothing, wide-brim hat, sunglasses, and minimize sun exposure."
        } else if skinConditions.contains(where: { $0.lowercased().contains("melasma") }) {
            recommendations = "Use SPF 50+, protective clothing, wide-brim hat, and avoid peak sun hours."
        } else if skinConditions.contains(where: { $0.lowercased().contains("rosacea") }) {
            recommendations = "Use SPF 30-50, protective clothing, and limit sun exposure."
        } else {
            recommendations = "Use SPF 30+ broad-spectrum sunscreen and seek shade during peak hours."
        }
        //skin summary output
        return """
        \(baselineInfo)Your skin profile shows you have \(conditionsText) at age \(age). These factors affect your risk through \(ageImpact).
        
        Advice: \(recommendations) Reapply every 2 hours and seek shade during peak UV hours (10 AM - 4 PM). 🌞
        """
    }
}

//handles errors from cerebras
enum CerebrasError: Error {
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
