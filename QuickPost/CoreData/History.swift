//
//  History.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/5/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct HistoryData {
    
    var objectId: String?
    var caption: String?
    var postedDate: String?
}

final class History: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var caption: String?
    @NSManaged var postedDate: Date?
    
    func delete() {
        CoreDataManager.shared.delete(object: self)
    }
}


extension History {
    
    
    static func fetchAll(result: ([History?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "History")
        let timeSortDescriptor = NSSortDescriptor(key: "postedDate", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [History] {
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
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "History")
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
    
    
    static func add(historyData: HistoryData) {
        
        guard let caption = historyData.caption else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.autoupdatingCurrent
        
        History.fetchBy(caption: caption) { (resultHistory) in
            
            guard let _ = resultHistory else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "History", into: CoreDataManager.shared.managedObjectContext) as? History {
                    newObject.objectId = NSUUID().uuidString
                    newObject.caption = caption
                    
                    newObject.postedDate = formatter.date(from: historyData.postedDate ?? "1990-09-26 03:00:00")
                }
                return
            }
            
            (resultHistory as! History).caption = caption
            (resultHistory as! History).postedDate = formatter.date(from: historyData.postedDate ?? "1990-09-26 03:00:00")
        }
    }
}
