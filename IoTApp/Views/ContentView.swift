//
//  ContentView.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab ("Home", systemImage: "house"){
                HomeView()
            }
                    
            Tab ("Heat map", systemImage: "map"){
                Heatmap()
            }
        }

    }
}

#Preview {
    ContentView()
}
