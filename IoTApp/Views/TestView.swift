////
////  TestView.swift
////  IoTApp
////
////  Created by UwU on 20/11/25.
////
//
//import SwiftUI
//
//struct WeatherView: View {
//    var body: some View {
//        ZStack {
//            // Fondo azul
//            Color(#colorLiteral(red: 0.04, green: 0.10, blue: 0.35, alpha: 1.0))
//                .ignoresSafeArea()
//            
//            VStack(alignment: .leading, spacing: 16) {
//                // CONTENIDO DE ARRIBA (ciudad, temperatura, etc.)
//                Text("Montreal")
//                    .font(.largeTitle.bold())
//                    .foregroundColor(.white)
//                
//                Text("Today, Dec 3, 5:27 PM")
//                    .foregroundColor(.white.opacity(0.8))
//                
//                Spacer()   // 👈 Empuja la tarjeta blanca hacia abajo
//                
//                // TARJETA BLANCA (sheet asomándose)
//                WeatherBottomCard()
//            }
//            .padding()
//        }
//    }
//}
//
//struct WeatherBottomCard: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Weather now")
//                .font(.headline)
//            
//            HStack(spacing: 24) {
//                WeatherItem(title: "Min temp", value: "-7°", systemImage: "thermometer")
//                WeatherItem(title: "Max temp", value: "-5°", systemImage: "thermometer")
//            }
//            
//            HStack(spacing: 24) {
//                WeatherItem(title: "Wind speed", value: "2 m/s", systemImage: "wind")
//                WeatherItem(title: "Humidity", value: "50%", systemImage: "humidity")
//            }
//        }
//        .padding(.vertical, 20)
//        .padding(.horizontal, 24)
//        .frame(maxWidth: .infinity)
//        .background(Color.white)
//        .clipShape(
//            RoundedRectangle(cornerRadius: 30, style: .continuous) // 👈 esquinas redondeadas arriba
//        )
//        .shadow(radius: 10)
//        .padding(.horizontal)   // margen lateral
//        .padding(.bottom, 8)    // para que “flote” un poquito
//        .ignoresSafeArea()
//    }
//}
//
//struct WeatherItem: View {
//    let title: String
//    let value: String
//    let systemImage: String
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Image(systemName: systemImage)
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                Text(value)
//                    .font(.headline)
//            }
//        }
//    }
//}
//
//
//#Preview {
//    WeatherView()
//}
