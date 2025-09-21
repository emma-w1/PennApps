//
//  UserData.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

/// User data model for storing profile information
struct UserData {
    let email: String
    let age: String
    let skinToneIndex: Int
    let skinConditions: String
    let baselineRiskScore: Double?
    let baselineRiskCategory: String?
    let finalRiskScore: Double?
    let finalRiskCategory: String?
}

/// Represents UV risk levels based on skin condition severity
enum UVRiskLevel: Int, CaseIterable {
    case none = 0
    case minimal = 1
    case low = 2
    case moderate = 3
    case high = 4
    case severe = 5
    
    var description: String {
        switch self {
        case .none: return "No additional UV risk"
        case .minimal: return "Minimal UV risk"
        case .low: return "Low UV risk"
        case .moderate: return "Moderate UV risk"
        case .high: return "High UV risk"
        case .severe: return "Severe UV risk"
        }
    }
    
    var recommendations: String {
        switch self {
        case .none:
            return "Continue regular sun protection habits."
        case .minimal:
            return "Basic sun protection recommended."
        case .low:
            return "Use SPF 30+ and seek shade during peak hours."
        case .moderate:
            return "Use SPF 50+, protective clothing, and limit sun exposure."
        case .high:
            return "Use SPF 50+, protective clothing, wide-brim hat, and avoid peak sun hours."
        case .severe:
            return "Maximum protection required: SPF 50+, protective clothing, wide-brim hat, sunglasses, and minimize sun exposure."
        }
    }
}
