//
//  MainAppView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var authManager = AuthManager()
    @State private var hasTestedGemini = false
    
    var body: some View {
            
            Group {
                if authManager.isAuthenticated {
                    // show home if logged in
                    Navbar()
                } else {
                    // show login if not logged in
                    LoginView()
                }
            }
            .background(Color(red: 255/255, green: 247/255, blue: 217/255))
            .environmentObject(authManager)
            .onAppear {
                // Test Gemini integration safely after view appears
                if !hasTestedGemini {
                    hasTestedGemini = true
                    testGeminiIntegration()
                }
            }
    }
    
    private func testGeminiIntegration() {
        Task {
            print("🧪 Testing Gemini Integration...")
            
            let config = Config.shared
            print(config.getConfigurationStatus())
            
            let gemini = GeminiService()
            
            // Test a few quick cases
            let testCases = ["none", "acne"]
            
            for testCase in testCases {
                do {
                    let result = try await gemini.analyzeSkinConditionSeverity(conditions: testCase)
                    print("✅ Test: '\(testCase)' → Severity: \(result)")
                } catch {
                    print("❌ Test failed for '\(testCase)': \(error)")
                }
            }
        }
    }
}

#Preview {
    MainAppView()
}
