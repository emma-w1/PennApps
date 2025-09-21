//
//  UVMonitoringService.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation
import FirebaseFirestore

class UVMonitoringService: ObservableObject {
    static let shared = UVMonitoringService()
    
    private let db = Firestore.firestore()
    private let riskService = RiskCalculationService.shared
    private var uvListener: ListenerRegistration?
    private var isMonitoring = false
    
    // Tracking for each user
    private var userTrackingData: [String: UserTrackingInfo] = [:]
    
    private init() {}
    
    struct UserTrackingInfo {
        var previousUVIntensity: Int = 0
        var lastCalculationTime: Date = Date()
        var documentReference: DocumentReference
        var skinToneIndex: Int
        var age: Int
        var severityScore: Int
        var location: String
    }
    
    /// Start monitoring UV changes and updating final risk scores for all users
    func startUVMonitoring() {
        guard !isMonitoring else {
            print("UV monitoring is already running")
            return
        }
        
        print("🔄 Starting UV monitoring service...")
        isMonitoring = true
        
        // First, load all users and set up tracking
        loadAllUsersForMonitoring { [weak self] success in
            if success {
                self?.setupUVListener()
            } else {
                print("❌ Failed to load users for monitoring")
                self?.isMonitoring = false
            }
        }
    }
    
    /// Stop UV monitoring
    func stopUVMonitoring() {
        print("⏹️ Stopping UV monitoring service...")
        isMonitoring = false
        uvListener?.remove()
        uvListener = nil
        userTrackingData.removeAll()
    }
    
    /// Load all users and set up tracking data
    private func loadAllUsersForMonitoring(completion: @escaping (Bool) -> Void) {
        print("📊 Loading all users for UV monitoring...")
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("❌ Error loading users: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("ℹ️ No users found")
                completion(true)
                return
            }
            
            // Filter out the "latest" document which is used for UV data
            let userDocuments = documents.filter { $0.documentID != "latest" }
            
            print("👥 Found \(userDocuments.count) users to monitor")
            
            for document in userDocuments {
                let userData = document.data()
                
                // Extract user data
                let ageString = userData["age"] as? String ?? "25"
                let age = Int(ageString) ?? 25
                let skinToneIndex = userData["skinToneIndex"] as? Int ?? 3
                let severityScore = userData["conditionSeverity"] as? Int ?? 0
                let location = userData["location"] as? String ?? "default_location"
                
                // Create tracking info
                let trackingInfo = UserTrackingInfo(
                    previousUVIntensity: 0,
                    lastCalculationTime: Date(),
                    documentReference: document.reference,
                    skinToneIndex: skinToneIndex,
                    age: age,
                    severityScore: severityScore,
                    location: location
                )
                
                self.userTrackingData[document.documentID] = trackingInfo
                print("✅ Set up monitoring for user \(document.documentID)")
            }
            
            completion(true)
        }
    }
    
    /// Set up real-time listener for UV changes
    private func setupUVListener() {
        print("🎧 Setting up UV change listener...")
        
        uvListener = FirestoreManager.shared.listenToUVIntensityChanges { [weak self] uvIntensity in
            guard let self = self, let uvIntensity = uvIntensity else {
                return
            }
            
            print("🌞 UV intensity changed to: \(uvIntensity)")
            self.updateAllUsersFinalRiskScores(uvIntensity: uvIntensity)
        }
    }
    
    /// Update final risk scores for all users based on new UV intensity
    private func updateAllUsersFinalRiskScores(uvIntensity: Int) {
        let currentTime = Date()
        var updatesMade = 0
        
        for (userId, trackingInfo) in userTrackingData {
            // Check if we should recalculate for this user
            let timeSinceLastCalculation = currentTime.timeIntervalSince(trackingInfo.lastCalculationTime)
            let uvChange = abs(uvIntensity - trackingInfo.previousUVIntensity)
            
            // Recalculate if UV changed by 100+ OR 15 minutes (900 seconds) have passed
            let shouldRecalculate = uvChange >= 100 || timeSinceLastCalculation >= 900
            
            if shouldRecalculate {
                // Calculate new final risk score with UV modifier
                let finalResult = calculateFinalRiskScoreWithUV(
                    skinToneIndex: trackingInfo.skinToneIndex,
                    age: trackingInfo.age,
                    severityScore: trackingInfo.severityScore,
                    uvIntensity: uvIntensity
                )
                
                let finalRiskScore = finalResult["final_risk_score"] as? Double ?? 0.0
                let finalRiskCategory = finalResult["final_risk_category"] as? String ?? "Unknown"
                
                // Update the user document
                let updateData: [String: Any] = [
                    "final_risk_score": finalRiskScore,
                    "final_risk_category": finalRiskCategory,
                    "current_uv_intensity": uvIntensity,
                    "last_uv_update": currentTime,
                    "uv_update_timestamp": FieldValue.serverTimestamp()
                ]
                
                trackingInfo.documentReference.updateData(updateData) { error in
                    if let error = error {
                        print("❌ Error updating user \(userId): \(error.localizedDescription)")
                    } else {
                        print("✅ Updated user \(userId): Final=\(finalRiskCategory) (UV=\(uvIntensity))")
                        updatesMade += 1
                    }
                }
                
                // Update tracking info
                userTrackingData[userId]?.previousUVIntensity = uvIntensity
                userTrackingData[userId]?.lastCalculationTime = currentTime
            }
        }
        
        if updatesMade == 0 {
            print("ℹ️ No user updates needed (UV change < 100, time < 15min)")
        } else {
            print("🎉 Made \(updatesMade) user updates based on UV change")
        }
    }
    
    /// Calculate final risk score including UV modifier
    private func calculateFinalRiskScoreWithUV(skinToneIndex: Int, age: Int, severityScore: Int, uvIntensity: Int) -> [String: Any] {
        let phototype = max(1, min(6, skinToneIndex))
        let ref = riskService.phototypeRefValues[phototype - 1]
        let ageModifier = riskService.getAgeModifier(age: age)
        let conditionModifier = riskService.getConditionModifier(severityScore: severityScore)
        
        // Calculate UV modifier
        let uvModifier = getUVModifier(uvIntensity: uvIntensity)
        
        // Final calculation: REF * Age Modifier * Condition Modifier + UV Modifier
        let finalRiskScore = (ref * ageModifier * conditionModifier) + uvModifier
        let finalRiskCategory = riskService.classifyFinalRiskCategory(riskScore: finalRiskScore)
        
        return [
            "final_risk_score": finalRiskScore,
            "final_risk_category": finalRiskCategory,
            "uv_modifier": uvModifier,
            "uv_intensity": uvIntensity
        ]
    }
    
    /// Calculate UV modifier based on UV intensity
    private func getUVModifier(uvIntensity: Int) -> Double {
        if uvIntensity == 0 {
            return -2.88  // Indoor/no UV
        } else {
            let proportion = Double(uvIntensity) / 165.0  // 165 is max UV intensity
            return proportion * 2.88  // 2.88 is max UV modifier
        }
    }
}

