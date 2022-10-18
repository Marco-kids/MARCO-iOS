//
//  ContentView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/12/22.
//

import SwiftUI
import SceneKit
import ARKit

struct ContentView: View {
    
    @State private var selection = 2
    
    var body: some View {
        
        TabView(selection:$selection) {
            Text("Your Progress")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("Progress")
                }
                .tag(1)

            ARView()
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
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
