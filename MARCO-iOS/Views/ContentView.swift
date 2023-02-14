//
//  ContentView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/12/22.
//

import Combine
import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    
    // Network shared instance
    @StateObject var network = Network.sharedInstance
    @State var models: [Obra] = []
    @State var rutas: [URL] = []
    
    // Tabbar selection
    @State private var selection = 2
    
    @State var tokens: Set<AnyCancellable> = []
    
    // Obra de arte completada
    @StateObject var completed = Coordinator.completed
    
    // Light or dark mode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
            
        ZStack {
            TabView(selection:$selection) {
                
                ProgressView()
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Progress")
                    }
                    .tag(1)
                
                ARViewContainer(models: .constant(self.models))
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
            .accentColor(colorScheme == .dark ? Color.white : Color.black)
            .onAppear {
                // Correct the transparency bug for Tab Bars
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                network.getModels()
                observeModels()
            }
            
            TutorialView()
        }.sheet(isPresented: $completed.currSheet) {
            ObraView(obra: completed.currModel)
        }
    }
    
    // Returns the models when received
    func observeModels() {
        network.obrasPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                print("Handle \(completion) for error and finished subscription.")
            } receiveValue: { model in
                self.models = model
            }
            .store(in: &tokens)
    }
}
