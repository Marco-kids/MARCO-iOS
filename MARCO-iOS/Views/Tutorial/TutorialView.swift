//
//  TutorialView.swift
//  TutorialMarco
//
//  Created by Jose Castillo on 11/29/22.
//

import SwiftUI

private let primero = Card(title: "Bienvenidx al \nrecorrido virtual de Museo MARCO",
                           descripcion: "Conoce a la Paloma MARCO",
                           image: "paloma")

private let segundo = Card(title: "El Museo tiene una coleccion escondida",
                           descripcion: "Con tu dispositivo puedes recorrer las instalaciones y encontrarlas",
                           image: "estatuas")

private let tercero = Card(title: "Al encontrar la obra, resuelve el reto para activarla",
                           descripcion: "Elimina los cubos en la pantalla",
                           image: "juego")

private let cuarto = Card(title: "Al resolver el reto activas la obra! ",
                          descripcion: "Encuentralas todas y gana un premio al final del recorrido",
                          image: "estatua")

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: 0, y: offset * 10)
    }
}

struct TutorialView: View {
    
    @State private var cards = [cuarto, tercero, segundo, primero]
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    ForEach(0..<cards.count, id: \.self) { index in
                        CardView(card: cards[index]) {
                            withAnimation {
                                removeCard(at: index)
                            }
                        }
                        .stacked(at: index, in: cards.count)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.6))
    }
    
    func removeCard(at index: Int) {
         cards.remove(at: index)
    }
    
}
