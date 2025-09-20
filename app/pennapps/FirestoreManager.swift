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
    
    }
    
    func getUserData(uid: String) async throws -> [String: Any]? {
        print("FirestoreManager: Fetching user data for UID: \(uid)")
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists {
                let data = document.data()
                print("FirestoreManager: Successfully retrieved user data")
                return data
            } else {
                print("FirestoreManager: No user document found")
                return nil
            }
        } catch {
            print("FirestoreManager: Error fetching user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchLatestUVIndex(completion: @escaping (Int?) -> Void) {
        print("FirestoreManager: Fetching latest UV index...")
        
        db.collection("users").document("latest").getDocument { document, error in
            if let error = error {
                print("Error fetching latest UV index: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let data = document.data()
                let uvIndex = data?["uv_index"] as? Int
                print("FirestoreManager: Retrieved UV index: \(uvIndex ?? -1)")
                completion(uvIndex)
            } else {
                print("Latest document does not exist")
                completion(nil)
            }
        }
    }
    
    func fetchUserData(uid: String, completion: @escaping (UserData?) -> Void) {
        print("FirestoreManager: Fetching user data for UID: \(uid)")
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let data = document.data()
                
                if let age = data?["age"] as? String,
                   let skinToneIndex = data?["skinToneIndex"] as? Int,
                   let skinConditions = data?["skinConditions"] as? String {
                    
                    let userData = UserData(
                        email: "", // Email not stored in user document
                        age: age,
                        skinToneIndex: skinToneIndex,
                        skinConditions: skinConditions
                    )
                    
                    print("FirestoreManager: Successfully parsed user data - Age: \(age), SkinTone: \(skinToneIndex), Conditions: \(skinConditions)")
                    completion(userData)
                } else {
                    print("FirestoreManager: Failed to parse user data from document")
                    completion(nil)
                }
            } else {
                print("User document does not exist for UID: \(uid)")
                completion(nil)
            }
        }
    }
}
