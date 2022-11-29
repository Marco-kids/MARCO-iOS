//
//  ObraModel.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/15/22.
//

import Foundation

struct Obra:  Decodable, Hashable {
    var _id : String
    var nombre : String
    var autor : String
    var descripcion : String
    var modelo : String
    var zona: String
    var completed: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case _id, nombre, autor, descripcion, modelo, zona
    }
}
