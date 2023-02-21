//
//  ARLocation.swift
//  ARPersistencySwiftUI
//
//  Created by Jose Castillo on 2/14/23.
//

import Foundation

struct ARLocation: Decodable {
    
    let nombre: String
    let screenshot: String
    let ARWorldMap: String
    var locationPath: URL?
    
    private enum CodingKeys: String, CodingKey {
        case nombre, screenshot, ARWorldMap
    }

}
