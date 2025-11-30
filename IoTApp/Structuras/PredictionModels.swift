//
//  PredictionModels.swift
//  IoTApp
//
//  Created for prediction system
//

import Foundation

// Estructura para una predicción individual (una hora específica)
struct Prediction: Codable, Identifiable {
    let hora: String
    let temperatura: Float
    let humedad: Float
    let calidadAire: Float
    let presion: Float
    let confianza: Float
    
    var id: String { hora } // Identifiable requiere un id
    
    // Helper para obtener la hora como Date
    var horaDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: hora)
    }
}

// Respuesta completa del API con todas las predicciones
struct PredictionsResponse: Codable {
    let estacion: String
    let fechaPrediccion: String
    let predicciones: [Prediction]
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case estacion
        case fechaPrediccion = "fecha_prediccion"
        case predicciones
        case error
    }
}

// Respuesta para múltiples estaciones (cuando se solicita "all")
struct MultiplePredictionsResponse: Codable {
    let multiple: Bool
    let predicciones: [PredictionsResponse]
    let error: String?
}

