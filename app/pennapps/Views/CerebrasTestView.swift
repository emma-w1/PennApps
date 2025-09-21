import SwiftUI

struct CerebrasTestView: View {
    @StateObject private var cerebrasService = CerebrasService()
    @State private var testResults: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Cerebras API Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                if isLoading {
                    ProgressView("Testing Cerebras API...")
                        .padding()
                }
                
                Button("Run Cerebras Tests") {
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
            .navigationTitle("Cerebras Test")
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
                let severity = try await cerebrasService.analyzeSkinConditionSeverity(conditions: testCase)
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
            (age: 35, conditions: []),
            (age: 45, conditions: ["eczema", "rosacea"])
        ]
        
        for testCase in testCases {
            do {
                let summary = try await cerebrasService.generateUserSummary(
                    age: testCase.age,
                    skinConditions: testCase.conditions
                )
                await MainActor.run {
                    testResults.append("✅ Age \(testCase.age), \(testCase.conditions.isEmpty ? "No conditions" : testCase.conditions.joined(separator: ", "))")
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
    CerebrasTestView()
}
x
