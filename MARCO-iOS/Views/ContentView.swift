//
//  ContentView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/12/22.
//

import Combine
import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    
    // Network shared instance
    @StateObject var network = Network.sharedInstance
    @State var models: [Obra] = []
    
    @State private var selection = 2
    
    // Coordinates variables
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (1.0,1.0)
    @State var textColor: Color = .red
    
    // Obra de arte completada
    @StateObject var completed = Coordinator.completed
    
    // Casa
    var objetoLimitLat = [25.65000, 25.66000]
    var objetoLimitLon =  [-100.26000, -100.25000]
    
    // Simulador
    // var objetoLimitLat = [0.0000, 100.0000]
    //  var objetoLimitLon =  [-123.00000, -122.00000]
    
    // Salon Swift coordenadas
    var pirinolaLimitLat = [25.60008, 25.66009]
    var pirinolaLimitLon = [-100.29069, -100.290400]
    
    // Simulador cualquier lugar
    // var objetoLimitLat = [20.0000, 28.00000]
    // var objetoLimitLon =  [-101.00000, -100.0000]

    
    var body: some View {
        
        VStack {
            if (coordinates.lat > pirinolaLimitLat[0] && coordinates.lat < pirinolaLimitLat[1] && coordinates.lon > pirinolaLimitLon[0] && coordinates.lon < pirinolaLimitLon[1]) {
                Text("Latitude: \(coordinates.lat)")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("Longitude: \(coordinates.lon)")
                    .font(.largeTitle)
                    .foregroundColor(.green)
            } else if (coordinates.lat > objetoLimitLat[0] && coordinates.lat < objetoLimitLat[1] && coordinates.lon > objetoLimitLon[0] && coordinates.lon < objetoLimitLon[1]) {
                Text("Latitude: \(coordinates.lat)")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Longitude: \(coordinates.lon)")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            } else {
                Text("Latitude: \(coordinates.lat)")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Longitude: \(coordinates.lon)")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }
            
            if(completed.complete) {
                Text("SI completado")
                    .font(.largeTitle)
                    .foregroundColor(.green)
            } else {
                Text("NO completado")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }

        }
        
        TabView(selection:$selection) {
            
            Text("Your Progress" )
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("Progress")
                }
                .tag(1)

            ARViewContainer(coordinates: .constant((lat: coordinates.lat, lon: coordinates.lon)), models: .constant(self.models))
                .edgesIgnoringSafeArea(.top)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(2)
            

            Text("Settings")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .onAppear {
                        observeCoordinateUpdates()
                        observeDeniedLocationAccess()
                        deviceLocationService.requestLocationUpdates()
                        network.getModels()
                        observeModels()
                    }
    }
    
    // Returns the models when received
    func observeModels() {
        network.obrasPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { model in
                self.models = model
            }
            .store(in: &tokens)
    }

    // Updates coordinates
    func observeCoordinateUpdates() {
            deviceLocationService.coordinatesPublisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    print("Handle \(completion) for error and finished subscription.")
                } receiveValue: { coordinates in
                    self.coordinates = (coordinates.latitude, coordinates.longitude)
                }
                .store(in: &tokens)
        }

    func observeDeniedLocationAccess() {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Handle access denied event, possibly with an alert.")
                }
                .store(in: &tokens)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

