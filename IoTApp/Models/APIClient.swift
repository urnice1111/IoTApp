//
//  APIClient.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import Foundation



struct APIClient {
    let ip = "192.168.1.216"
    
    func fetchData(estacion: String) async throws -> lastLecture {
        
        
        let urlString = "http://\(ip)/api_handler_swift/get_zone_info.php/\(estacion)"
        
        
        guard let url = URL(string: urlString) else {
            throw APIErrors.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw APIErrors.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let dataFromServer = try decoder.decode(lastLecture.self, from: data)
            return dataFromServer
        }
        
    }
    
    func fetchPredictions(estacion: String) async throws -> PredictionsResponse {
        let urlString = "http://\(ip)/api_handler_swift/get_predictions.php?estacion=\(estacion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? estacion)"
        
        guard let url = URL(string: urlString) else {
            throw APIErrors.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw APIErrors.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let predictionsResponse = try decoder.decode(PredictionsResponse.self, from: data)
            return predictionsResponse
        } catch {
            print("Error decodificando predicciones: \(error)")
            throw APIErrors.decodingError
        }
    }
    
}



enum APIErrors: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}
