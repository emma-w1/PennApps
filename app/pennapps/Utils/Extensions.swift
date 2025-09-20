//
//  Extensions.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import SwiftUI

// MARK: - Date Formatting

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Color Helpers

extension Color {
    /// App's primary background color
    static let appBackground = Color(red: 255/255, green: 247/255, blue: 217/255)
    
    /// Card background color
    static let cardBackground = Color(red: 235/255, green: 205/255, blue: 170/255)
    
    /// Accent color for interactive elements
    static let appAccent = Color(red: 161/255, green: 114/255, blue: 14/255)
    
    /// Skin tone colors array
    static let skinTones: [Color] = [
        Color(red: 244/255, green: 208/255, blue: 177/255),
        Color(red: 231/255, green: 180/255, blue: 143/255),
        Color(red: 210/255, green: 159/255, blue: 124/255),
        Color(red: 186/255, green: 120/255, blue: 81/255),
        Color(red: 165/255, green: 94/255, blue: 43/255),
        Color(red: 60/255, green: 31/255, blue: 29/255)
    ]
}

// MARK: - UV Risk Helpers

extension Int {
    /// Get color for UV intensity level
    var uvColor: Color {
        return self >= 10 ? .red : .black
    }
    
    /// Get color for risk level (0-5 scale)
    var riskColor: Color {
        switch self {
        case 0: return .green
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .red
        default: return .gray
        }
    }
}
