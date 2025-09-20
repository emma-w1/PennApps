//
//  ContentView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

// main home page

import SwiftUI
import FirebaseFirestore
import UserNotifications

struct ContentView: View {
    //all user data / sensor data needed
    @EnvironmentObject var authManager: AuthManager
    @State private var userData: UserData?
    @State private var isLoading = true
    @State private var uvIntensity: Int?
    @State private var isLoadingUV = true
    @State private var uvListener: ListenerRegistration?
    @State private var userDocListener: ListenerRegistration?
    @State private var lastNotifiedUVLevel: Int? = nil
    @State private var lastAppliedDate: Date?
    @State private var lastIsPressedState: Bool = false
    @State private var aiSummary = ""
    @State private var isLoadingSummary = false
    @State private var summaryError = ""
    @State private var riskScoreBaseline: String?
    @State private var dynamicRiskCategory: String?
    
    private let geminiService = GeminiService()
    
    //possible skin tones to pick from
    let skinTones: [Color] = [
        Color(red: 244/255, green: 208/255, blue: 177/255),
        Color(red: 231/255, green: 180/255, blue: 143/255),
        Color(red: 210/255, green: 159/255, blue: 124/255),
        Color(red: 186/255, green: 120/255, blue: 81/255),
        Color(red: 165/255, green: 94/255, blue: 43/255),
        Color(red: 60/255, green: 31/255, blue: 29/255)
    ]
    
    //widget colors to randomize
    let widgetColors: [Color] = [
        Color(red: 235/255, green: 205/255, blue: 170/255), // light orange
        Color(red: 200/255, green: 240/255, blue: 200/255), // light green
        Color(red: 255/255, green: 248/255, blue: 220/255)  // light yellow
    ]
    
    //random colors for each widget
    @State private var riskScoreColor: Color = Color(red: 235/255, green: 205/255, blue: 170/255)
    @State private var aiSummaryColor: Color = Color(red: 200/255, green: 240/255, blue: 200/255)
    @State private var uvIntensityColor: Color = Color(red: 235/255, green: 205/255, blue: 170/255)
    @State private var lastAppliedColor: Color = Color(red: 255/255, green: 248/255, blue: 220/255)
    @State private var userInfoColor: Color = Color(red: 200/255, green: 240/255, blue: 200/255)
    
