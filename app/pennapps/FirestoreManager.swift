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
    
    func saveUserInfo(uid: String, age: String, skinTone: Color, conditions: String, skinToneIndex: Int) {
        print("FirestoreManager: Starting to save user data for UID: \(uid)")
        print("FirestoreManager: Age: \(age), SkinTone Index: \(skinToneIndex), Conditions: \(conditions)")
        
        let userData: [String: Any] = [
            "age": age,
            "skinToneIndex": skinToneIndex,
            "skinConditions": conditions,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        print("FirestoreManager: Attempting to write to Firestore...")
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error writing user document: \(error.localizedDescription)")
            } else {
                print("User data successfully written to Firestore!")
            }
        }
    }
}
