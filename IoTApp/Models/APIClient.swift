//
//  APIClient.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import Foundation



struct APIClient {
    func fetchData(estacion: String) async throws -> lastLecture {
        
        let ip = "192.168.0.12"
        
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
}



enum APIErrors: Error {
    case invalidURL
    case invalidResponse
}
