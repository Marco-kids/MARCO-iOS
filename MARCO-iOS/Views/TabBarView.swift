//
//  TabBarView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import SwiftUI

struct TabBarView: View {
    
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

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
