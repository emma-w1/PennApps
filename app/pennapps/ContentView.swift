//
//  ContentView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var userData: UserData?
    @State private var isLoading = true
    
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
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20){
                    VStack(spacing: 10) {
                        Text("Demographics")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let userData = userData {
                            VStack(alignment: .center, spacing: 8) {
                                // Email display
                                Text("User: \(userData.email)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 5)
                                
                                HStack(alignment: .center, spacing: 20) {
                                    // Skin tone circle
                                    Circle()
                                        .fill(userData.skinToneIndex > 0 && userData.skinToneIndex <= skinTones.count ? 
                                              skinTones[userData.skinToneIndex - 1] : Color.gray)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 2)
                                        )
                                    
                                    VStack(alignment: .center, spacing: 5) {
                                        Text("Age: \(userData.age)")
                                            .font(.body)
                                            .foregroundColor(.black)
                                        
                                        Text("Skin Tone: \(userData.skinToneIndex)")
                                            .font(.body)
                                            .foregroundColor(.black)
                                        
                                        if !userData.skinConditions.isEmpty {
                                            Text("Conditions: \(userData.skinConditions)")
                                                .font(.body)
                                                .foregroundColor(.black)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        } else {
                            Text("No demographic data available")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(red: 235/255, green: 205/255, blue: 170/255))
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    private func fetchUserData() {
        guard let uid = authManager.user?.uid, let email = authManager.user?.email else {
            print("No authenticated user found")
            isLoading = false
            return
        }
        
        print("Fetching user data for UID: \(uid), Email: \(email)")
        
        FirestoreManager.shared.fetchUserData(uid: uid) { data in
            DispatchQueue.main.async {
                if let userData = data {
                    print("Successfully fetched user data for: \(userData.email)")
                    print("User data - Age: \(userData.age), Skin Tone: \(userData.skinToneIndex), Conditions: \(userData.skinConditions)")
                } else {
                    print("Failed to fetch user data for UID: \(uid)")
                }
                self.userData = data
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
