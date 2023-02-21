//
//  ARView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import SwiftUI

struct ARViewContainer : View {
    var body: some View {
        #if !targetEnvironment(simulator)
        StoryBoardView()
            .ignoresSafeArea(.all)
        #else
        Text("ARViewContainer")
        #endif
    }
}

#if !targetEnvironment(simulator)
struct StoryBoardView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "editor")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
#endif

#if DEBUG
struct ARView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
