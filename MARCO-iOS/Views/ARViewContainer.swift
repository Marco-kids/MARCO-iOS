//
//  ARView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import SwiftUI

struct ARViewContainer : View {
    var body: some View {
        StoryBoardView()
            .ignoresSafeArea(.all)
        // Text("ARViewContainer")
    }
}

struct StoryBoardView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "editor")
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

struct ARView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