    var body: some View {
        NavigationStack {
            //topbar
            Topbar()
                .padding(.top, 0)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20){

                    //risk score (final)
                    VStack (alignment: .center, spacing: 10) {
                        Text("Risk Score")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            if isLoadingUV {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let dynamicRisk = dynamicRiskCategory {
                                Text(dynamicRisk)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(dynamicRisk.lowercased().contains("high") ? .red : 
                                                   dynamicRisk.lowercased().contains("medium") ? .orange : .green)
                            } else if let riskScoreBaseline = riskScoreBaseline {
                                Text(riskScoreBaseline)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(riskScoreBaseline.lowercased().contains("high") ? .red : 
                                                   riskScoreBaseline.lowercased().contains("medium") ? .orange : .green)
                            } else {
                                Text("--")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(riskScoreColor)
                        )

                    // ai skin summary based on demographics, UV, risk score
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
                        //default message
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
                        //loading message
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
                            .fill(aiSummaryColor)
                    )

                    //load in the UV intensity from the firebase sensor data
                    HStack {
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
                                .fill(uvIntensityColor)
                        )
                        
                        //last time sunscreen was applied from the button sensor data
                        VStack (alignment: .center, spacing: 10) {
                            Text("Sunscreen Last Applied")
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
                                .fill(lastAppliedColor)
                        )
                    }
                    
                    //user demographics like skin tone , disease, age, email
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
                                
                                //skin tone
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
                                    //conditions
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
                            .fill(userInfoColor)
                    )
                    
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .padding(.top, 0)
        }
        .onAppear {
            assignRandomColors()
            fetchUserData()
            fetchLastAppliedDate()
            startUVIntensityListener()
            startUserDocumentListener()
            requestNotificationPermissions()
        }
        .onDisappear {
            stopUVIntensityListener()
            stopUserDocumentListener()
        }
    }
    
    //assign random colors to widgets
    private func assignRandomColors() {
        riskScoreColor = widgetColors.randomElement() ?? widgetColors[0]
        aiSummaryColor = widgetColors.randomElement() ?? widgetColors[0]
        uvIntensityColor = widgetColors.randomElement() ?? widgetColors[0]
        lastAppliedColor = widgetColors.randomElement() ?? widgetColors[0]
        userInfoColor = widgetColors.randomElement() ?? widgetColors[0]
    }
    
    //fetch data like skin color, user data, sensor data
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
                    if let riskScore = userData.riskScoreBaseline {
                        print("Risk Score Baseline: \(riskScore)")
                    } else {
                        print("No risk score baseline found")
                    }
                } else {
                    print("Failed to fetch user data for UID: \(uid)")
                }
                self.userData = data
                self.riskScoreBaseline = data?.riskScoreBaseline
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
                        
                        // When UV intensity changes, fetch the updated risk category
                        self.fetchUpdatedRiskCategory()
                    } else {
                        print("ContentView: UV intensity is nil, showing --")
                    }
                }
            },
            isPressedCompletion: { isPressed, date in
                DispatchQueue.main.async {
                    print("ContentView: Received is_pressed update: \(isPressed), date: \(date?.description ?? "nil")")
                    print("ContentView: Previous is_pressed state: \(self.lastIsPressedState)")
                    print("ContentView: About to check if isPressed is true...")
                    
                    // Always update the date when is_pressed is true
                    if isPressed {
                        print("ContentView: ✅ isPressed is TRUE! Executing update logic...")
                        // Use provided date or current date if none provided
                        let dateToUse = date ?? Date()
                        print("ContentView: is_pressed is true, updating last applied date to: \(dateToUse)")
                        self.lastAppliedDate = dateToUse
                        self.saveLastAppliedDateToFirebase(date: dateToUse)
                        
                        // Send notification only when state changes from false to true
                        if !self.lastIsPressedState {
                            print("🎉 SUNSCREEN APPLIED! State changed from false to true!")
                            print("ContentView: Sending sunscreen applied notification...")
                            self.sendSunscreenAppliedNotification()
                        }
                    } else {
                        print("ContentView: is_pressed is false")
                    }
                    
                    self.lastIsPressedState = isPressed
                    print("ContentView: Updated lastIsPressedState to: \(self.lastIsPressedState)")
                    print("ContentView: Current lastAppliedDate: \(self.lastAppliedDate?.description ?? "nil")")
                }
            }
        )
    }
    
    private func startUserDocumentListener() {
        guard let uid = authManager.user?.uid else {
            print("ContentView: No user UID available for user document listener")
            return
        }
        
        print("Starting user document listener for risk category...")
        
        userDocListener = FirestoreManager.shared.listenToUserDocumentChanges(
            uid: uid,
            riskCategoryCompletion: { riskCategory in
                DispatchQueue.main.async {
                    print("ContentView: Received risk category update from user doc: \(riskCategory ?? "nil")")
                    self.dynamicRiskCategory = riskCategory
                }
            }
        )
    }
    
    private func stopUserDocumentListener() {
        print("Stopping user document listener...")
        userDocListener?.remove()
    }
    
    private func fetchUpdatedRiskCategory() {
        guard let uid = authManager.user?.uid else {
            print("ContentView: No user UID available for fetching risk category")
            return
        }
        
        print("ContentView: Fetching updated risk category due to UV change...")
        
        FirestoreManager.shared.fetchRiskCategory(uid: uid) { riskCategory in
            DispatchQueue.main.async {
                if let riskCategory = riskCategory {
                    print("ContentView: Updated risk category from UV change: \(riskCategory)")
                    self.dynamicRiskCategory = riskCategory
                } else {
                    print("ContentView: No risk category available")
                }
            }
        }
    }
    
    private func stopUVIntensityListener() {
        print("Stopping UV intensity listener...")
        uvListener?.remove()
        uvListener = nil
    }
    
    //allow sending notifications & check
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
    //sunscreen notifications
    private func checkForSunscreenNotification(uvIntensity: Int) {
        if uvIntensity >= 10 {
            if lastNotifiedUVLevel != uvIntensity {
                print("🌞 High UV intensity detected: \(uvIntensity). Sending sunscreen notification.")
                lastNotifiedUVLevel = uvIntensity
                sendSunscreenNotification(uvIntensity: uvIntensity)
            }
        } else {
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
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
    
    //date format
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
                // severity score from Firebase, otherwise calculate it
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
                    severityScore = 1
                }
                
                // Generate personalized summary
                let summary = try await geminiService.generateUserSummary(
                    age: userData.age,
                    skinConditions: userData.skinConditions,
                    severityScore: severityScore,
                    riskScoreBaseline: riskScoreBaseline,
                    skinToneIndex: userData.skinToneIndex
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
