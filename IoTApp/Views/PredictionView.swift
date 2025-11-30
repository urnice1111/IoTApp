//
//  PredictionView.swift
//  IoTApp
//
//  Vista para mostrar predicciones de sensores IoT
//

import SwiftUI

struct PredictionView: View {
    let estacion: String
    @State private var predictions: PredictionsResponse?
    @State private var isLoading = true
    @State private var selectedVariable: PredictionVariable = .temperatura
    @State private var errorMessage: String?
    
    enum PredictionVariable: String, CaseIterable {
        case temperatura = "Temperatura"
        case humedad = "Humedad"
        case calidadAire = "Calidad de Aire"
        case presion = "Presión"
        
        var unit: String {
            switch self {
            case .temperatura: return "°C"
            case .humedad: return "%"
            case .calidadAire: return "%"
            case .presion: return "Pa"
            }
        }
        
        var color: Color {
            switch self {
            case .temperatura: return .orange
            case .humedad: return .blue
            case .calidadAire: return .green
            case .presion: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [.blue, .cyan, .white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Cargando predicciones...")
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("Error")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if let predictions = predictions {
                ScrollView {
                    VStack(spacing: 20) {
                        // Título
                        VStack(spacing: 8) {
                            Text(predictions.estacion.capitalized)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Predicciones para: \(predictions.fechaPrediccion)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top)
                        
                        // Selector de variable
                        Picker("Variable", selection: $selectedVariable) {
                            ForEach(PredictionVariable.allCases, id: \.self) { variable in
                                Text(variable.rawValue).tag(variable)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Gráfico
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(selectedVariable.rawValue) (\(selectedVariable.unit))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ChartView(
                                predictions: predictions.predicciones,
                                variable: selectedVariable
                            )
                            .frame(height: 250)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        }
                        
                        // Lista de predicciones
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Predicciones por Hora")
                                .font(.headline)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                            
                            ForEach(predictions.predicciones.prefix(12)) { prediction in
                                PredictionRow(
                                    prediction: prediction,
                                    variable: selectedVariable
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
        }
        .task {
            await loadPredictions()
        }
        .refreshable {
            await loadPredictions()
        }
    }
    
    private func loadPredictions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            predictions = try await APIClient().fetchPredictions(estacion: estacion)
            if predictions?.error != nil {
                errorMessage = predictions?.error ?? "Error desconocido"
            }
        } catch APIErrors.invalidURL {
            errorMessage = "URL inválida. Verifica la configuración del servidor."
        } catch APIErrors.invalidResponse {
            errorMessage = "Error de conexión con el servidor. Verifica tu conexión a internet y que el servidor esté disponible."
        } catch APIErrors.decodingError {
            errorMessage = "Error al procesar los datos. El servidor puede no estar configurado correctamente."
        } catch {
            errorMessage = "Error desconocido: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// Vista del gráfico
struct ChartView: View {
    let predictions: [Prediction]
    let variable: PredictionView.PredictionVariable
    
    var dataPoints: [(hour: String, value: Double)] {
        predictions.map { pred in
            let value: Double
            switch variable {
            case .temperatura: value = Double(pred.temperatura)
            case .humedad: value = Double(pred.humedad)
            case .calidadAire: value = Double(pred.calidadAire)
            case .presion: value = Double(pred.presion)
            }
            return (hour: pred.hora, value: value)
        }
    }
    
    var minValue: Double {
        (dataPoints.map { $0.value }.min() ?? 0) - 5
    }
    
    var maxValue: Double {
        (dataPoints.map { $0.value }.max() ?? 100) + 5
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(dataPoints.count - 1, 1))
            let range = maxValue - minValue
            
            ZStack {
                // Eje Y
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: height - 20))
                }
                .stroke(Color.gray, lineWidth: 1)
                
                // Eje X
                Path { path in
                    path.move(to: CGPoint(x: 40, y: height - 20))
                    path.addLine(to: CGPoint(x: width, y: height - 20))
                }
                .stroke(Color.gray, lineWidth: 1)
                
                // Línea del gráfico
                Path { path in
                    for (index, point) in dataPoints.enumerated() {
                        let x = 40 + CGFloat(index) * stepX
                        let normalizedValue = (point.value - minValue) / range
                        let y = height - 20 - (normalizedValue * (height - 40))
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(variable.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Puntos
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                    let x = 40 + CGFloat(index) * stepX
                    let normalizedValue = (point.value - minValue) / range
                    let y = height - 20 - (normalizedValue * (height - 40))
                    
                    Circle()
                        .fill(variable.color)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
                
                // Etiquetas de horas (cada 3 horas)
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                    if index % 3 == 0 {
                        let x = 40 + CGFloat(index) * stepX
                        Text(point.hour)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: x, y: height - 5)
                    }
                }
                
                // Etiquetas de valores (lado izquierdo)
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(format: "%.1f", maxValue))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f", minValue))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(width: 35, height: height - 20)
                .padding(.leading, 5)
            }
        }
    }
}

// Fila de predicción individual
struct PredictionRow: View {
    let prediction: Prediction
    let variable: PredictionView.PredictionVariable
    
    var value: Float {
        switch variable {
        case .temperatura: return prediction.temperatura
        case .humedad: return prediction.humedad
        case .calidadAire: return prediction.calidadAire
        case .presion: return prediction.presion
        }
    }
    
    var body: some View {
        HStack {
            Text(prediction.hora)
                .font(.subheadline.bold())
                .frame(width: 60, alignment: .leading)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(value, specifier: "%.1f")\(variable.unit)")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Barra de confianza
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < Int(prediction.confianza * 5) ? variable.color : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .cornerRadius(2)
                }
            }
            .frame(width: 50)
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    PredictionView(estacion: "biblioteca")
}

