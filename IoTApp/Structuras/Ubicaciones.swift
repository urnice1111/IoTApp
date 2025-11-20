//
//  Ubicaciones.swift
//  IoTApp
//
//  Created by UwU on 20/11/25.
//

import Foundation

struct ubicacion: Codable {
    let estacion: String
    let latitud: Double
    let longitud: Double
}

var ubicaciones: [ubicacion] = []
