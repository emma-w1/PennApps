//
//  SettingsView.swift
//  pennapps
//
//  Created by Adishree Das on 9/19/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("SETTINGS SCREEN")
            Spacer()
            Navbar()
                .frame(maxWidth: .infinity)
        }
        .background(Color(red: 255/255, green: 247/255, blue: 217/255))

    }
}

#Preview {
    SettingsView()
}
