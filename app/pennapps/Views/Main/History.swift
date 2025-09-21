//
//  History.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct History: View {
    @State private var historyEntries: [HistoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    private let firestoreManager = FirestoreManager.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Topbar()
                    .padding(.top, 0)
                // Header
                Text("HISTORY")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .padding(.top)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading history...")
                        .foregroundColor(.yellow)
                    Spacer()
                } else if !errorMessage.isEmpty {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    Spacer()
                } else if historyEntries.isEmpty {
                    Spacer()
                    Text("No history entries yet")
                        .foregroundColor(.yellow)
                        .font(.headline)
                    Text("Apply sunscreen to start tracking your history")
                        .foregroundColor(.yellow.opacity(0.8))
                        .font(.caption)
                    Spacer()
                } else {
                    // History entries list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyEntries) { entry in
                                HistoryEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            }
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255))
        .onAppear {
            loadHistoryEntries()
        }
        .refreshable {
            loadHistoryEntries()
        }
    }
    
    private func loadHistoryEntries() {
        isLoading = true
        errorMessage = ""
        
        firestoreManager.fetchHistoryEntries { entries in
            DispatchQueue.main.async {
                isLoading = false
                historyEntries = entries
            }
        }
    }
}

struct HistoryEntryCard: View {
    let entry: HistoryEntry
    
    var body: some View {
        HStack {
            // UV on the left
            VStack {
                Text("UV")
                    .font(.caption)
                    .foregroundColor(.brown)
                    .fontWeight(.medium)
                Text("\(entry.uv)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
            }
            .frame(width: 60)
            
            Spacer()
            
            // Date and time on the right
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.date)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
                Text(entry.time)
                    .font(.subheadline)
                    .foregroundColor(.brown.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brown.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    History()
}
