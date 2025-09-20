//
//  FirestoreManager.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

//this is to store user data when registered / settings to firestore
//lots of print statements for debugging

import Foundation
import FirebaseFirestore
import SwiftUI

struct UserData {
    let email: String
    let age: String
    let skinToneIndex: Int
    let skinConditions: String
}

class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    init() {
        print("FirestoreManager initialized")
    }
    
    func testConnection() {
        print("Testing Firestore connection...")
        db.collection("test").document("test").setData(["test": "value"]) { error in
            if let error = error {
                print("Firestore test failed: \(error.localizedDescription)")
            } else {
                print("Firestore test successful!")
            }
        }
    }
    
    func fetchUserData(uid: String, completion: @escaping (UserData?) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let data = document.data()
                let userData = UserData(
                    email: data?["email"] as? String ?? "",
                    age: data?["age"] as? String ?? "",
                    skinToneIndex: data?["skinToneIndex"] as? Int ?? 0,
                    skinConditions: data?["skinConditions"] as? String ?? ""
                )
                completion(userData)
            } else {
                print("User document does not exist")
                completion(nil)
            }
        }
    }
    
    func saveUserInfo(uid: String, email: String, age: String, skinTone: Color, conditions: String, skinToneIndex: Int, severityScore: Int) {
        print("FirestoreManager: Starting to save user data for UID: \(uid)")
        print("FirestoreManager: Email: \(email), Age: \(age), SkinTone Index: \(skinToneIndex), Conditions: \(conditions)")
        
        let userData: [String: Any] = [
            "email": email,
            "age": age,
            "skinToneIndex": skinToneIndex,
            "skinConditions": conditions,
            "conditionSeverity": severityScore,  // ← Gemini analysis result
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        print("FirestoreManager: Attempting to write to Firestore with Gemini data...")
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error writing user document: \(error.localizedDescription)")
            } else {
                print("User data successfully written to Firestore with severity score: \(severityScore)!")
            }
        }
    }
    
    func fetchLatestUVIntensity(completion: @escaping (Int?) -> Void) {
        print("FirestoreManager: Fetching latest UV intensity...")
        
        // Try the users/latest document first
        db.collection("users").document("latest").getDocument { document, error in
            if let error = error {
                print("Error fetching from users/latest: \(error.localizedDescription)")
                // Fallback: try a public UV data collection
                self.fetchFromPublicUVCollection(completion: completion)
            } else if let document = document, document.exists {
                let data = document.data()
                let uvIntensity = data?["uv_index"] as? Int
                print("FirestoreManager: Retrieved UV intensity from users/latest: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("users/latest document does not exist, trying public collection")
                self.fetchFromPublicUVCollection(completion: completion)
            }
        }
    }
    
    private func fetchFromPublicUVCollection(completion: @escaping (Int?) -> Void) {
        print("FirestoreManager: Trying public UV data collection...")
        
        db.collection("uvData").document("current").getDocument { document, error in
            if let error = error {
                print("Error fetching from public UV collection: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let data = document.data()
                let uvIntensity = data?["uv_index"] as? Int ?? data?["intensity"] as? Int
                print("FirestoreManager: Retrieved UV intensity from public collection: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("No UV data found in any collection")
                completion(nil)
            }
        }
    }
    
    func listenToUVIntensityChanges(completion: @escaping (Int?) -> Void) -> ListenerRegistration {
        print("FirestoreManager: Setting up real-time listener for UV intensity...")
        
        // Try to listen to users/latest first
        let listener = db.collection("users").document("latest").addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error listening to users/latest: \(error.localizedDescription)")
                // Fallback: try listening to public collection
                self.setupPublicUVListener(completion: completion)
            } else if let document = documentSnapshot, document.exists {
                let data = document.data()
                let uvIntensity = data?["uv_index"] as? Int
                print("FirestoreManager: Real-time UV intensity update from users/latest: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("users/latest document no longer exists, trying public collection")
                self.setupPublicUVListener(completion: completion)
            }
        }
        
        return listener
    }
    
    private func setupPublicUVListener(completion: @escaping (Int?) -> Void) -> ListenerRegistration {
        print("FirestoreManager: Setting up public UV data listener...")
        
        return db.collection("uvData").document("current").addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error listening to public UV collection: \(error.localizedDescription)")
                completion(nil)
            } else if let document = documentSnapshot, document.exists {
                let data = document.data()
                let uvIntensity = data?["uv_index"] as? Int ?? data?["intensity"] as? Int
                print("FirestoreManager: Real-time UV intensity update from public collection: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("Public UV document no longer exists")
                completion(nil)
            }
        }
    }
}
