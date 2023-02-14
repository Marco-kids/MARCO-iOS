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
    @Binding var models: [Obra]

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
        arView.session.run(configuration, options: [.resetTracking])
        arView.session.delegate = context.coordinator
        context.coordinator.runCoachingOverlay()
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.initModelsData(newObras: models)
        if(models.count > 2){
            context.coordinator.showMarcoModel(currentObra: models[0], gameType: 2)
        }
    }
}


struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(models: .constant([]))
    }
}
