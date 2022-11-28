//
//  ProgressViewRow.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/23/22.
//

import SwiftUI
import SceneKit

struct ProgressRowView: View {
    
    let obra: Obra
    
    var scene = SCNScene()
    
    var url: URL
            
    var cameraNode: SCNNode? {
        scene.rootNode.childNode(withName: "camera", recursively: false)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack() {
                SceneView(scene: try? SCNScene(url: url), pointOfView: cameraNode, options: [.autoenablesDefaultLighting])
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(spacing: 5) {
                    Text(obra.nombre)
                        .font(.title).bold()
                        .foregroundColor(Color(.white))
                    Text(obra.autor)
                        .font(.title3).bold()
                        .foregroundColor(Color(.white))
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 25))
        .foregroundColor(Color(.systemPink))
        .clipped()
        .padding(.horizontal, 5)
    }
}

struct ProgressRowView_Previews: PreviewProvider {
    
    static let obra = Obra(_id: "0", nombre: "Pirinola", autor: "Daniel", descripcion: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", modelo: "Models/pirinola.usdz", zona: "")
    
    static var previews: some View {
        ProgressRowView(obra: obra, url: URL(fileURLWithPath: ""))
    }
    
}
