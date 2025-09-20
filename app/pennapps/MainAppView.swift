//
//  MainAppView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var authManager = AuthManager()
    
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
    }
}

#Preview {
    MainAppView()
}
