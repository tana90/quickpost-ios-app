//
//  AddScheduleViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/2/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

final class AddScheduleViewController: UITableViewController {
    
    lazy var trendsResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Trends")
        //let indexSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        request.sortDescriptors = []
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    @IBOutlet weak var barChart: BeautifulBarChart!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    
    public var completionHandler: (() -> ())?
    
    var selectedScheduleData: ScheduleData?
    var didSelectDate: Bool = false
    
    
    @IBAction func closeAction() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveAction() {

        if  let _ = selectedScheduleData,
            didSelectDate == true,
            let _ = selectedScheduleData?.scheduledDate {
            
            
            //Remove older notification with id
            if let objectId = selectedScheduleData?.objectId {
                UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                    requests.forEach({ (request) in
                        if request.identifier == objectId {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                        }
                    })
                }
            }
            
            selectedScheduleData?.postedStatus = 0
            Schedule.add(scheduleData: selectedScheduleData!)
            CoreDataManager.shared.saveContext()
            
            NotificationManager.shared.scheduleNotification(with: selectedScheduleData!)
            
            let alertViewController = UIAlertController(title: "Post scheduled successfully", message: String(format: "Your photo is scheduled to be posted at\n\n%@\n\nTap on notification you receive and follow steps.", beautyDateFormatter.string(from: (selectedScheduleData?.scheduledDate)!)), preferredStyle: .alert)
            
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (alert) in
                self.closeAction()
                if let _ = self.completionHandler {
                    self.completionHandler!()
                }
            }
            
            alertViewController.addAction(okAction)
            self.present(alertViewController, animated: true, completion: nil)
        } else {
            
            let alertViewController = UIAlertController(title: "When to post?", message: "Select a date when to post.", preferredStyle: .alert)
            
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
            }
            
            alertViewController.addAction(okAction)
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func dateChanged() {
        didSelectDate = true
        selectedScheduleData?.scheduledDate = datePicker.date
        guard let entries = barChart.dataEntries else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        entries.enumerated().forEach { (index, entry) in
            if entry.title.lowercased().contains(formatter.string(from: datePicker.date).lowercased()) {
                barChart.selectedIndex = index
            }
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        do {
            try trendsResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        showChart()
        datePicker.minimumDate = Date()
        populateData()
        
        Trends.fetchAll { (trends) in
            if let first = trends.first {
                po(first?.value)
            }
        }
    }
    
    
    func populateData() {
        
        guard let _ = selectedScheduleData else { return }
        if let img = UIImage(data: selectedScheduleData!.picture!) {
            previewImageView.image = img
        }
        
        captionLabel.text = selectedScheduleData!.caption!
        captionLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
        
        if let date = selectedScheduleData?.scheduledDate {
            datePicker.date = date
            dateChanged()
        } else {
            datePicker.date = Date()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        
        if segue.identifier == "showEditCaptionSegue" {
            let destination = segue.destination as! EditCaptionViewController
            destination.selectedText = captionLabel.text
            destination.completionHandler = { (result) in
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.captionLabel.text = result
                    self!.selectedScheduleData?.caption = result
                }
            }
        }
    }
}


extension AddScheduleViewController {
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}



extension AddScheduleViewController {
    
    
    func showChart() {
        
//        statusLabel.text = "Waiting to post"
//        statusView.backgroundColor = #colorLiteral(red: 0.8630884087, green: 0.6817946828, blue: 0.0007469394811, alpha: 1)
//        cell?.backgroundColor = UIColor.groupTableViewBackground
//    } else {
//    statusLabel.text = "Posted"
//    statusView.backgroundColor = #colorLiteral(red: 0.3110891583, green: 0.6448216959, blue: 0.1683993493, alpha: 1)
//    cell?.backgroundColor = UIColor.white
        
        let presetColors = [UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1), #colorLiteral(red: 0.8630884087, green: 0.5384463775, blue: 0, alpha: 1), #colorLiteral(red: 0.8630884087, green: 0.6817946828, blue: 0.0007469394811, alpha: 1), #colorLiteral(red: 0.3110891583, green: 0.6448216959, blue: 0.1683993493, alpha: 1)]
        
        var result: [BarEntry] = []
        var colors: [UIColor] = []
        var values: [UInt32] = []
        var heights: [Float] = []
        var titles: [String] = []
        var topTitles: [String] = ["4PM", "9PM", "6PM", "7PM", "9PM", "9PM", "8PM"]
        topTitles.shuffle()
        
        for i in 0..<7 {
            let value = (arc4random() % 100) + 10
            let height: Float = Float(value) / 100.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            var date = Date()
            date.addTimeInterval(TimeInterval(24*60*60*i))
            
            values.append(value)
            heights.append(height)
            titles.append(formatter.string(from: date))
        }
        
        //Calculate max
        var maxValue: UInt32 = 0
        for i in 0..<7 {
            let value = values[i]
            if value > maxValue { maxValue = value }
        }
        
        //Calculate min
        var minValue: UInt32 = maxValue
        for i in 0..<7 {
            let value = values[i]
            if value < minValue { minValue = value }
        }
        
        //Calculate colors
        for i in 0..<7 {
            let value = values[i]
            var color = presetColors[0]
            let quarter = (maxValue - minValue) / 4
            
            
            if value < quarter {
                color = presetColors[0]
            } else if value > quarter && value < quarter * 2 {
                color = presetColors[1]
            } else if value > quarter * 2 && value < quarter * 3 {
                color = presetColors[2]
            } else if value > quarter * 3 {
                color = presetColors[3]
            }
            
            colors.append(color)
        } 
        
        for i in 0..<7 {
            let title = titles[i]
            result.append(BarEntry(color: colors[i % colors.count], height: heights[i], textValue: topTitles[i], title: title))
        }
        
        barChart.dataEntries = result
    }
}


//MARK: - Fetch Results Controller Delegate
extension AddScheduleViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        po("begin to change content")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        po("did change section")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        po("did change row")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        po("finish changing")
        po(controller.fetchedObjects)
    }
}
