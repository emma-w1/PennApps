//
//  TopBar.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct Topbar: View {
    var body: some View {
        HStack {
           Image("Soliss")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .top)
        .frame(height: 60)

    }
}

#Preview {
    Topbar()
}

