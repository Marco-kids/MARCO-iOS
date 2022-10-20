//
//  ContentView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/12/22.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        ZStack {
            TabBarView()
            TutorialView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
