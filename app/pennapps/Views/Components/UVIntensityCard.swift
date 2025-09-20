//
//  UVIntensityCard.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import SwiftUI

struct UVIntensityCard: View {
    let uvIntensity: Int?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Current UV Intensity")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let uvIntensity = uvIntensity {
                Text("\(uvIntensity)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(uvIntensity.uvColor)
            } else {
                Text("--")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    UVIntensityCard(uvIntensity: 7, isLoading: false)
}
