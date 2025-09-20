//
//  Navbar.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct Navbar: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            History()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
                
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(Color(red: 161/255, green: 114/255, blue: 14/255)) 
    }
}

#Preview {
    Navbar()
}
