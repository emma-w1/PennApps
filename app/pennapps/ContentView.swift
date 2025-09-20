//
//  ContentView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("HOME SCREEN")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255))
    }
}

#Preview {
    ContentView()
}
