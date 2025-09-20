//
//  LastAppliedCard.swift
//  pennapps
//
//  Created by Adishree Das on 9/20/25.
//

import SwiftUI

struct LastAppliedCard: View {
    let lastAppliedDate: Date?
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Last Applied")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            if let lastAppliedDate = lastAppliedDate {
                Text(lastAppliedDate.formatted())
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            } else {
                Text("Never")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
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
    LastAppliedCard(lastAppliedDate: Date())
}
