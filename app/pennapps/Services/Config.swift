//
//  Config.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

/// Configuration manager for app settings and API keys
/// Note: GeminiService now handles its own API key loading
class Config {
    static let shared = Config()
    
    private init() {}
    
    // MARK: - App Initialization
    
    /// Initialize app configurations
    func initializeApp() {
        print("🚀 Initializing app configuration...")
        print(getConfigurationStatus())
        print("✅ App configuration completed")
    }
    
    // MARK: - Debug & Status
    
    /// Get configuration status for debugging
    func getConfigurationStatus() -> String {
        // Since GeminiService now handles its own secrets, we delegate to it
        return "🔐 App Configuration Status:\n" + getCerebrasStatus()
    }
    
    /// Get safe status for production logging
    func getSafeStatus() -> String {
        return """
        🔐 Configuration Status:
        Cerebras: \(hasCerebrasKey() ? "✅ Ready" : "❌ Missing")
        """
    }
    
    // MARK: - Private Helpers
    
    private func getCerebrasStatus() -> String {
        // Check via GeminiService's own key detection
        return hasCerebrasKey() ? "✅ Cerebras API Key: Available" : "❌ Cerebras API Key: Not configured"
    }
    
    private func hasCerebrasKey() -> Bool {
        // Check if GeminiService can find its API key
        if let env = ProcessInfo.processInfo.environment["CEREBRAS_API_KEY"], !env.isEmpty {
            return true
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "CEREBRAS_API_KEY") as? String, !key.isEmpty {
            return true
        }
        return false
    }
}
