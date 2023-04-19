//
//  LoadingView.swift
//  MARCO-iOS
//
//  Created by Dani on 28/02/23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        Text("Loading...")
            .padding()
            .font(.system(size: 30, weight: .bold, design: .rounded))
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
