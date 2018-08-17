//
//  Tag.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/25/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct TagData {
    
    var tag: String?
    var favorite: Bool = false
    var selected: Bool = false
    var priority: Int?
    var confirmed: Bool = false
    var utility: Bool = false
}

final class Tag: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var tag: String?
    @NSManaged var favorite: Bool
    @NSManaged var selected: Bool
    @NSManaged var priority: NSNumber?
    @NSManaged var timestamp: NSNumber?
    @NSManaged var confirmed: Bool
    @NSManaged var utility: Bool
    
    func delete() {
        CoreDataManager.shared.delete(object: self)
    }
}


extension Tag {
    
    static func fetchSelected(result: ([Tag?]) -> ()) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let timeSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        let predicate = NSPredicate(format: "selected == true and utility == false")
        request.predicate = predicate
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Tag] {
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
    
    
    static func fetchFavorites(result: ([Tag?]) -> ()) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let timeSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        let predicate = NSPredicate(format: "favorite == true and utility == false")
        request.predicate = predicate
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Tag] {
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
    
    
    static func fetchUnselectedFavorites(result: ([Tag?]) -> ()) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let timeSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        let predicate = NSPredicate(format: "favorite == true and utility == false and selected == false")
        request.predicate = predicate
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Tag] {
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
    
    
    static func fetchBy(tag: String,
                        result: (NSManagedObject?) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let predicate = NSPredicate(format: "tag == %@", tag)
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
    
    static func add(tagData: TagData) {

        guard let tagName = tagData.tag else {
            return
        }
        Tag.fetchBy(tag: tagName) { (resultTag) in
            
            guard let _ = resultTag else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: CoreDataManager.shared.managedObjectContext) as? Tag {
                    newObject.objectId = NSUUID().uuidString
                    newObject.tag = tagName
                    newObject.selected = tagData.selected
                    newObject.favorite = tagData.favorite
                    newObject.utility = tagData.utility
                    newObject.timestamp = NSNumber(value: Date.timestamp())
                }
                return
            }
            
            (resultTag as! Tag).confirmed = tagData.confirmed
            //(resultTag as! Tag).selected = tagData.selected
            (resultTag as! Tag).favorite = tagData.favorite
            (resultTag as! Tag).utility = tagData.utility
            (resultTag as! Tag).timestamp = NSNumber(value: Date.timestamp())
        }
    }
    
    static func deleteUnfavorite() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [NSManagedObject]
                results?.forEach{ (result) in
                    if (result as! Tag).favorite == false {
                        CoreDataManager.shared.managedObjectContext.delete(result)
                    } else {
                        (result as! Tag).selected = false
                    }
                }
                CoreDataManager.shared.saveContext()
            } catch _ {
                po("Error deleteing objects")
            }
        }
    }
    
    static func countSelected(result: (Int) -> (Void)) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let predicate = NSPredicate(format: "selected == true")
        request.predicate = predicate
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.count(for: request)
                result(results)
            } catch _ {
                po("Error fetching object by id.")
                result(0)
            }
        }
    }
    
    static func count(result: (Int) -> (Void)) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let predicate = NSPredicate(format: "favorite == YES AND utility == NO")
        request.predicate = predicate
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.count(for: request)
                result(results)
            } catch _ {
                po("Error fetching object by id.")
                result(0)
            }
        }
    }
}
