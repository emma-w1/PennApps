//
//  UserInfoCard.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import SwiftUI

struct UserInfoCard: View {
    let userData: UserData?
    let isLoading: Bool
    
    var body: some View {
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
                    Text("User: \(userData.email)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Skin tone indicator
                    Circle()
                        .fill(getSkinToneColor(for: userData.skinToneIndex))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                    
                    // User details
                    VStack(alignment: .center, spacing: 4) {
                        Text("Age: \(userData.age)")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("Conditions: \(userData.skinConditions.isEmpty ? "None" : userData.skinConditions)")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            } else {
                Text("Failed to load user data")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.cardBackground)
        )
    }
    
    private func getSkinToneColor(for index: Int) -> Color {
        guard index > 0 && index <= Color.skinTones.count else {
            return Color.gray
        }
        return Color.skinTones[index - 1]
    }
}

#Preview {
    UserInfoCard(
        userData: UserData(
            email: "test@example.com",
            age: "25",
            skinToneIndex: 3,
            skinConditions: "Sensitive skin",
            baselineRiskScore: 1.2,
            baselineRiskCategory: "Medium",
            finalRiskScore: 1.5,
            finalRiskCategory: "High"
        ),
        isLoading: false
    )
}
