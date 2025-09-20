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
    @State private var uvIndex: Int?
    @State private var isLoadingUV = true
    
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
                .padding(.top, 0)
                .padding(.bottom, 10)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20){
                    HStack(spacing: 16) {
                        VStack (alignment: .center, spacing: 10) {
                            Text("Current UV Index")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            if isLoadingUV {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let uvIndex = uvIndex {
                                Text("\(uvIndex)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                .padding(.top, 0)
                .padding(.bottom, 10)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20){
                    HStack(spacing: 16) {
                        VStack (alignment: .center, spacing: 10) {
                            Text("Current UV Index")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            if isLoadingUV {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let uvIndex = uvIndex {
                                Text("\(uvIndex)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            } else {
                                Text("--")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 235/255, green: 205/255, blue: 170/255))
                        )
                        
                        VStack (alignment: .center, spacing: 10) {
                            Text("Last Applied")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            Text("Placeholder")
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 235/255, green: 205/255, blue: 170/255))
                        )
                    }
                    
                    VStack(alignment: .center, spacing: 10) {
                        Text("User Info")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let userData = userData {
                            VStack(alignment: .center, spacing: 12) {
                                // Email display
                                Text("User: \(userData.email)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                // Skin tone circle (centered)
                                Circle()
                                    .fill(getSkinToneColor(for: userData.skinToneIndex))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                
                                // User info (centered)
                                VStack(alignment: .center, spacing: 4) {
                                    Text("Age: \(userData.age)")
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Skin Tone: \(userData.skinToneIndex)")
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                    
                                    if !userData.skinConditions.isEmpty {
                                        Text("Conditions: \(userData.skinConditions)")
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        } else {
                            Text("No demographic data available")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(red: 235/255, green: 205/255, blue: 170/255))
                    )
                    
                    VStack (alignment: .center, spacing: 10) {
                        Text("AI Skin Analysis")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        VStack(spacing: 12) {
                            // Summarize button - main feature
                            NavigationLink("📋 Get My Skin Summary & Tips") {
                                UserSummaryView()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.medium)
                            
                            // Add test button for Gemini
                            NavigationLink("🧪 Test AI Analysis") {
                                GeminiTestView()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(red: 235/255, green: 205/255, blue: 170/255))
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .padding(.top, 0)
        }
        .onAppear {
            fetchUserData()
            fetchUVIndex()
        }
    }
    
    private func getSkinToneColor(for index: Int) -> Color {
        guard index > 0 && index <= skinTones.count else {
            return Color.gray
        }
        return skinTones[index - 1]
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
    
    private func fetchUVIndex() {
        print("Fetching UV index from latest document...")
        
        FirestoreManager.shared.fetchLatestUVIndex { uvIndex in
            DispatchQueue.main.async {
                self.uvIndex = uvIndex
                self.isLoadingUV = false
                if let uvIndex = uvIndex {
                    print("Successfully fetched UV index: \(uvIndex)")
                } else {
                    print("Failed to fetch UV index or no data available")
>>>>>>> 65b36984a71b609597e9dde8cb7afee12a5d3421
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
