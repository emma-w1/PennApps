//
//  pennappsApp.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

@main
struct pennappsApp: App {
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        UITabBar.appearance().tintColor = UIColor.white
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .white
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]

    }
    
    var body: some Scene {
        WindowGroup {
            Navbar()
        }
    }
}
