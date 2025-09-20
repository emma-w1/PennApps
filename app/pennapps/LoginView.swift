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
    @State private var isSignUp = false
    
    @State private var age = ""
    @State private var selectedSkinTone: Color = .clear
    @State private var selectedSkinToneIndex: Int = 0
    @State private var skinConditions = ""
    
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
                //email and login form slots
                VStack(spacing: 10) {
                    Image("Soliss")
                        .padding(.vertical, 0)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(.top, 0)
                        .frame(maxWidth: 300)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                    
//                    new registration
                    if isSignUp {
                        TextField("Age", text: $age)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 300)
                                                
                        VStack(alignment: .leading) {
                            Text("Select your skin tone:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                                    
                            HStack(spacing: 15) {
                            ForEach(Array(skinTones.enumerated()), id: \.offset) { index, tone in
                                Circle()
                                    .fill(tone)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                    Circle()
                                        .stroke(selectedSkinToneIndex == index + 1 ? Color.yellow : Color.clear, lineWidth: 3)
                                                )
                                    .onTapGesture {
                                    selectedSkinTone = tone
                                    selectedSkinToneIndex = index + 1
                            }
                                                        }
                                                    }
                                                }
                                                .padding(.vertical, 5)
                                                
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Pre-existing skin conditions", text: $skinConditions)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 300)
                        
                        Text("e.g., acne, eczema, sensitive skin (or \"none\" if no conditions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 300, alignment: .leading)
                    }
                    
                    // Show Gemini analysis progress
                    if authManager.isAnalyzingSkinConditions {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Analyzing skin condition severity with AI...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 5)
                    }                    }
//                    errors
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
//                    sign up/sign in button
                    Button(action: {
                        if isSignUp {
                            authManager.signUp(
                                email: email, 
                                password: password, 
                                age: age, 
                                skinTone: selectedSkinTone, 
                                skinConditions: skinConditions,
                                skinToneIndex: selectedSkinToneIndex
                            )
                        } else {
                            authManager.signIn(email: email, password: password)
                        }
                    }) {
                        HStack {
                            if authManager.isAnalyzingSkinConditions {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSignUp ? (authManager.isAnalyzingSkinConditions ? "Analyzing..." : "Register") : "Log In")
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.headline)
                    }
                    .disabled(authManager.isAnalyzingSkinConditions || (isSignUp ? (email.isEmpty || password.isEmpty || age.isEmpty || selectedSkinToneIndex == 0) : (email.isEmpty || password.isEmpty)))
                    
//                    switch mode from sign in to sign up or vice versa
                    Button(action: {
                        isSignUp.toggle()
                        authManager.errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Register")
                            .font(.caption)
                            .foregroundColor(Color(red: 161/255, green: 114/255, blue: 14/255))
                    }
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 100)
                
        }
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
