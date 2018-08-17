//
//  CoredataManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/25/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import CoreData

final class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1] as NSURL
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: "Data", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = { [unowned self] in
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.aww.quickpostig")
        
        let url = containerPath?.appendingPathComponent("Data.sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption : true,
                       NSInferMappingModelAutomaticallyOption: true]
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url,
                                               options: options)
        } catch {
            
            var dict = [String: AnyObject]()
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN",
                                       code: 9999,
                                       userInfo: dict)
            
            po("Persistent store -- Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        return coordinator
        }()
    
    
    
    lazy var managedObjectContext: NSManagedObjectContext = { [unowned self] in
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
        }()
    
    
    // MARK: - Core Data Saving support
    final func saveContext() {
        managedObjectContext.performAndWait {
            if managedObjectContext.hasChanges {
                
                do {
                    try self.managedObjectContext.save()
                } catch {
                    let nserror = error as NSError
                    po("Save context -- Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    func delete(object: NSManagedObject) {
        managedObjectContext.performAndWait {
            managedObjectContext.delete(object)
        }
    }
    
    
    //Wipe data
    func deleteAllData(entity: String,
                       from context: NSManagedObjectContext)
    {
        let managedContext = context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        managedContext.performAndWait {
            do
            {
                let results = try managedContext.fetch(fetchRequest)
                for managedObject in results
                {
                    let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                    managedContext.delete(managedObjectData)
                }
            } catch let error as NSError {
                po("Detele all data in \(entity) error : \(error) \(error.userInfo)")
            }
        }
    }
}


