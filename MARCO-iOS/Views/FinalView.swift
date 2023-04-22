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
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color("lightPink")).shadow(radius: 10)
                
                HStack(alignment: .center) {
                    VStack(alignment: .center) {
                        Text("Lo lograste!!!")
                            .font(.title).bold()
                            .foregroundColor(.black)
                        
                        Text("Haz encontrado todas las obras")
                            .font(.title3)
                            .foregroundColor(.black)
                            
                        if(UIDevice.current.model == "iPhone") {
                            Image("paloma")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 350.0, height: 350.0)
                            
                        } else {
                            Image("paloma")
                                .resizable()
                                .frame(maxWidth: 270)
                        }
                        
                        Text("Recuerda que puedes ver las obras en el boton 'Progreso'")
                            .font(.title3)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                    }
                   
                }
                 
            }
        }
    }
    
}



struct FinalView_Previews: PreviewProvider {
    static var previews: some View {
        FinalView()
    }
}
