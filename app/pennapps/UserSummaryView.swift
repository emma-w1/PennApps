import SwiftUI
import FirebaseAuth

/// View that displays personalized user summary and skin care tips
struct UserSummaryView: View {
    @State private var summary = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var userAge = ""
    @State private var userConditions = ""
    @State private var severityScore = 0
    
    private let geminiService = GeminiService()
    private let firestoreManager = FirestoreManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("📋 Your Skin Profile Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Personalized tips based on your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // User info display
                if !userAge.isEmpty || !userConditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📊 Your Profile")
                            .font(.headline)
                        
                        HStack {
                            Text("Age:")
                                .fontWeight(.medium)
                            Text(userAge.isEmpty ? "Not specified" : "\(userAge) years")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Skin Conditions:")
                                .fontWeight(.medium)
                            Text(userConditions.isEmpty ? "None specified" : userConditions)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("UV Risk Level:")
                                .fontWeight(.medium)
                            Text("\(severityScore)/5")
                                .fontWeight(.semibold)
                                .foregroundColor(getRiskColor(severityScore))
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Generate button
                Button(action: {
                    generateSummary()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(isLoading ? "Generating Summary..." : "🤖 Generate AI Summary & Tips")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Summary display
                if !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 Your Personalized Summary")
                            .font(.headline)
                        
                        Text(summary)
                            .font(.body)
                            .lineSpacing(4)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please log in to view your summary"
            return
        }
        
        Task {
            do {
                if let userData = try await firestoreManager.getUserData(uid: user.uid) {
                    await MainActor.run {
                        userAge = userData["age"] as? String ?? ""
                        userConditions = userData["skinConditions"] as? String ?? ""
                        severityScore = userData["conditionSeverity"] as? Int ?? 0
                        
                        print("Loaded user data: Age=\(userAge), Conditions=\(userConditions), Severity=\(severityScore)")
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "No user profile found. Please complete registration first."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load user data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func generateSummary() {
        guard !userAge.isEmpty && !userConditions.isEmpty else {
            errorMessage = "Complete user profile data is required for summary generation"
            return
        }
        
        isLoading = true
        errorMessage = ""
        summary = ""
        
        Task {
            do {
                let generatedSummary = try await geminiService.generateUserSummary(
                    age: userAge,
                    skinConditions: userConditions,
                    severityScore: severityScore
                )
                
                await MainActor.run {
                    isLoading = false
                    summary = generatedSummary
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to generate summary: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getRiskColor(_ score: Int) -> Color {
        switch score {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3: return .orange
        case 4: return .red
        case 5: return .red
        default: return .gray
        }
    }
}

#Preview {
    UserSummaryView()
}
