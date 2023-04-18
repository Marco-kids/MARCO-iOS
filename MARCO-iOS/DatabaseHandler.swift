//
//  DatabaseHandler.swift
//  MARCO-iOS
//
//  Created by Dani on 11/04/23.
//

import Foundation
import CoreData
import UIKit

class DataBaseHandler {
    init() {}
    
    static let instance = DataBaseHandler()
    
    static var context : NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Stack
    static var persistentContainer : NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "testModel")
        container.loadPersistentStores(completionHandler: {(storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error when fetching coreData: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    static func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Data is saved")
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error:  \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    static func fetchAllObras() -> [ObraEntity] {
        var obraEnti = [ObraEntity]()
        let context = DataBaseHandler.context
        
        let fetchRequest : NSFetchRequest<ObraEntity>
        fetchRequest = ObraEntity.fetchRequest()
        
        do {
            obraEnti = try (context.fetch(fetchRequest))
            print("Fetch Obras", obraEnti.count)
        } catch {
            print("Error in fetching Data")
        }
        
        return obraEnti
    }
}
