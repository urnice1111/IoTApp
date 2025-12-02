//
//  HomeView.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI



struct LocationInfoView: View {
    @State private var lastInfo: lastLecture? = nil
    @State private var showPredictions = false
    var piHandler: APIClient?
    let nombreEstacion: String
    
    var body: some View {
        ZStack {
            // Fondo azul
            LinearGradient(
                gradient: Gradient(colors: [.blue,.cyan,.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // CONTENIDO DE ARRIBA (ciudad, temperatura, etc.)
                Text(lastInfo?.estacion.capitalized ?? "")
                    .padding(.top, 20)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                
                HStack{
                    (
                        Text(Double(lastInfo?.temperatura ?? 0), format: .number.precision(.fractionLength(0)))
                            .foregroundColor(.white)
                            .font(.system(size: 100))
                        +
                        Text("°C")
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Image(systemName: "thermometer.variable")
                    .foregroundColor(colorTemperatura(lastInfo?.temperatura ?? 0))
                    .font(.system(size: 80))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(){
                    Text("Ultima actualizacion: ")

                    Text(lastInfo?.fecha ?? "Loading...")
                    
                    Text(lastInfo?.hora ?? "Loading...")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 15))
                .padding(16)
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    WeatherBottomCard(humedad: lastInfo?.humedad ?? 0.0, presion: lastInfo?.presion ?? 0.0)
                    
                    
                    airQualityItem(calidadAire: lastInfo?.calidadAire ?? 0.0)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Botón para ver predicciones
                    Button(action: {
                        showPredictions = true
                    }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title3)
                            Text("Ver Predicciones (24h)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 10)
                .padding(.horizontal)   // margen lateral
                .padding(.bottom, 8)    // para que "flote" un poquito
                .ignoresSafeArea()
                .sheet(isPresented: $showPredictions) {
                    NavigationView {
                        PredictionView(estacion: nombreEstacion)
                            .navigationTitle("Predicciones")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button{
                                        showPredictions = false
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                    }
                }
                
                
            }
            .padding()
        }
        .task {
            do {
                lastInfo = try await APIClient().fetchData(estacion: nombreEstacion)
            } catch APIErrors.invalidURL{
                print("Invalid URL, CHECK URL!")
            } catch APIErrors.invalidResponse{
                print("Invalid response")
            } catch {
                print("Unknown error")
            }
            }
    }
}

struct WeatherBottomCard: View {
    
    let humedad: Float
    let presion: Float
    
    var body: some View {
        
            Text("Ultimo estado")
                .font(.headline)
            
            HStack(spacing: 24) {
                WeatherItem(title: "Presión", value: String(presion), systemImage: "aqi.medium")
                Spacer()
                WeatherItem(title: "Humedad", value: String(humedad), systemImage: "humidity")
            }
            .padding(.bottom)
    }
}

struct WeatherItem: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                Text(value)
                    .font(.headline)
            }
        }
    }
}


struct airQualityItem: View {
    
    let calidadAire: Float
    
    private var progress: Double {
        Double(calidadAire)/100.0
    }
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .stroke(.quaternary, lineWidth: 10)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        colorCalidadAire(calidadAire),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 0.35), value: progress)
                
                Text(String(calidadAire))
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 100, height: 100)
            
            Spacer()
            VStack{
                Text("Calidad del aire:")
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .frame(alignment: .center)
                    
                
                Text(textoCalidadAire(calidadAire))
            }
            
        }
    }
}



func textoCalidadAire(_ calidadAire: Float) -> String {
    switch calidadAire {
    case 0..<40:
        return "Buena 🌿\nEl aire es limpio y seguro."
    case 40..<55:
        return "Aceptable 🙂\nAire adecuado para la mayoría."
    case 55..<70:
        return "Moderada 😐\nPersonas sensibles podrían molestarse."
    case 70..<85:
        return "Mala ⚠️\nEvita actividades al aire libre prolongadas."
    case 85..<100:
        return "Muy mala ☠️\nRiesgoso, permanece en interiores."
    default:
        return "Calculando calidad del aire..."
    }
}

func colorCalidadAire(_ calidadAire: Float) -> Color {
    switch calidadAire {
    case 0..<40:
        return .green
    case 40..<55:
        return .green
    case 55..<70:
        return .yellow
    case 70..<85:
        return .red
    case 85..<100:
        return .red
    default:
        return .blue
    }
}

func colorTemperatura(_ temp: Float) -> Color {
    switch temp {
    case ..<10:
        return Color.blue.opacity(0.85)           // Muy frío
    case 10..<15:
        return Color.cyan.opacity(0.85)           // Frío
    case 15..<20:
        return Color.teal.opacity(0.85)           // Fresco
    case 20..<25:
        return Color.green.opacity(0.85)          // Confort
    case 25..<30:
        return Color.yellow.opacity(0.85)         // Caluroso
    case 30..<35:
        return Color.orange.opacity(0.85)         // Muy caluroso
    default:
        return Color.red.opacity(0.85)            // Peligro
    }
}

#Preview {
    LocationInfoView(nombreEstacion: "biblioteca")
}

