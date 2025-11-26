//
//  Heatmap.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI
import MapKit


struct Heatmap: View {
    @StateObject var viewModel = LocationsViewModel()
    @State private var lecturas: [String: lastLecture] = [:]
    @State private var isLoading = true
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.596, longitude: -99.226),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    
    // Radio base para los círculos de calor (en metros)
    private let baseRadius: CLLocationDistance = 60
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando mapa de calor...")
            } else if viewModel.ubicaciones.isEmpty {
                Text("No hay ubicaciones disponibles")
                    .foregroundColor(.secondary)
            } else {
                Map(position: $cameraPosition) {
                    // Agregar overlays de calor y marcadores para cada ubicación
                    ForEach(viewModel.ubicaciones) { ubicacion in
                        let coordenada = CLLocationCoordinate2D(
                            latitude: ubicacion.latitud,
                            longitude: ubicacion.longitud
                        )
                        
                        // Si hay lectura disponible, mostrar círculo de calor
                        if let lectura = lecturas[ubicacion.estacion] {
                            MapCircle(
                                center: coordenada,
                                radius: baseRadius
                            )
                            .foregroundStyle(
                                colorForTemperature(lectura.temperatura)
                                    .opacity(0.4)
                            )
                            
                            // Marcador con nombre y temperatura
                            Marker(
                                "\(ubicacion.estacion.capitalized): \(Int(lectura.temperatura))°C",
                                coordinate: coordenada
                            )
                        } else {
                            // Marcador sin temperatura si no hay lectura
                            Marker(ubicacion.estacion.capitalized, coordinate: coordenada)
                        }
                    }
                }
            }
        }
        .task {
            await loadHeatmapData()
        }
    }
    
    // Función para cargar todas las ubicaciones y sus lecturas
    private func loadHeatmapData() async {
        isLoading = true
        
        do {
            try await viewModel.fetchLocations()
        } catch {
            print("Error obteniendo ubicaciones: \(error)")
            isLoading = false
            return
        }
        
        if !viewModel.ubicaciones.isEmpty {
            let region = calculateMapRegion(for: viewModel.ubicaciones)
            cameraPosition = .region(region)
        }
        
        // Obtener últimas lecturas para cada ubicación en paralelo
        await withTaskGroup(of: (String, lastLecture?).self) { group in
            for ubicacion in viewModel.ubicaciones {
                group.addTask {
                    do {
                        let lectura = try await APIClient().fetchData(estacion: ubicacion.estacion)
                        return (ubicacion.estacion, lectura)
                        
                    } catch APIErrors.invalidURL {
                        print("Invalid URL para estación \(ubicacion.estacion)")
                        return (ubicacion.estacion, nil)
                    } catch APIErrors.invalidResponse {
                        print("Invalid response para estación \(ubicacion.estacion)")
                        return (ubicacion.estacion, nil)
                    } catch {
                        print("Unknown error para estación \(ubicacion.estacion): \(error)")
                        return (ubicacion.estacion, nil)
                    }
                }
            }
            
            // Recopilar resultados
            for await (estacion, lectura) in group {
                if let lectura = lectura {
                    lecturas[estacion] = lectura
                }
            }
        }
        
        isLoading = false
    }
    
    // Función para calcular la región del mapa que incluya todas las ubicaciones
    private func calculateMapRegion(for ubicaciones: [Ubicacion]) -> MKCoordinateRegion {
        guard !ubicaciones.isEmpty else {
            // Región por defecto si no hay ubicaciones
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 19.596, longitude: -99.226),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        var minLat = ubicaciones[0].latitud
        var maxLat = ubicaciones[0].latitud
        var minLon = ubicaciones[0].longitud
        var maxLon = ubicaciones[0].longitud
        
        for ubicacion in ubicaciones {
            minLat = min(minLat, ubicacion.latitud)
            maxLat = max(maxLat, ubicacion.latitud)
            minLon = min(minLon, ubicacion.longitud)
            maxLon = max(maxLon, ubicacion.longitud)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = (maxLat - minLat) * 1.5 // Padding del 50%
        let lonDelta = (maxLon - minLon) * 1.5 // Padding del 50%
        
        // Asegurar un mínimo de zoom
        let minDelta = 0.0025
        let finalLatDelta = max(latDelta, minDelta)
        let finalLonDelta = max(lonDelta, minDelta)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
    }
    
    // Función para mapear temperatura a color
    private func colorForTemperature(_ temp: Float) -> Color {
        switch temp {
        case ..<10:
            return Color.blue           // Muy frío
        case 10..<15:
            return Color.cyan           // Frío
        case 15..<20:
            return Color.teal           // Fresco
        case 20..<25:
            return Color.green          // Confort
        case 25..<30:
            return Color.yellow         // Caluroso
        case 30..<35:
            return Color.orange         // Muy caluroso
        default:
            return Color.red            // Peligro
        }
    }
}


#Preview {
    Heatmap()
}
