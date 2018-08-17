//
//  Trends.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/14/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct TrendsData {
    
    var index: Int?
    var value: Double?
    var hour: Int?
}

final class Trends: NSManagedObject {
    
    @NSManaged var index: Int
    @NSManaged var value: Double
    @NSManaged var hour: Int
}

extension Trends {
    
    static func add(trendsData: TrendsData) {
        guard let index = trendsData.index else { return }
        Trends.fetchBy(index: index) { (result) in
            guard let _ = result else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "Trends", into: CoreDataManager.shared.managedObjectContext) as? Trends {
                    newObject.index = index
                    newObject.hour = trendsData.hour ?? 0
                    newObject.value = trendsData.value ?? 0.5
                }
                return
            }
            
            (result as! Trends).index = index
            (result as! Trends).hour = trendsData.hour ?? 0
            (result as! Trends).value = trendsData.value ?? 0.5
        }
    }
    
    static func fetchBy(index: Int,
                        result: (NSManagedObject?) -> ()) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Trends")
        let predicate = NSPredicate(format: "index == %ld", index)
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
    
    static func fetchAll(result: ([Trends?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Trends")
        request.sortDescriptors = []
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Trends] {
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
}
