//
//  Heatmap.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI
import MapKit


struct Heatmap: View {
    
    
    let cafeteria = CLLocationCoordinate2D(latitude: 19.596864, longitude: -99.226705)
    
    let biblioteca = CLLocationCoordinate2D(latitude: 19.596956, longitude: -99.225960)
    
    let gimnasio = CLLocationCoordinate2D(latitude: 19.595180, longitude: -99.227234)
    
    
    var body: some View {
        Map(){
            Marker("Cafeteria", coordinate: cafeteria)
            
            Marker("Biblioteca", coordinate: biblioteca)
            
            Marker("Gimnasio", coordinate: gimnasio)
        }
    }
}


#Preview {
    Heatmap()
}
