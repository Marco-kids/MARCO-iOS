//
//  ContentView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/12/22.
//

import Combine
import SwiftUI
import SceneKit
import ARKit

struct ContentView: View {
    
    @State private var selection = 2
    
    // Coordinates variables
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (1.0,0.0)
    //

    var body: some View {
        VStack {
            Text("Latitude: \(coordinates.lat)")
                .font(.largeTitle)
            Text("Longitude: \(coordinates.lon)")
                .font(.largeTitle)
        }
        
        TabView(selection:$selection) {
            
            Text("Your Progress")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("Progress")
                }
                .tag(1)

            ARView(coordinates: .constant((lat: coordinates.lat, lon: coordinates.lon)))
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
                    }
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
