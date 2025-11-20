//
//  ContentView.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = LocationsViewModel()
    

    
    var body: some View {
        if viewModel.ubicaciones.isEmpty {
            ProgressView("Cargando ubicaciones...")
                .task {
                    try?await viewModel.fetchLocations()
                }
        } else {
            TabView {
                ForEach(viewModel.ubicaciones) {ubicacion in
                    LocationInfoView(nombreEstacion: ubicacion.estacion)
                        .tabItem {
                            Label(ubicacion.estacion.capitalized,
                                  systemImage: "building.2.fill")
                        }
                }
            }
            .task{
                do {
                    try await viewModel.fetchLocations()
                } catch {
                    print("Error getting locations: \(error)")
                }
            }
        }
        

    }
}

#Preview {
    ContentView()
}
