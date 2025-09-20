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
            VStack(spacing: 20) {
                Spacer()
                Text("HOME SCREEN")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Add test button for Gemini
                NavigationLink("🧪 Test AI Skin Analysis") {
                    GeminiTestView()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
