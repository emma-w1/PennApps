//
//  RiskCalculationService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

class RiskCalculationService {
    static let shared = RiskCalculationService()
    
    private init() {}
    
    // Fitzpatrick values for skin tones 
    private let phototypeRefValues: [Double] = [1.0, 0.8, 0.6, 0.4, 0.2, 0.1]
    
    // age modifiers
    private func getAgeModifier(age: Int) -> Double {
        switch age {
        case 0..<20:
            return 0.8
        case 20...39:
            return 1.0
        case 40...59:
            return 1.2
        case 60...69:
            return 1.4
        default: // 70+
            return 1.6
        }
    }
    
    // Condition modifiers based on severity score
    private func getConditionModifier(severityScore: Int) -> Double {
        switch severityScore {
        case 0: return 1.0
        case 1: return 1.1
        case 2: return 1.2
        case 3: return 1.4
        case 4: return 1.6
        case 5: return 1.8
        default: return 1.0
        }
    }
    
    // Risk category classification
    private func classifyRiskCategory(riskScore: Double) -> String {
        switch riskScore {
        case 0.1...0.3:
            return "Very Low"
        case 0.31...0.6:
            return "Low"
        case 0.61...1.0:
            return "Medium"
        case 1.01...1.5:
            return "High"
        case _ where riskScore > 1.5:
            return "Very High"
        default:
            return "Unknown"
        }
    }
    
    // Calculate baseline risk score (without skin conditions)
    func calculateBaselineRiskScore(skinToneIndex: Int, age: Int) -> [String: Any] {
        // Convert skin tone index to phototype (1-6)
        let phototype = max(1, min(6, skinToneIndex))
        let ref = phototypeRefValues[phototype - 1]
        let ageModifier = getAgeModifier(age: age)
        
        // Baseline calculation: REF * Age Modifier (no condition modifier)
        let baselineRiskScore = ref * ageModifier
        let baselineRiskCategory = classifyRiskCategory(riskScore: baselineRiskScore)
        
        return [
            "baseline_risk_score": baselineRiskScore,
            "baseline_risk_category": baselineRiskCategory,
            "phototype": phototype,
            "age": age,
            "ref": ref,
            "age_modifier": ageModifier
        ]
    }
    
    // Calculate final risk score (with skin conditions)
    func calculateFinalRiskScore(skinToneIndex: Int, age: Int, severityScore: Int) -> [String: Any] {
        // Convert skin tone index to phototype (1-6)
        let phototype = max(1, min(6, skinToneIndex))
        let ref = phototypeRefValues[phototype - 1]
        let ageModifier = getAgeModifier(age: age)
        let conditionModifier = getConditionModifier(severityScore: severityScore)
        
        // Final calculation: REF * Age Modifier * Condition Modifier
        let finalRiskScore = ref * ageModifier * conditionModifier
        let finalRiskCategory = classifyRiskCategory(riskScore: finalRiskScore)
        
        return [
            "final_risk_score": finalRiskScore,
            "final_risk_category": finalRiskCategory,
            "phototype": phototype,
            "age": age,
            "severity_score": severityScore,
            "ref": ref,
            "age_modifier": ageModifier,
            "condition_modifier": conditionModifier
        ]
    }
    
    // Calculate complete user risk profile
    func calculateUserRiskProfile(skinToneIndex: Int, age: Int, severityScore: Int) -> [String: Any] {
        let baseline = calculateBaselineRiskScore(skinToneIndex: skinToneIndex, age: age)
        let final = calculateFinalRiskScore(skinToneIndex: skinToneIndex, age: age, severityScore: severityScore)
        
        return [
            "baseline": [
                "baseline_risk_score": baseline["baseline_risk_score"] ?? 0.0,
                "baseline_risk_category": baseline["baseline_risk_category"] ?? "Unknown"
            ],
            "final": [
                "final_risk_score": final["final_risk_score"] ?? 0.0,
                "final_risk_category": final["final_risk_category"] ?? "Unknown"
            ]
        ]
    }
}
