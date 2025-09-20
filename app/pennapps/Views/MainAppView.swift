//
//  MainAppView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var authManager = AuthManager()
    @State private var hasTestedCerebras = false
    
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
            .background(Color.appBackground)
            .environmentObject(authManager)
            .onAppear {
                // Test Cerebras integration safely after view appears
                if !hasTestedCerebras {
                    hasTestedCerebras = true
                    testCerebrasIntegration()
                }
            }
    }
    
    private func testCerebrasIntegration() {
        Task {
            print("🧪 Testing Cerebras Integration...")
            
            let config = Config.shared
            print(config.getConfigurationStatus())
            
            let cerebras = GeminiService()
            
            // Test a few quick cases
            let testCases = ["none", "acne"]
            
            for testCase in testCases {
                do {
                    let result = try await cerebras.analyzeSkinConditionSeverity(conditions: testCase)
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
