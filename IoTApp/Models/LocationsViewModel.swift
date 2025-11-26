//
//  LocationsViewModel.swift
//  IoTApp
//
//  Created by UwU on 20/11/25.
//

import SwiftUI
internal import Combine

class LocationsViewModel: ObservableObject {
    @Published var ubicaciones: [Ubicacion] = []
    let ip = "10.48.67.179" 

    func fetchLocations() async throws {
        
        print("Entre al fetch de ubicaciones") //Debug
        let urlString = "http://\(ip)/api_handler_swift/get_locations.php"
        
        guard let url = URL(string: urlString) else {
            throw APIErrors.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw APIErrors.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            
            let dataFromServer = try decoder.decode([Ubicacion].self, from: data)
            
            self.ubicaciones = dataFromServer
        } catch {
            print("Error decodificando ubicaciones: \(error)")
            throw APIErrors.decodingError
        }
    }
}

struct Ubicacion: Codable, Identifiable {
    let idEstacion: Int
    let estacion: String
    let latitud: Double
    let longitud: Double
    
    var id: Int { idEstacion } // Identifiable usa este
}
