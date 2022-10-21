//
//  ARView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import Combine
import SwiftUI
import SceneKit
import ARKit

struct ARView: UIViewRepresentable {
    
    @Binding var coordinates: (lat: Double, lon: Double)
    
    var limitLat = [25.65008, 25.65009]
    var limitLon = [-100.29066, -100.29063]

    func makeUIView(context: Context) -> some UIView {
        let sceneView = ARSCNView()
        sceneView.showsStatistics = true
        sceneView.delegate = context.coordinator

        // Create base scene
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true

        // Limits for the model to show
        //if (coordinates.lat > limitLat[0] && coordinates.lat < limitLat[1] && coordinates.lon > limitLon[0] && coordinates.lon < limitLon[1]) {
            
            // Create Pirinola Scene (tiene que existir si no crashea)
            let pirinolaScene = SCNScene(named: "Art.scnassets/Pirinola.scn")!

            // Add node to base scene
            if let pirinolaNode = pirinolaScene.rootNode.childNode(withName: "pirinola", recursively: true) {
                print("Added Node")
                pirinolaNode.worldPosition = SCNVector3(x: 0, y: 0, z: 0)
                // Escala muy pequeña para que se fije en un punto
                pirinolaNode.scale = SCNVector3(x: 0.0001, y: 0.0001, z: 0.0001)
                sceneView.scene.rootNode.addChildNode(pirinolaNode)
            } else {
                print("Could not add Node")
            }
            
        // }
        
        // Configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        // Return final view
        return sceneView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print(coordinates)
        if(coordinates.lat < limitLat[1] && coordinates.lat > limitLat[0]) {
            
        }
    }
    
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
    }

    // Coordinator permite usar delegates de UIKit
    final class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARView
        init(_ parent: ARView) {
            self.parent = parent
        }
        
        // MARK: Funcion de plano
        /*
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARPlaneAnchor {

                print("plane detected")

                let planeAnchor = anchor as! ARPlaneAnchor

                let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))

                let gridMaterial = SCNMaterial()
                gridMaterial.diffuse.contents = UIImage(named: "Scenes.scnassets/grid.png")
                plane.materials = [gridMaterial]

                let planeNode = SCNNode()

                planeNode.geometry = plane
                planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)

                node.addChildNode(planeNode)

            } else {
                return
            }
            
        } */
        
    }
}

struct ARView_Previews: PreviewProvider {
    static var previews: some View {
        ARView(coordinates: .constant((lat: 1.0, lon: 1.0)))
    }
}
