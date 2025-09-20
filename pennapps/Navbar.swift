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
            HStack{
                NavigationLink (destination: ContentView()) {
                    VStack{
                        Image(systemName: "house.fill")
                        Text("Home").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                NavigationLink (destination: History()) {
                    VStack {
                        Image(systemName: "clock.fill")
                        Text("History").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                NavigationLink(destination: SettingsView()) {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .background(Color.yellow)
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    Navbar()
}
