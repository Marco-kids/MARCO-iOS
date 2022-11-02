//
//  ARView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import Combine
import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    
    @Binding var coordinates: (lat: Double, lon: Double)
    
    var pirinolaLimitLat = [25.65008, 25.65009]
    var pirinolaLimitLon = [-100.29066, -100.29063]
    
    // var pirinolaLimitLat = [37.33467638, 37.33521504]
    // var pirinolaLimitLon = [-122.03432425, -122.03254905]
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Gesture to launch rocks
        arView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        
        context.coordinator.view = arView
        // context.coordinator.buildEnvironment()
        context.coordinator.initFunction()
        arView.session.run(configuration)
        arView.session.delegate = context.coordinator
        
        
        // activarlo una vez al inicio
        // arView.initCollisionDetection()
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateMarcoModels(lat: coordinates.lat, lon: coordinates.lon)
    }
}

struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(coordinates: .constant((lat: 1.0, lon: 1.0)))
    }
}
