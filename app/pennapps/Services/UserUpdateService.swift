//
//  UserUpdateService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation
import FirebaseFirestore

class UserUpdateService {
    static let shared = UserUpdateService()
    private let db = Firestore.firestore()
    private let riskService = RiskCalculationService.shared
    
    private init() {}
    
    /// Updates all existing users in the database with correct risk categories
    func updateAllUsersRiskCategories(completion: @escaping (Bool, String) -> Void) {
        print("🔄 Starting to update risk categories for all users...")
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            if let error = error {
                print("❌ Error fetching users: \(error.localizedDescription)")
                completion(false, "Error fetching users: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("ℹ️ No users found in the database")
                completion(true, "No users found to update")
                return
            }
            
            print("📊 Found \(documents.count) users to update")
            var updatedCount = 0
            var errorCount = 0
            
            let group = DispatchGroup()
            
            for document in documents {
                group.enter()
                
                self.updateUserRiskCategories(document: document) { success, message in
                    if success {
                        updatedCount += 1
                        print("✅ Updated user \(document.documentID)")
                    } else {
                        errorCount += 1
                        print("❌ Failed to update user \(document.documentID): \(message)")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let message = "Updated \(updatedCount) users successfully. \(errorCount) errors."
                print("🎉 Update complete: \(message)")
                completion(errorCount == 0, message)
            }
        }
    }
    
    /// Updates a single user's risk categories
    private func updateUserRiskCategories(document: DocumentSnapshot, completion: @escaping (Bool, String) -> Void) {
        guard let userData = document.data() else {
            completion(false, "No user data found")
            return
        }
        
        // Extract user data
        let ageString = userData["age"] as? String ?? "25"
        let age = Int(ageString) ?? 25
        let skinToneIndex = userData["skinToneIndex"] as? Int ?? 3
        let severityScore = userData["conditionSeverity"] as? Int ?? 0
        
        print("Processing user \(document.documentID): age=\(age), skinTone=\(skinToneIndex), severity=\(severityScore)")
        
        // Calculate new risk categories
        let baselineResult = riskService.calculateBaselineRiskScore(skinToneIndex: skinToneIndex, age: age)
        let finalResult = riskService.calculateFinalRiskScore(skinToneIndex: skinToneIndex, age: age, severityScore: severityScore)
        
        let baselineRiskScore = baselineResult["baseline_risk_score"] as? Double ?? 0.0
        let baselineRiskCategory = baselineResult["baseline_risk_category"] as? String ?? "Unknown"
        let finalRiskScore = finalResult["final_risk_score"] as? Double ?? 0.0
        let finalRiskCategory = finalResult["final_risk_category"] as? String ?? "Unknown"
        
        print("Calculated for \(document.documentID): baseline=\(baselineRiskScore) (\(baselineRiskCategory)), final=\(finalRiskScore) (\(finalRiskCategory))")
        
        // Update the user document
        let updateData: [String: Any] = [
            "baseline_risk_score": baselineRiskScore,
            "baseline_risk_category": baselineRiskCategory,
            "final_risk_score": finalRiskScore,
            "final_risk_category": finalRiskCategory,
            "risk_updated_at": FieldValue.serverTimestamp()
        ]
        
        document.reference.updateData(updateData) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, "Success")
            }
        }
    }
    
    /// Updates a specific user's risk categories by UID
    func updateUserRiskCategories(uid: String, completion: @escaping (Bool, String) -> Void) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            if let error = error {
                completion(false, "Error fetching user: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                completion(false, "User not found")
                return
            }
            
            self.updateUserRiskCategories(document: document, completion: completion)
        }
    }
}
