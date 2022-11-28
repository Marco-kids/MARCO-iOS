//
//  ObraModel.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/15/22.
//

import Foundation

struct Obra:  Decodable {
    var _id : String
    var nombre : String
    var autor : String
    var descripcion : String
    var modelo : String
//    var longitud : String
//    var latitud : String
    var zona: String
}
