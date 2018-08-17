//
//  SchedulesViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/2/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

final class SchedulesViewController: UITableViewController {
    
    lazy var schedulesResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Schedule")
        let dateSortDescriptor = NSSortDescriptor(key: "scheduledDate", ascending: false)
        request.sortDescriptors = [dateSortDescriptor]
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    @IBOutlet weak var scheduleInfoLabel: UILabel!
    var selectedScheduleData: ScheduleData = ScheduleData()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        do {
            try schedulesResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        //Mark posted schedules
        Schedule.markAsPending()
        
        //Count posts
        Schedule.count { (count) in
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                if count == 0 {
                    self!.scheduleInfoLabel.text = "You haven't any scheduled posts"
                } else {
                    self!.scheduleInfoLabel.text = String(format: "%ld scheduled posts", count)
                }
            }
        }
        
        //Put refresh control
        refreshControl = UIRefreshControl()
        tableView?.addSubview(refreshControl!)
        refreshControl!.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        //Mark posted schedules
        Schedule.markAsPending()
        tableView.reloadData()
    }
    
    
    @objc func refreshData() {
        //Mark posted schedules
        Schedule.markAsPending()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            self?.refreshControl!.endRefreshing()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddScheduleSegue" {
            let destination = (segue.destination as! UINavigationController).viewControllers[0] as! AddScheduleViewController
            destination.selectedScheduleData = self.selectedScheduleData
        }
    }
}


extension SchedulesViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sections = schedulesResultsController.sections else {
            return 1
        }
        return sections.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        guard let sections = schedulesResultsController.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 88
    }

    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleCellIdentifier")
        
        guard let schedule = schedulesResultsController.object(at: indexPath) as? Schedule else {
            return cell!
        }
        
        if let previewImageView = cell?.viewWithTag(100) as? UIImageView,
            let captionLabel = cell?.viewWithTag(103) as? UILabel,
            let dateLabel = cell?.viewWithTag(102) as? UILabel,
            let statusView = cell?.viewWithTag(104),
            let statusLabel = statusView.viewWithTag(100) as? UILabel {
            
            previewImageView.image = UIImage(data: schedule.picture!)
            captionLabel.text = schedule.caption
            captionLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
            dateLabel.text = beautyDateFormatter.string(from: schedule.scheduledDate!)
            
            if captionLabel.text?.count == 0 {
                captionLabel.text = "No caption"
            }
            
            if schedule.postedStatus == 0 {
                statusLabel.text = "Scheduled"
                statusView.backgroundColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                cell?.backgroundColor = UIColor.groupTableViewBackground
                
            } else if schedule.postedStatus == 1 {
                statusLabel.text = "Waiting to post"
                statusView.backgroundColor = #colorLiteral(red: 0.8630884087, green: 0.6817946828, blue: 0.0007469394811, alpha: 1)
                cell?.backgroundColor = UIColor.groupTableViewBackground
            } else {
                statusLabel.text = "Posted"
                statusView.backgroundColor = #colorLiteral(red: 0.3110891583, green: 0.6448216959, blue: 0.1683993493, alpha: 1)
                cell?.backgroundColor = UIColor.white
            }
        }
        return cell!
    }
    
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let schedule = schedulesResultsController.object(at: indexPath) as? Schedule else {
            return
        }
        
        var style: UIAlertControllerStyle = .actionSheet
        if UI_USER_INTERFACE_IDIOM() == .pad {
            style = .alert
        }
        
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: style)
        
        alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
        let postAction = UIAlertAction(title: "Post now", style: .default) { [weak self] (alert) in
            guard let imageData = schedule.picture,
                let image = UIImage(data: imageData) else { return }
            
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                PhotoPoster.postPhotoToInstagram(image: image, caption: schedule.caption ?? "", callBackViewController: self!, completion: {
                    
                    //Mark photo as posted
                    schedule.markAsPosted()
                    CoreDataManager.shared.saveContext()
                    AppManager.incrementNumberOfScans()
                    EventManager.shared.sendEvent(name: "schedule_post", type: "action")
                })
            }
        }
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] (alert) in
            guard let _ = self else { return }
            self?.selectedScheduleData = schedule.getData()
            self!.performSegue(withIdentifier: "showAddScheduleSegue", sender: self!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in }
        
        alertViewController.addAction(postAction)
        alertViewController.addAction(editAction)
        alertViewController.addAction(cancelAction)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            guard let schedule = schedulesResultsController.object(at: indexPath) as? Schedule else {
                return
            }
            
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                requests.forEach({ (request) in
                    if request.identifier == schedule.objectId {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                        schedule.delete()
                        CoreDataManager.shared.saveContext()
                    }
                })
            }
        }
    }
}



//MARK: - Fetch Results Controller Delegate
extension SchedulesViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.tableView.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet([sectionIndex]), with: .automatic)
        case .delete:
            self.tableView.deleteSections(IndexSet([sectionIndex]), with: .automatic)
        case .move:
            self.tableView.moveSection(sectionIndex, toSection: sectionIndex)
        case .update:
            self.tableView.reloadSections(IndexSet([sectionIndex]), with: .automatic)
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            self.tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .move:
            self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.tableView.endUpdates()
        
        Schedule.count { (count) in
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                if count == 0 {
                    self!.scheduleInfoLabel.text = "You haven't any scheduled posts"
                } else {
                    self!.scheduleInfoLabel.text = String(format: "%ld scheduled posts", count)
                }
            }
        }
    }
}
