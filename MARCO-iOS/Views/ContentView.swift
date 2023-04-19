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
    @State var locations: [ARLocation] = []
    @State var rutas: [URL] = []
    
    // Tabbar selection
    @State private var selection = 2
    
    @State var tokens: Set<AnyCancellable> = []
    
    // Light or dark mode
    @Environment(\.colorScheme) var colorScheme
    
    #if !targetEnvironment(simulator)
    @StateObject var completed = ARViewController.completed
    #endif
    // TODO: make "gameFinished variable a stateObject for when the game has ended"
    // @StateObject var gameFinished = false
    var gameFinished = false

    
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
                #if !targetEnvironment(simulator)
                ZStack {
                    ARViewContainer()
                        .edgesIgnoringSafeArea(.top)
                }
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(2)
                #else
                ZStack {
                    Text("ARViewContainer")
                }
                .edgesIgnoringSafeArea(.top)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(2)
                #endif
                
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
                #if !targetEnvironment(simulator)
                network.getLocations()
                #endif
                observeModels()
            }
            
            TutorialView()
            
            if(gameFinished == true) {

                FinalView()
            }
            
        }
        
        #if !targetEnvironment(simulator)
        // MARK: Fix to present when one game completed
        .sheet(isPresented: $completed.currSheet) {
            ObraView(obra: completed.currModel)
        }
        #endif
        
        if !network.loadedUSDZ || !network.loadedARWorldMaps {
            LoadingView()
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
