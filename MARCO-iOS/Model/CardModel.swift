//
//  Card.swift
//  TutorialMarco
//
//  Created by Alumno on 29/11/22.
//

import Foundation

struct Card {

    let title: String
    let descripcion: String
    let image: String
    
    static let example = Card(title: "Bienvenide al \nrecorrido virtual de Museo MARCO",
                              descripcion: "Conoce a la Paloma MARCO",
                              image: "paloma")
    
    static let example2 = Card(title: "El Museo tiene una coleccion escondida",
                               descripcion: "Con tu dispositivo puedes recorrer las instalaciones y encontrarlas",
                               image: "estatuas")
        
}
