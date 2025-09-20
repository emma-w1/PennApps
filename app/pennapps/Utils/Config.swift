import Foundation
import SwiftUI

/// Comprehensive configuration manager for app settings and API keys
/// makes sensitive .env file available to app parts
class Config {
    static let shared = Config()
    
    private var environment: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    /// Load environment variables from .env file
    private func loadEnvironmentVariables() {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found in bundle")
            loadFromProcessEnvironment()
            return
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath)
            parseEnvironmentContent(envContent)
        } catch {
            print("⚠️ Failed to read .env file: \(error)")
            loadFromProcessEnvironment()
        }
    }
    
    /// Parse .env file content
    private func parseEnvironmentContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Parse KEY=VALUE format
            let components = trimmedLine.components(separatedBy: "=")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                environment[key] = value
            }
        }
        
        print("✅ Loaded \(environment.count) environment variables from .env file")
    }
    
    /// Fallback to process environment variables
    private func loadFromProcessEnvironment() {
        environment["CEREBRAS_API_KEY"] = ProcessInfo.processInfo.environment["CEREBRAS_API_KEY"]
        
        print("📱 Loaded environment variables from process environment")
    }
    
    
    /// Securely get API key with validation
    private func getAPIKey(_ key: String) -> String? {
        let value = environment[key]
        
        // Validate that it's not a placeholder
        if let value = value,
           !value.isEmpty,
           !value.contains("your_") && !value.contains("_here") {
            return value
        }
        
        return nil
    }
        
    /// Get Cerebras API Key
    var cerebrasAPIKey: String? {
        return getAPIKey("CEREBRAS_API_KEY")
    }
    
    /// Check if Cerebras key is properly configured
    var hasValidCerebrasKey: Bool {
        return cerebrasAPIKey != nil
    }
        
    /// Initialize app configurations
    func initializeApp() {
        print("🚀 Initializing app configuration...")
        print(getConfigurationStatus())
        print("✅ App configuration completed")
    }
        
    /// Get comprehensive configuration status for debugging
    func getConfigurationStatus() -> String {
        var status = "🔐 App Configuration Status:\n"
        
        // Cerebras Status
        if let key = cerebrasAPIKey {
            let maskedKey = String(key.prefix(10)) + "..." + String(key.suffix(4))
            status += "✅ Cerebras API Key: \(maskedKey)\n"
        } else {
            status += "❌ Cerebras API Key: Not configured\n"
        }
        
        return status
    }
    
    /// Get safe status for production logging
    func getSafeStatus() -> String {
        return """
        🔐 Configuration Status:
        Cerebras: \(hasValidCerebrasKey ? "✅ Ready" : "❌ Missing")
        """
    }
    
    /// Test function to verify Cerebras integration
    func testCerebrasIntegration() async {
        print("🧪 Testing Cerebras Integration...")
        print(getConfigurationStatus())
        
        let cerebras = CerebrasService()
        
        // Test cases
        let testCases = [
            "none",
            "acne",
            "eczema, sensitive skin",
            "lupus, photosensitive"
        ]
        
        for testCase in testCases {
            do {
                let result = try await cerebras.analyzeSkinConditionSeverity(conditions: testCase)
                print("✅ Test: '\(testCase)' → Severity: \(result)")
            } catch {
                print("❌ Test failed for '\(testCase)': \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get Cerebras API Key with fallback
    func getCerebrasAPIKey() -> String? {
        return cerebrasAPIKey
    }
    
    /// Check if Cerebras is ready
    func hasCerebrasKey() -> Bool {
        return hasValidCerebrasKey
    }
    
    /// Get Cerebras status for debugging
    func getCerebrasStatus() -> String {
        if hasValidCerebrasKey {
            return "✅ Cerebras API Ready"
        } else {
            return "❌ Cerebras API Key Missing"
        }
    }
}
