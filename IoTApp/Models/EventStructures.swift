//
//  DataGET.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import Foundation


//Struct gotten from GET Request API
struct lastLecture: Codable {
    let estacion: String
    let temperatura: Float
    let humedad: Float
    let presion: Float
    let calidadAire: Float
}
