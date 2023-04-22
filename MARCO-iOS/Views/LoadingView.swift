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

            ZStack(alignment: .center) {
                
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color("lightPink")).shadow(radius: 10)
                
                HStack(alignment: .center) {
                    VStack(alignment: .center) {
                        Text("Marco Kids")
                            .font(.title).bold()
                            .foregroundColor(.black)
                        
                        Text("Explora el museo en AR")
                            .font(.title3)
                            .foregroundColor(.black)
                            
                        if(UIDevice.current.model == "iPhone") {
                            Image("paloma")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300.0, height: 300.0)
                            
                        } else {
                            Image("paloma")
                                .resizable()
                                .frame(maxWidth: 270)
                        }
                        
                        VStack(alignment: .center) {
                            Text("Cargando...")
                                .font(.title3)
                                .foregroundColor(.black)
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(Color(.systemGray))
                                    .frame(width: 200, height: 20)
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(Color(.systemPink))
                                    .frame(width: 200*(0.2*CGFloat(network.modelProgressDownload)), height: 20)
                            }
                            
                            
                            Text("Progreso: " + String(network.modelProgressDownload) + " de " + String(network.models.count))
                                .font(.title2)
                                .foregroundColor(.black)
                            
                        }
                        .padding()
                    }
                }
            }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
