//
//  HistoryEntry.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import Foundation

//swift data to store user's history
struct HistoryEntry: Identifiable {
    let id: String
    let date: String
    let time: String
    let uv: Int
    let timestamp: Date
}
