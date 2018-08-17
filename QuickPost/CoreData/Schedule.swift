//
//  Schedule.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/2/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import CoreData

struct ScheduleData {
    
    var objectId: String?
    var caption: String?
    var postedStatus: Int = 0
    var scheduledDate: Date?
    var picture: Data?
}


final class Schedule: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var caption: String?
    @NSManaged var postedStatus: Int
    @NSManaged var scheduledDate: Date?
    @NSManaged var picture: Data?
    
    
    func markAsPosted() {
        
        self.postedStatus = 2
        self.scheduledDate = Date()
    }
    
    
    func delete() {
        
        CoreDataManager.shared.delete(object: self)
    }
    
    
    func getData() -> ScheduleData {
        
        var scheduleData = ScheduleData()
        scheduleData.objectId = self.objectId
        scheduleData.caption = self.caption
        scheduleData.postedStatus = self.postedStatus
        scheduleData.picture = self.picture
        scheduleData.scheduledDate = self.scheduledDate
        return scheduleData
    }
}


extension Schedule {
    
    
    static func fetchAll(result: ([Schedule?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let timeSortDescriptor = NSSortDescriptor(key: "scheduledDate", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Schedule] {
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
    
    
    static func fetchPosted(result: ([Schedule?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let timeSortDescriptor = NSSortDescriptor(key: "scheduledDate", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        let predicate = NSPredicate(format: "postedStatus == 2")
        request.predicate = predicate
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Schedule] {
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
    
    
    static func fetchUnposted(result: ([Schedule?]) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let timeSortDescriptor = NSSortDescriptor(key: "scheduledDate", ascending: false)
        request.sortDescriptors = [timeSortDescriptor]
        let predicate = NSPredicate(format: "postedStatus == 0 OR postedStatus == 1")
        request.predicate = predicate
        request.fetchBatchSize = 100
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                if let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [Schedule] {
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
    
    
    static func fetchBy(id: String,
                        result: (NSManagedObject?) -> ()) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let predicate = NSPredicate(format: "objectId == %@", id)
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
    
    static func add(scheduleData: ScheduleData) {
        
        guard let objectId = scheduleData.objectId,
            let pictureData = scheduleData.picture,
            let caption = scheduleData.caption,
            let date = scheduleData.scheduledDate else {
            return
        }
        
        Schedule.fetchBy(id: objectId) { (resultSchedule) in
            
            guard let _ = resultSchedule else {
                if let newObject = NSEntityDescription.insertNewObject(forEntityName: "Schedule", into: CoreDataManager.shared.managedObjectContext) as? Schedule {
                    newObject.objectId = objectId
                    newObject.caption = caption
                    newObject.picture = pictureData
                    newObject.scheduledDate = date
                    newObject.postedStatus = 0
                }
                return
            }
            
            (resultSchedule as! Schedule).caption = caption
            (resultSchedule as! Schedule).picture = pictureData
            (resultSchedule as! Schedule).scheduledDate = date
            (resultSchedule as! Schedule).postedStatus = 0
        }
    }
    
    
    static func markAsPending() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let predicate = NSPredicate(format: "scheduledDate <= %@", Date() as CVarArg)
        request.predicate = predicate
        CoreDataManager.shared.managedObjectContext.performAndWait {
            do {
                let results = try CoreDataManager.shared.managedObjectContext.fetch(request) as? [NSManagedObject]
                results?.forEach { (result) in
                    if (result as! Schedule).postedStatus != 2 {
                        (result as! Schedule).postedStatus = 1
                    }
                }
                CoreDataManager.shared.saveContext()
            } catch _ {
                po("Error fetching object by id.")
            }
        }
    }
    
    
    static func count(result: (Int) -> (Void)) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
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
