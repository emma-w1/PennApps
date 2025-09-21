//
//  SettingsView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var userData: UserData?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Editable fields
    @State private var age: String = ""
    @State private var skinConditions: String = ""
    @State private var selectedSkinToneIndex: Int = 0
    
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
            Topbar()
                .padding(.top, 0)
            
            VStack(spacing: 20) {
                Text("SETTINGS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .foregroundStyle(.yellow)
            
            ScrollView{
                if isLoading {
                    ProgressView("Loading settings...")
                        .padding()
                } else {
                    VStack(spacing: 15) {
                        // welcome
                        Text("Welcome, \(authManager.user?.email ?? "User")!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        // age
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Age")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Enter your age", text: $age)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 300)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    isTextFieldFocused = false
                                }
                        }
                        
                        // skin tones
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
                            
                            if selectedSkinToneIndex > 0 {
                                Text("Selected: Tone \(selectedSkinToneIndex)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: 300, alignment: .leading)
                            }
                        }
                        
                        // skin conditions field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Skin Conditions")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("e.g., acne, eczema, sensitive skin (or \"none\" if no conditions)", text: $skinConditions, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                                .frame(maxWidth: 300)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    isTextFieldFocused = false
                                }
                            
                            Text("Describe any skin conditions or write \"none\" if you have no conditions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: 300, alignment: .leading)
                        }
                        
                        // save button
                        Button(action: {
                            saveSettings()
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isSaving ? "Saving..." : "Save Settings")
                            }
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color(red: 235/255, green: 205/255, blue: 170/255))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.headline)
                        }
                        .disabled(isSaving || age.isEmpty)
                        
                        if showSuccessMessage {
                            Text("✅ Settings saved successfully!")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        // Sign out button
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color(red: 139/255, green: 0/255, blue: 0/255))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
            }
            }
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255).ignoresSafeArea())
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            isTextFieldFocused = false
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    private func fetchUserData() {
        guard let uid = authManager.user?.uid else {
            print("No authenticated user found")
            isLoading = false
            return
        }
        
        print("SettingsView: Fetching user data for UID: \(uid)")
        
        FirestoreManager.shared.fetchUserData(uid: uid) { data in
            DispatchQueue.main.async {
                if let userData = data {
                    print("SettingsView: Successfully fetched user data")
                    self.userData = userData
                    
                    // current data
                    self.age = userData.age
                    self.skinConditions = userData.skinConditions
                    self.selectedSkinToneIndex = userData.skinToneIndex
                } else {
                    print("SettingsView: Failed to fetch user data")
                }
                self.isLoading = false
            }
        }
    }
    
    private func saveSettings() {
        guard let uid = authManager.user?.uid,
              let email = authManager.user?.email else {
            print("SettingsView: No authenticated user found")
            return
        }
        
        isSaving = true
        showSuccessMessage = false
        
        // Get the selected skin tone color
        let selectedSkinTone = selectedSkinToneIndex > 0 && selectedSkinToneIndex <= skinTones.count 
            ? skinTones[selectedSkinToneIndex - 1] 
            : Color.clear
        
        print("SettingsView: Saving settings - Age: \(age), Skin Tone: \(selectedSkinToneIndex), Conditions: \(skinConditions)")
        
        // Use Cerebras to analyze skin conditions and get severity score
        Task {
            do {
                let cerebrasService = CerebrasService()
                let severityScore = try await cerebrasService.analyzeSkinConditionSeverity(conditions: skinConditions)
                
                await MainActor.run {
                    // Save to Firebase with Cerebras analysis
                    FirestoreManager.shared.saveUserInfo(
                        uid: uid,
                        email: email,
                        age: age,
                        skinTone: selectedSkinTone,
                        conditions: skinConditions,
                        skinToneIndex: selectedSkinToneIndex,
                        severityScore: severityScore
                    )
                    
                    // Show success message
                    self.showSuccessMessage = true
                    self.isSaving = false
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                        self.showSuccessMessage = false
                    })
                }
            } catch {
                await MainActor.run {
                    print("SettingsView: Gemini analysis failed: \(error.localizedDescription)")
                    // Still save to Firebase with default severity score
                    FirestoreManager.shared.saveUserInfo(
                        uid: uid,
                        email: email,
                        age: age,
                        skinTone: selectedSkinTone,
                        conditions: skinConditions,
                        skinToneIndex: selectedSkinToneIndex,
                        severityScore: 1 // Default severity score
                    )
                    
                    self.showSuccessMessage = true
                    self.isSaving = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                        self.showSuccessMessage = false
                    })
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
