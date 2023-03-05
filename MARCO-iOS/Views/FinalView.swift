//
//  FinalView.swift
//  MARCO-iOS
//
//  Created by Dani on 28/02/23.
//

import SwiftUI

struct FinalView: View {
    
    var body: some View {
        // TODO: Cambiar el styling
        // Ayuda no se nada de styling
        VStack {
            VStack(alignment: .leading) {
                Text("Felicidades")
                    .font(.title2).bold()
                    .foregroundColor(.black)
                Text("Lo lograste")
                    .font(.title).bold()
                    .foregroundColor(.black)
            }
            Image("paloma")
                .scaledToFit()
                .frame(maxWidth: 270)
        }
        .background(Color.pink.opacity(1))
        .padding(40)
        .padding()
    }
    
}



struct FinalView_Previews: PreviewProvider {
    static var previews: some View {
        FinalView()
    }
}
