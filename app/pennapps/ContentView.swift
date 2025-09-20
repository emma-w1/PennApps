//
//  ContentView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var userData: UserData?
    @State private var isLoading = true
    @State private var uvIntensity: Int?
    @State private var isLoadingUV = true
    @State private var uvListener: ListenerRegistration?
    @State private var lastNotifiedUVLevel: Int? = nil
    @State private var lastAppliedDate: Date?
    @State private var lastIsPressedState: Bool = false
    @State private var aiSummary = ""
    @State private var isLoadingSummary = false
    @State private var summaryError = ""
    
    private let geminiService = GeminiService()
    
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
                            Text("Current UV Intensity")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            if isLoadingUV {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let uvIntensity = uvIntensity {
                                Text("\(uvIntensity)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(uvIntensity >= 10 ? .red : .black)
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
                            
                            if let lastAppliedDate = lastAppliedDate {
                                Text(formatDate(lastAppliedDate))
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("Never")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
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
                                
                                // Skin tone
                                Circle()
                                    .fill(getSkinToneColor(for: userData.skinToneIndex))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                
                                // User info 
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
                    
                    VStack (alignment: .leading, spacing: 15) {
                        HStack {
                            Text("🤖 AI Skin Summary")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Button(action: {
                                generateAISummary()
                            }) {
                                HStack(spacing: 6) {
                                    if isLoadingSummary {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                    }
                                    Text(isLoadingSummary ? "Generating..." : "Generate")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(isLoadingSummary || userData == nil)
                        }
                        
                        if !summaryError.isEmpty {
                            Text("\(summaryError)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        if aiSummary.isEmpty && !isLoadingSummary && summaryError.isEmpty {
                            Text("Get personalized skin care tips and UV protection advice based on your profile. Tap 'Generate' to create your AI-powered summary!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .italic()
                        } else if !aiSummary.isEmpty {
                            ScrollView {
                                Text(aiSummary)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        if isLoadingSummary {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing your profile and generating personalized recommendations...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(red: 200/255, green: 240/255, blue: 200/255))
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .padding(.top, 0)
        }
        .onAppear {
            fetchUserData()
            fetchLastAppliedDate()
            startUVIntensityListener()
            requestNotificationPermissions()
        }
        .onDisappear {
            stopUVIntensityListener()
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
    
    private func fetchLastAppliedDate() {
        print("Fetching last applied date from users/latest document")
        
        FirestoreManager.shared.fetchLastAppliedDate { date in
            DispatchQueue.main.async {
                if let date = date {
                    print("Successfully fetched last applied date: \(date)")
                    self.lastAppliedDate = date
                } else {
                    print("No last applied date found in latest document")
                }
            }
        }
    }
    
    private func startUVIntensityListener() {
        print("Starting UV intensity and is_pressed real-time listener...")
        
        uvListener = FirestoreManager.shared.listenToLatestDocumentChanges(
            uvCompletion: { uvIntensity in
                DispatchQueue.main.async {
                    print("ContentView: Received UV intensity update: \(uvIntensity ?? -999)")
                    self.uvIntensity = uvIntensity
                    self.isLoadingUV = false
                    if let uvIntensity = uvIntensity {
                        print("ContentView: Setting UV intensity to: \(uvIntensity)")
                        self.checkForSunscreenNotification(uvIntensity: uvIntensity)
                    } else {
                        print("ContentView: UV intensity is nil, showing --")
                    }
                }
            },
            isPressedCompletion: { isPressed, date in
                DispatchQueue.main.async {
                    print("ContentView: Received is_pressed update: \(isPressed), date: \(date?.description ?? "nil")")
                    print("ContentView: Previous is_pressed state: \(self.lastIsPressedState)")
                    
                    // Check if is_pressed just became true (sunscreen applied)
                    if isPressed && !self.lastIsPressedState {
                        print("🎉 SUNSCREEN APPLIED! State changed from false to true!")
                        print("ContentView: Sending sunscreen applied notification...")
                        self.sendSunscreenAppliedNotification()
                        if let date = date {
                            self.lastAppliedDate = date
                            self.saveLastAppliedDateToFirebase(date: date)
                        }
                    } else if isPressed && date != nil {
                        // Update the date even if we already knew is_pressed was true
                        print("ContentView: is_pressed is true, updating date...")
                        self.lastAppliedDate = date
                        self.saveLastAppliedDateToFirebase(date: date!)
                    } else if !isPressed {
                        print("ContentView: is_pressed is false")
                    }
                    
                    self.lastIsPressedState = isPressed
                    print("ContentView: Updated lastIsPressedState to: \(self.lastIsPressedState)")
                }
            }
        )
    }
    
    private func stopUVIntensityListener() {
        print("Stopping UV intensity listener...")
        uvListener?.remove()
        uvListener = nil
    }
    
    private func requestNotificationPermissions() {
        print("Requesting notification permissions...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }
    
    private func checkForSunscreenNotification(uvIntensity: Int) {
        // Check if UV intensity is 10 or higher
        if uvIntensity >= 10 {
            // Only send notification if we haven't already notified for this level
            if lastNotifiedUVLevel != uvIntensity {
                print("🌞 High UV intensity detected: \(uvIntensity). Sending sunscreen notification.")
                lastNotifiedUVLevel = uvIntensity
                sendSunscreenNotification(uvIntensity: uvIntensity)
            }
        } else {
            // Reset the notified level when UV goes below 10
            if lastNotifiedUVLevel != nil {
                print("UV intensity dropped below 10. Resetting notification state.")
                lastNotifiedUVLevel = nil
            }
        }
    }
    
    private func sendSunscreenNotification(uvIntensity: Int) {
        print("🔔 Attempting to send UV sunscreen reminder notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "🌞 Sunscreen Reminder"
        content.body = "UV intensity is \(uvIntensity)! Please apply/re-apply sunscreen to protect your skin from harmful UV rays."
        content.sound = .default
        content.badge = 1
        
        // Create immediate notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create unique identifier for this notification
        let identifier = "sunscreen_reminder_\(uvIntensity)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Check notification settings first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 UV Notification settings check:")
            print("   Authorization status: \(settings.authorizationStatus.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                // Add the notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule UV sunscreen notification: \(error.localizedDescription)")
                    } else {
                        print("✅ UV sunscreen notification scheduled successfully for UV level: \(uvIntensity)")
                    }
                }
            } else {
                print("❌ UV Notifications not authorized. Status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func sendSunscreenAppliedNotification() {
        print("🔔 Attempting to send sunscreen applied notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Sunscreen Applied!"
        content.body = "Great job! You've applied sunscreen to protect your skin."
        content.sound = .default
        content.badge = 1
        
        // Create immediate notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create unique identifier for this notification
        let identifier = "sunscreen_applied_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Check notification settings first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Current notification settings:")
            print("   Authorization status: \(settings.authorizationStatus.rawValue)")
            print("   Alert setting: \(settings.alertSetting.rawValue)")
            print("   Badge setting: \(settings.badgeSetting.rawValue)")
            print("   Sound setting: \(settings.soundSetting.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                // Add the notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule sunscreen applied notification: \(error.localizedDescription)")
                    } else {
                        print("✅ Sunscreen applied notification scheduled successfully")
                    }
                }
            } else {
                print("❌ Notifications not authorized. Status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveLastAppliedDateToFirebase(date: Date) {
        print("Saving last applied date to Firebase latest document: \(date)")
        FirestoreManager.shared.saveLastAppliedDate(date: date)
    }
    private func generateAISummary() {
        guard let userData = userData else {
            summaryError = "No user data available. Please ensure your profile is complete."
            return
        }
        
        isLoadingSummary = true
        summaryError = ""
        aiSummary = ""
        
        print("🤖 Generating AI summary for user: Age=\(userData.age), Conditions=\(userData.skinConditions)")
        
        Task {
            do {
                // Get severity score from Firebase if available, otherwise calculate it
                let severityScore: Int
                if let uid = authManager.user?.uid {
                    if let firebaseData = try? await FirestoreManager.shared.getUserData(uid: uid),
                       let storedSeverity = firebaseData["conditionSeverity"] as? Int {
                        severityScore = storedSeverity
                        print("📊 Using stored severity score: \(severityScore)")
                    } else {
                        // Calculate severity if not stored
                        severityScore = try await geminiService.analyzeSkinConditionSeverity(conditions: userData.skinConditions)
                        print("🔍 Calculated severity score: \(severityScore)")
                    }
                } else {
                    severityScore = 1 // Default fallback
                }
                
                // Generate personalized summary
                let summary = try await geminiService.generateUserSummary(
                    age: userData.age,
                    skinConditions: userData.skinConditions,
                    severityScore: severityScore
                )
                
                await MainActor.run {
                    isLoadingSummary = false
                    aiSummary = summary
                    print("✅ AI Summary generated successfully")
                }
                
            } catch {
                await MainActor.run {
                    isLoadingSummary = false
                    summaryError = "Failed to generate summary: \(error.localizedDescription)"
                    print("❌ AI Summary generation failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
