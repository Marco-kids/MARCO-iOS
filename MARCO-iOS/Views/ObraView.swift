//
//  ObraView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/23/22.
//

import SwiftUI
import SceneKit

struct ObraView: View {
    
    let obra: Obra
    
    var scene = SCNScene()

    var cameraNode: SCNNode? {
        scene.background.contents = UIColor.systemPink
        return scene.rootNode.childNode(withName: "camera", recursively: false)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(obra.nombre)
                .font(.title).bold()
                .foregroundColor(Color(.white))
                .padding(.top)
            Text(obra.autor)
                .font(.title3).bold()
                .foregroundColor(Color(.white))
            SceneView(scene: {
                let scene = try! SCNScene(url: URL(string: obra.modelo)!)
                scene.background.contents = UIColor.systemPink
                return scene
            }(), pointOfView: cameraNode, options: [.autoenablesDefaultLighting, .allowsCameraControl])
            Text(obra.descripcion)
                .font(.headline).bold()
                .foregroundColor(Color(.white))
                .multilineTextAlignment(.center)
                .padding(40)
                .background(RoundedRectangle(cornerRadius: 25))
                .foregroundColor(Color(.black))
                .clipped()
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color(.systemPink))
    }
}

struct ObraView_Previews: PreviewProvider {
    
    static let obra = Obra(_id: "0", nombre: "Pirinola", autor: "Daniel", descripcion: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", modelo: "Models/pirinola.usdz", zona: "")
    
    static var previews: some View {
        ObraView(obra: obra)
    }
}
