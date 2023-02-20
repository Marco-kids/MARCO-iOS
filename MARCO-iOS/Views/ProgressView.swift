//
//  ProgressView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/23/22.
//

import SwiftUI

struct ProgressView: View {
    @StateObject var network = Network.sharedInstance
    #if !targetEnvironment(simulator)
    @StateObject var completed = Coordinator.completed
    #endif
    @State var currentProgress: CGFloat = 0
    
    let obra = Obra(_id: "0", nombre: "Pirinola", autor: "Daniel", descripcion: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", modelo: "Models/pirinola.usdz", zona: "", completed: false)
    
    var body: some View {
        NavigationView {
            #if !targetEnvironment(simulator)
            // MARK: Main app code
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    HStack(spacing: 30) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(.systemGray))
                                .frame(width: 200, height: 20)
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(.systemPink))
                                .frame(width: 200*completed.progreso, height: 20)
                        }
                        Text("\(completed.progresoActual) / 10")
                            .font(.title).bold()
                    }
                    .padding(.vertical)
                    ScrollView {
                        LazyVStack {
                            ForEach(network.models, id: \.self) { model in
                                NavigationLink(destination: ObraView(obra: model)) {
                                    if (model.completed) {
                                        ProgressRowView(obra: model, url: URL(string: model.modelo)!)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            #else
            // MARK: For testing on SwiftUI Preview
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    HStack(spacing: 30) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(.systemGray))
                                .frame(width: 200, height: 20)
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(.systemPink))
                                .frame(width: 200*0.2, height: 20)
                        }
                        Text("2 / 10")
                            .font(.title).bold()
                    }
                    .padding(.vertical)
                    ScrollView {
                        LazyVStack {
                            ForEach(network.models, id: \.self) { model in
                                NavigationLink(destination: ObraView(obra: model)) {
                                    if (!model.completed) {
                                        ProgressRowView(obra: model, url: URL(string: model.modelo)!)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            #endif
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
    }
}
