//
//  LoginView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var age = ""
    @State private var skinConditions = ""
    @State private var selectedSkinToneIndex = 0
    
    let skinTones: [Color] = [
        Color(red: 244/255, green: 208/255, blue: 177/255),
        Color(red: 231/255, green: 180/255, blue: 143/255),
        Color(red: 210/255, green: 159/255, blue: 124/255),
        Color(red: 186/255, green: 120/255, blue: 81/255),
        Color(red: 165/255, green: 94/255, blue: 43/255),
        Color(red: 60/255, green: 31/255, blue: 29/255)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("Soliss")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                    
                    Text(isSignUpMode ? "Create Account" : "Welcome Back")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Form
                VStack(spacing: 20) {
                    // Email
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Sign up specific fields
                    if isSignUpMode {
                        // Age
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Age")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Enter your age", text: $age)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Skin Tone Selection
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Skin Tone")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text("Select your skin tone:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(Array(skinTones.enumerated()), id: \.offset) { index, tone in
                                    Circle()
                                        .fill(tone)
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedSkinToneIndex == index + 1 ? Color.yellow : Color.clear, lineWidth: 3)
                                        )
                                        .onTapGesture {
                                            selectedSkinToneIndex = index + 1
                                        }
                                }
                            }
                            .frame(maxWidth: 300, alignment: .leading)
                        }
                        
                        // Skin Conditions
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Skin Conditions")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("e.g., acne, eczema, sensitive skin (or \"none\" if no conditions)", text: $skinConditions, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // Error message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 40)
                }
                
                // Action buttons
                VStack(spacing: 15) {
                    // Main action button
                    Button(action: {
                        if isSignUpMode {
                            signUp()
                        } else {
                            signIn()
                        }
                    }) {
                        HStack {
                            if authManager.isAnalyzingSkinConditions {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSignUpMode ? 
                                 (authManager.isAnalyzingSkinConditions ? "Analyzing..." : "Sign Up") : 
                                 "Sign In")
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color(red: 235/255, green: 205/255, blue: 170/255))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.headline)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isAnalyzingSkinConditions)
                    
                    // Toggle mode button
                    Button(action: {
                        isSignUpMode.toggle()
                        authManager.errorMessage = nil
                    }) {
                        Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255).ignoresSafeArea())
    }
    
    private func signIn() {
        authManager.signIn(email: email, password: password)
    }
    
    private func signUp() {
        let selectedSkinTone = selectedSkinToneIndex > 0 && selectedSkinToneIndex <= skinTones.count 
            ? skinTones[selectedSkinToneIndex - 1] 
            : Color.clear
        
        authManager.signUp(
            email: email,
            password: password,
            age: age,
            skinTone: selectedSkinTone,
            skinConditions: skinConditions,
            skinToneIndex: selectedSkinToneIndex
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
