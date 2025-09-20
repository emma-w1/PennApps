import SwiftUI

/// Debug view to test Gemini skin condition analysis
struct GeminiTestView: View {
    @State private var testCondition = ""
    @State private var result = ""
    @State private var isLoading = false
    
    private let geminiService = GeminiService()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 Gemini Skin Condition Test")
                .font(.title2)
                .fontWeight(.bold)
            
            // Configuration status
            Text(Config.shared.getSafeStatus())
                .font(.caption)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Test input
            VStack(alignment: .leading) {
                Text("Enter skin conditions to test:")
                    .font(.caption)
                
                TextField("e.g., acne, eczema, none", text: $testCondition)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Test button
            Button(action: {
                testAnalysis()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Analyzing..." : "Test AI Analysis")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading || testCondition.isEmpty)
            
            // Result display
            if !result.isEmpty {
                VStack(alignment: .leading) {
                    Text("Result:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(result)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Quick test buttons
            VStack(alignment: .leading) {
                Text("Quick Tests:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack {
                    ForEach(["none", "acne", "eczema", "lupus"], id: \.self) { condition in
                        Button(condition) {
                            testCondition = condition
                            testAnalysis()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.3))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func testAnalysis() {
        isLoading = true
        result = ""
        
        Task {
            do {
                let severity = try await geminiService.analyzeSkinConditionSeverity(conditions: testCondition)
                
                await MainActor.run {
                    isLoading = false
                    result = """
                    Input: "\(testCondition)"
                    Severity Score: \(severity)
                    Risk Level: \(getRiskDescription(severity))
                    """
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    result = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getRiskDescription(_ severity: Int) -> String {
        switch severity {
        case 0: return "No additional UV risk"
        case 1: return "Minimal UV risk"
        case 2: return "Low UV risk"
        case 3: return "Moderate UV risk"
        case 4: return "High UV risk"
        case 5: return "Severe UV risk"
        default: return "Unknown"
        }
    }
}

#Preview {
    GeminiTestView()
}
