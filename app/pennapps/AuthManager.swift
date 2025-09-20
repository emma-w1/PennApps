//
//  AuthManager.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//


import Foundation
import FirebaseAuth
import SwiftUI

//firebase authentication manager for login functionality
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isLoading = true
    @Published var isAnalyzingSkinConditions = false
    
    // Gemini service for skin condition analysis
    private let geminiService = GeminiService()
    
    init() {
    //authentication changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                print("Auth state changed - User: \(user?.email ?? "nil")")
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }
    
//    sign in
    func signIn(email: String, password: String) {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Sign in error: \(error.localizedDescription)")
                } else {
                    self?.errorMessage = nil
                    print("Sign in successful")
                }
            }
        }
    }
    
//    sign up with Gemini skin condition analysis
    func signUp(email: String, password: String, age: String = "", skinTone: Color = .clear, skinConditions: String = "", skinToneIndex: Int = 0) {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        // Start analyzing skin conditions with Gemini
        isAnalyzingSkinConditions = true
        errorMessage = nil
        
        Task {
            do {
                // Step 1: Analyze skin conditions with Gemini
                let severityScore = try await geminiService.analyzeSkinConditionSeverity(conditions: skinConditions)
                print("✅ Gemini Analysis Complete: '\(skinConditions)' → Severity: \(severityScore)")
                
                // Step 2: Continue with Firebase registration on main thread
                await MainActor.run {
                    self.isAnalyzingSkinConditions = false
                    self.createFirebaseUser(
                        email: email,
                        password: password,
                        age: age,
                        skinTone: skinTone,
                        skinConditions: skinConditions,
                        skinToneIndex: skinToneIndex,
                        severityScore: severityScore
                    )
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzingSkinConditions = false
                    print("⚠️ Gemini analysis failed: \(error.localizedDescription)")
                    // Continue with default severity score of 1 if Gemini fails
                    self.createFirebaseUser(
                        email: email,
                        password: password,
                        age: age,
                        skinTone: skinTone,
                        skinConditions: skinConditions,
                        skinToneIndex: skinToneIndex,
                        severityScore: 1
                    )
                }
            }
        }
    }
    
    // Step 2: Create Firebase user with severity score
    private func createFirebaseUser(email: String, password: String, age: String, skinTone: Color, skinConditions: String, skinToneIndex: Int, severityScore: Int) {
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Sign up error: \(error.localizedDescription)")
                } else if let uid = result?.user.uid {
                    self?.errorMessage = nil
                    print("Sign up successful")
                    
                    // Test Firestore connection first
                    print("Testing Firestore connection...")
                    FirestoreManager.shared.testConnection()
                    
                    // Save user data with Gemini severity score
                    print("Saving user data with severity score: \(severityScore)")
                    if !age.isEmpty || skinToneIndex > 0 || !skinConditions.isEmpty {
                        print("Calling FirestoreManager to save data with Gemini analysis...")
                        FirestoreManager.shared.saveUserInfo(
                            uid: uid,
                            age: age,
                            skinTone: skinTone,
                            conditions: skinConditions,
                            skinToneIndex: skinToneIndex,
                            severityScore: severityScore  // ← Gemini result goes to Firebase
                        )
                    } else {
                        print("No additional data to save")
                    }
                } else {
                    self?.errorMessage = "An unexpected error occured"
                }
            }
        }
    }
    
//    sign out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("Sign out successful")
        } catch {
            errorMessage = error.localizedDescription
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
