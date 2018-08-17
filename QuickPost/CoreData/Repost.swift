//
//  Repost.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/26/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct RepostData {
    
    var url: String?
    var profileUrl: String?
    var username: String?
    var imageUrl: String?
    var caption: String?
    var new: Bool?
    var thumbnailUrl: String?
}

final class Repost: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var url: String?
    @NSManaged var profileUrl: String?
    @NSManaged var username: String?
    @NSManaged var imageUrl: String?
    @NSManaged var caption: String?
    @NSManaged var timestamp: NSNumber?
    @NSManaged var new: Bool
    @NSManaged var thumbnailUrl: String?
    
    func delete() {
        CoreDataManager.shared.delete(object: self)
    }
}


extension Repost {
    
    static func fetchAll(result: ([Repost?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Repost")
        let timeSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Repost] {
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
    
    static func fetchBy(url: String,
                        result: (Repost?) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Repost")
        let predicate = NSPredicate(format: "url == %@", url)
        request.predicate = predicate
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Repost]
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
    
    static func fetchBy(imageUrl: String,
                        result: (Repost?) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Repost")
        let predicate = NSPredicate(format: "imageUrl == %@", imageUrl)
        request.predicate = predicate
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Repost]
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
    
    static func add(repostData: RepostData, exists: (Bool) -> ()) {
        
        guard let url = repostData.imageUrl else {
            return
        }
        Repost.fetchBy(imageUrl: url) { (resultRepost) in
            
            guard let _ = resultRepost else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "Repost", into: CoreDataManager.shared.managedObjectContext) as? Repost {
                    newObject.objectId = NSUUID().uuidString
                    newObject.url = repostData.url
                    newObject.profileUrl = repostData.profileUrl
                    newObject.username = repostData.username
                    newObject.imageUrl = repostData.imageUrl
                    newObject.caption = repostData.caption
                    newObject.timestamp = NSNumber(value: Date.timestamp())
                    newObject.thumbnailUrl = repostData.thumbnailUrl
                    newObject.new = true
                    exists(false)
                }
                return
            }
            
            resultRepost?.profileUrl = repostData.profileUrl
            resultRepost?.url = repostData.url
            resultRepost?.imageUrl = url
            resultRepost?.username = repostData.username
            resultRepost?.caption = repostData.caption
            resultRepost?.timestamp = NSNumber(value: Date.timestamp())
            resultRepost?.thumbnailUrl = repostData.thumbnailUrl
            exists(true)
        }
    }
    
    static func count(result: (Int) -> (Void)) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Repost")
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
    
    static func markAsOld() {
        Repost.fetchAll { (reposts) in
            reposts.forEach { (repost) in
                repost?.new = false
            }
            CoreDataManager.shared.saveContext()
        }
    }
}
