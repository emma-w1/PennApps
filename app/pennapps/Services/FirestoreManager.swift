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

class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    init() {
        print("FirestoreManager initialized")
    }
    
    //test connection w firestore database
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
    
    //fetch the user's data like email, age, skin tone, conditions from database to app
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
    
    //save user data from app to datadase
    func saveUserInfo(uid: String, email: String, age: String, skinTone: Color, conditions: String, skinToneIndex: Int, severityScore: Int) {
        print("FirestoreManager: Starting to save user data for UID: \(uid)")
        print("FirestoreManager: Email: \(email), Age: \(age), SkinTone Index: \(skinToneIndex), Conditions: \(conditions)")
        
        let userData: [String: Any] = [
            "email": email,
            "age": age,
            "skinToneIndex": skinToneIndex,
            "skinConditions": conditions,
            "conditionSeverity": severityScore,  
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        //prints specific gemini value for skin conditoin severity
        print("FirestoreManager: Attempting to write to Firestore with Gemini data...")
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error writing user document: \(error.localizedDescription)")
            } else {
                print("User data successfully written to Firestore with severity score: \(severityScore)!")
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
        
        // users/latest document first
        db.collection("users").document("latest").getDocument { document, error in
            if let error = error {
                print("Error fetching from users/latest: \(error.localizedDescription)")
                self.fetchFromPublicUVCollection(completion: completion)
            } else if let document = document, document.exists {
                let data = document.data()
                print("FirestoreManager: Latest document data: \(data ?? [:])")
                
                // Try UV_raw field first, then fallback to uv_index
                let uvIntensity = data?["UV_raw"] as? Int ?? data?["uv_raw"] as? Int ?? data?["uv_index"] as? Int
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
                print("FirestoreManager: Public UV document data: \(data ?? [:])")
                
                // Try UV_raw field first, then fallback to other field names
                let uvIntensity = data?["UV_raw"] as? Int ?? data?["uv_raw"] as? Int ?? data?["uv_index"] as? Int ?? data?["intensity"] as? Int
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
                let _ = self.setupPublicUVListener(completion: completion)
            } else if let document = documentSnapshot, document.exists {
                let data = document.data()
                print("FirestoreManager: Real-time document data: \(data ?? [:])")
                
                // Try UV_raw field first, then fallback to uv_index
                let uvIntensity = data?["UV_raw"] as? Int ?? data?["uv_raw"] as? Int ?? data?["uv_index"] as? Int
                print("FirestoreManager: Real-time UV intensity update from users/latest: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("users/latest document no longer exists, trying public collection")
                let _ = self.setupPublicUVListener(completion: completion)
            }
        }
        
        return listener
    }
    
    func listenToLatestDocumentChanges(uvCompletion: @escaping (Int?) -> Void, isPressedCompletion: @escaping (Bool, Date?) -> Void) -> ListenerRegistration {
        print("FirestoreManager: Setting up real-time listener for latest document...")
        
        return db.collection("users").document("latest").addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error listening to latest document: \(error.localizedDescription)")
                uvCompletion(nil)
                isPressedCompletion(false, nil)
            } else if let document = documentSnapshot, document.exists {
                let data = document.data()
                print("FirestoreManager: Latest document data: \(data ?? [:])")
                
                // Extract UV intensity
                let uvIntensity = data?["UV_raw"] as? Int ?? data?["uv_raw"] as? Int ?? data?["uv_index"] as? Int
                print("FirestoreManager: UV intensity: \(uvIntensity ?? -1)")
                uvCompletion(uvIntensity)
                
                // Extract is_pressed and timestamp
                let isPressed = data?["is_pressed"] as? Bool ?? false
                let timestamp = data?["timestamp"] as? Timestamp
                let date = timestamp?.dateValue()
                
                print("FirestoreManager: is_pressed: \(isPressed), timestamp: \(date?.description ?? "nil")")
                isPressedCompletion(isPressed, date)
            } else {
                print("Latest document no longer exists")
                uvCompletion(nil)
                isPressedCompletion(false, nil)
            }
        }
    }
    
    private func setupPublicUVListener(completion: @escaping (Int?) -> Void) -> ListenerRegistration {
        print("FirestoreManager: Setting up public UV data listener...")
        
        return db.collection("uvData").document("current").addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error listening to public UV collection: \(error.localizedDescription)")
                completion(nil)
            } else if let document = documentSnapshot, document.exists {
                let data = document.data()
                print("FirestoreManager: Real-time public UV document data: \(data ?? [:])")
                
                // Try UV_raw field first, then fallback to other field names
                let uvIntensity = data?["UV_raw"] as? Int ?? data?["uv_raw"] as? Int ?? data?["uv_index"] as? Int ?? data?["intensity"] as? Int
                print("FirestoreManager: Real-time UV intensity update from public collection: \(uvIntensity ?? -1)")
                completion(uvIntensity)
            } else {
                print("Public UV document no longer exists")
                completion(nil)
            }
        }
    }
    
    // MARK: - Last Applied Date Management
    
    func saveLastAppliedDate(date: Date) {
        print("FirestoreManager: Saving last applied date to users/latest document")
        
        let dateData: [String: Any] = [
            "lastAppliedDate": Timestamp(date: date),
            "lastAppliedTimestamp": date.timeIntervalSince1970,
            "lastAppliedUpdatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document("latest").updateData(dateData) { error in
            if let error = error {
                print("Error saving last applied date to latest document: \(error.localizedDescription)")
            } else {
                print("✅ Last applied date saved successfully to latest document: \(date)")
            }
        }
    }
    
    func fetchLastAppliedDate(completion: @escaping (Date?) -> Void) {
        print("FirestoreManager: Fetching last applied date from users/latest document")
        
        db.collection("users").document("latest").getDocument { document, error in
            if let error = error {
                print("Error fetching last applied date from latest document: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let data = document.data()
                
                // Try to get the date from Timestamp first, then fallback to timestamp
                if let timestamp = data?["lastAppliedDate"] as? Timestamp {
                    let date = timestamp.dateValue()
                    print("FirestoreManager: Retrieved last applied date from Timestamp: \(date)")
                    completion(date)
                } else if let timestamp = data?["lastAppliedTimestamp"] as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timestamp)
                    print("FirestoreManager: Retrieved last applied date from timestamp: \(date)")
                    completion(date)
                } else {
                    print("FirestoreManager: No last applied date found in latest document")
                    completion(nil)
                }
            } else {
                print("Latest document does not exist for last applied date")
                completion(nil)
            }
        }
    }
    
}
