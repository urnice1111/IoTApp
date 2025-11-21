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
            ProgressView("Revisa tu conexión a internet")
                .task {
                    try?await viewModel.fetchLocations()
            }
        } else {
            TabView {
                ForEach(viewModel.ubicaciones) {ubicacion in
                    LocationInfoView(nombreEstacion: ubicacion.estacion)
                        .tabItem {
                            Label(ubicacion.estacion.capitalized,
                                  systemImage: iconFor(ubicacion.estacion))
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

func iconFor(_ nombre: String) -> String {
        switch nombre.lowercased() {
        case "cafeteria":
            return "cup.and.saucer.fill"
        case "biblioteca":
            return "books.vertical.fill"
        case "gimnasio":
            return "dumbbell.fill"
        default:
            return "building.2.fill"  // Fallback
        }
    }

#Preview {
    ContentView()
}
