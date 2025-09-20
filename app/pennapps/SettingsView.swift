//
//  SettingsView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("SETTINGS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    Text("Welcome, \(authManager.user?.email ?? "User")!")
                        .font(.headline)
                    
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255).ignoresSafeArea())
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
