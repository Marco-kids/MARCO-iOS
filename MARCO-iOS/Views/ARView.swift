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
    @Binding var models: [Obra]
    @Binding var rutas: [URL]

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Gesture to launch bullets
        arView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap)))
        
        context.coordinator.view = arView
        context.coordinator.initCollisionDetection()
        context.coordinator.initBullets()
        context.coordinator.initBoxes()
        arView.session.run(configuration)
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateMarcoModels(lat: coordinates.lat, lon: coordinates.lon)
        context.coordinator.initModelsData(newObras: models)
        context.coordinator.initRutasData(newRutas: rutas)
    }
}

struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(coordinates: .constant((lat: 1.0, lon: 1.0)), models: .constant([]), rutas: .constant([]))
    }
}
