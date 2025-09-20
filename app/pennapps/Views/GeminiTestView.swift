import SwiftUI

struct GeminiTestView: View {
    @StateObject private var geminiService = GeminiService()
    @State private var testResults: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Gemini API Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                if isLoading {
                    ProgressView("Testing Gemini API...")
                        .padding()
                }
                
                Button("Run Gemini Tests") {
                    runTests()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                List(testResults, id: \.self) { result in
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(result.contains("✅") ? .green : result.contains("❌") ? .red : .primary)
                }
            }
            .padding()
            .navigationTitle("Gemini Test")
        }
    }
    
    private func runTests() {
        isLoading = true
        testResults.removeAll()
        
        Task {
            await testSkinConditionAnalysis()
            await testUserSummaryGeneration()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func testSkinConditionAnalysis() async {
        let testCases = [
            "none",
            "acne",
            "eczema",
            "psoriasis",
            "melanoma"
        ]
        
        await MainActor.run {
            testResults.append("🧪 Testing Skin Condition Analysis...")
        }
        
        for testCase in testCases {
            do {
                let severity = try await geminiService.analyzeSkinConditionSeverity(conditions: testCase)
                await MainActor.run {
                    testResults.append("✅ '\(testCase)' → Severity: \(severity)")
                }
            } catch {
                await MainActor.run {
                    testResults.append("❌ '\(testCase)' → Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testUserSummaryGeneration() async {
        await MainActor.run {
            testResults.append("\n🧪 Testing User Summary Generation...")
        }
        
        let testCases = [
            (age: 22, conditions: ["acne"]),
            (age: 35, conditions: ["none"]),
            (age: 45, conditions: ["eczema", "rosacea"])
        ]
        
        for testCase in testCases {
            do {
                let summary = try await geminiService.generateUserSummary(
                    age: testCase.age,
                    skinConditions: testCase.conditions
                )
                await MainActor.run {
                    testResults.append("✅ Age \(testCase.age), \(testCase.conditions.joined(separator: ", "))")
                    testResults.append("   Summary: \(summary.prefix(100))...")
                }
            } catch {
                await MainActor.run {
                    testResults.append("❌ Age \(testCase.age) → Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    GeminiTestView()
}