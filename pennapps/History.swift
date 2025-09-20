//
//  History.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct History: View {
    var body: some View {
        NavigationStack {
            Text("HISTORY")
            Spacer()
            Navbar()
                .frame(maxWidth: .infinity)
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255))
    }
}

#Preview {
    History()
}
