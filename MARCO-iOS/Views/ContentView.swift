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
    @State var rutas: [URL] = []
    
    // @ObservedObject var coordinator = Coordinator.completed
    
    // Tabbar selection
    @State private var selection = 2
    
    // Coordinates variables
    @StateObject var deviceLocationService = DeviceLocationService.shared
    
    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (1.0,1.0)
    @State var textColor: Color = .red
    
    // Obra de arte completada
    @StateObject var completed = Coordinator.completed
    
    
    // Casa
    var objetoLimitLat = [25.65700, 25.658700]
    var objetoLimitLon =  [-100.26000, -100.25000]
    
    // Simulador
    // var objetoLimitLat = [0.0000, 100.0000]
    //  var objetoLimitLon =  [-123.00000, -122.00000]
    // Salon Swift coordenadas
    var pirinolaLimitLat = [25.6587001, 25.66700]
    var pirinolaLimitLon = [-100.26000, -100.25000]
    // Simulador cualquier lugar
    // var objetoLimitLat = [20.0000, 28.00000]
    // var objetoLimitLon =  [-101.00000, -100.0000]
    
    // Light or dark mode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
            
    //        VStack {
    //            if (coordinates.lat > pirinolaLimitLat[0] && coordinates.lat < pirinolaLimitLat[1] && coordinates.lon > pirinolaLimitLon[0] && coordinates.lon < pirinolaLimitLon[1]) {
    //                Text("Latitude: \(coordinates.lat)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.green)
    //                Text("Longitude: \(coordinates.lon)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.green)
    //            } else if (coordinates.lat > objetoLimitLat[0] && coordinates.lat < objetoLimitLat[1] && coordinates.lon > objetoLimitLon[0] && coordinates.lon < objetoLimitLon[1]) {
    //                Text("Latitude: \(coordinates.lat)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.blue)
    //                Text("Longitude: \(coordinates.lon)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.blue)
    //            } else {
    //                Text("Latitude: \(coordinates.lat)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.red)
    //                Text("Longitude: \(coordinates.lon)")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.red)
    //            }
    //
    //            if(completed.complete) {
    //                Text("SI completado")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.green)
    //            } else {
    //                Text("NO completado")
    //                    .font(.largeTitle)
    //                    .foregroundColor(.red)
    //            }
    //
    //        }
            
        ZStack {
            TabView(selection:$selection) {
                
                ProgressView()
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tabItem {
                        Image(systemName: "square.and.pencil")
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
            .accentColor(colorScheme == .dark ? Color.white : Color.black)
            .onAppear {
                // Correct the transparency bug for Tab Bars
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                // Starting methods
                observeCoordinateUpdates()
                observeDeniedLocationAccess()
                deviceLocationService.requestLocationUpdates()
                network.getModels()
                observeModels()
            }
            
            TutorialView()
        }.sheet(isPresented: $completed.currSheet) {
            ObraView(obra: completed.currModel)
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
