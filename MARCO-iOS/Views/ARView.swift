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
    @State var timerAux: Int = 0

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
        
        let timerRefresh = UpdatViewTimer { (seconds) in
            if(seconds % 2 == 0) {
                timerAux = timerAux + 1
            }
        }
        timerRefresh.start()
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.initModelsData(newObras: models)
        if(models.count > 2){
            context.coordinator.showMarcoModel(currentObra: models[3], gameType: 2)
        }
    }
}


struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(models: .constant([]))
    }
}

// Timer
class UpdatViewTimer {
    typealias Update = (Int)->Void
    var timer:Timer?
    var count: Int = 0
    var update: Update?

    init(update:@escaping Update){
        self.update = update
    }
    func start(){
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
    }
    func stop(){
        if let timer = timer {
            timer.invalidate()
        }
    }


    @objc func timerUpdate() {
        count += 1;
        if let update = update {
            update(count)
        }
        // Stpp the Timer in some situation
        /*
        if (count == 4) {
            stop()
        }
        */
    }
}
