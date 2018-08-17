//
//  Popular.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/7/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct PopularData {
    
    var objectId: String?
    var caption: String?
    var category: String?
    var position: Int?
}

final class Popular: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var caption: String?
    @NSManaged var category: String?
    @NSManaged var position: Int
    
    func delete() {
        CoreDataManager.shared.delete(object: self)
    }
}


extension Popular {
    
    static func fetchAll(result: ([Popular?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Popular")
        request.sortDescriptors = []
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Popular] {
                    result(results)
                } else {
                    result([])
                }
            } catch _ {
                po("Error fetching object all.")
                result([])
            }
        }
    }
    
    
    static func fetchBy(caption: String,
                        result: (NSManagedObject?) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Popular")
        let predicate = NSPredicate(format: "caption == %@", caption)
        request.predicate = predicate
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [NSManagedObject]
                guard let last = results?.last else {
                    result(nil)
                    return
                }
                result(last)
            } catch _ {
                po("Error fetching object by id.")
                result(nil)
            }
        }
    }
    
    
    static func add(popularData: PopularData) {
        
        guard let caption = popularData.caption else { return }

        Popular.fetchBy(caption: caption) { (resultPopular) in
            
            guard let _ = resultPopular else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "Popular", into: CoreDataManager.shared.managedObjectContext) as? Popular {
                    newObject.objectId = NSUUID().uuidString
                    newObject.caption = caption
                    newObject.position = popularData.position ?? 0
                    newObject.category = popularData.category ?? "All"
                }
                return
            }
            
            (resultPopular as! Popular).caption = caption
            (resultPopular as! Popular).position = popularData.position ?? 0
            (resultPopular as! Popular).category = popularData.category ?? "All"
        }
    }
}

