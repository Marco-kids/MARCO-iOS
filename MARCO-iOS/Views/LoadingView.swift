//
//  LoadingView.swift
//  MARCO-iOS
//
//  Created by Dani on 28/02/23.
//

import SwiftUI

struct LoadingView: View {
    @StateObject var network = Network.sharedInstance
    
    var body: some View {
            // TODO: Cambiar el styling
            // Ayuda no se nada de styling
            VStack {
                VStack(alignment: .leading) {
                    Text("CARGANDO")
                        .font(.title).bold()
                        .foregroundColor(.black)
                    Image("paloma")
                        .scaledToFit()
                        .frame(maxWidth: 270)
                    Text("Progreso: " + String(network.modelProgressDownload) + " de " + String(network.models.count))
                        .font(.title2)
                        .foregroundColor(.black)
                }
                
                
            }
            .background(Color.pink.opacity(1))
            .padding(40)
            .padding()
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
