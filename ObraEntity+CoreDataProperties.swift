//
//  ObraEntity+CoreDataProperties.swift
//  MARCO-iOS
//
//  Created by Dani on 11/04/23.
//
//

import Foundation
import CoreData


extension ObraEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ObraEntity> {
        return NSFetchRequest<ObraEntity>(entityName: "ObraEntity")
    }

    @NSManaged public var autor: String?
    @NSManaged public var completed: Bool
    @NSManaged public var descripcion: String?
    @NSManaged public var id: String?
    @NSManaged public var modelo: String?
    @NSManaged public var nombre: String?
    @NSManaged public var zona: String?

}

extension ObraEntity : Identifiable {

}
