//
//  HomeView.swift
//  IoTApp
//
//  Created by UwU on 19/11/25.
//

import SwiftUI


struct HomeView: View {

    @State private var lastInfo: lastLecture? = nil
    var piHandler: APIClient?
    
    let fontSize: CGFloat = 100
    
    
    var body: some View {

        ZStack {
            LinearGradient(
                colors: [.cyan, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack{
                Text("Temperatura: ")
                Text(Double(lastInfo?.temperatura ?? 0), format: .number.precision(.fractionLength(0)))
                    .font(.system(size: fontSize))
                + Text("°")
                    .font(.system(size: fontSize))

            }
        }
        .task {
            do {
                lastInfo = try await APIClient().fetchData(estacion: "cafeteria")
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


#Preview {
    HomeView()
}

