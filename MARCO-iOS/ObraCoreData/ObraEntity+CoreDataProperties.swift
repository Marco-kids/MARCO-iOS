//
//  ObraEntity+CoreDataProperties.swift
//  MARCO-iOS
//
//  Created by Dani on 21/04/23.
//
//

import Foundation
import CoreData


extension ObraEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ObraEntity> {
        return NSFetchRequest<ObraEntity>(entityName: "ObraEntity")
    }

    @NSManaged public var zona: String?
    @NSManaged public var nombre: String?
    @NSManaged public var modelo: String?
    @NSManaged public var id: String?
    @NSManaged public var descripcion: String?
    @NSManaged public var completed: Bool
    @NSManaged public var autor: String?

}

extension ObraEntity : Identifiable {

}
