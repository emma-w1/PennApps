//
//  pennappsApp.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI
import FirebaseCore
import UserNotifications

//firebase config
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase configured successfully")
        
        // Initialize configuration without async operations in AppDelegate
        Config.shared.initializeApp()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground: \(notification.request.content.title)")
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification tapped: \(response.notification.request.content.title)")
        completionHandler()
    }
}

@main
struct pennappsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        //navbar styling bc it wasnt working
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.white 
        UITabBar.appearance().tintColor = UIColor(red: 161/255, green: 114/255, blue: 14/255, alpha: 1.0) 
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 161/255, green: 114/255, blue: 14/255, alpha: 1.0)] 
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 161/255, green: 114/255, blue: 14/255, alpha: 1.0) 
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .white
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
        }
    }
}
