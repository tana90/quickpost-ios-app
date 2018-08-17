//
//  TrendsViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/2/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData

final class TrendsViewController: UITableViewController {
    
    lazy var historyFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "History")
        let dateSortDescriptor = NSSortDescriptor(key: "postedDate", ascending: false)
        request.sortDescriptors = [dateSortDescriptor]
        
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    lazy var popularFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Popular")
        let positionSortDescriptor = NSSortDescriptor(key: "position", ascending: true)
        request.sortDescriptors = [positionSortDescriptor]
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    var selectedFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    
    @IBAction func helpAction() {
        present(helpSafariViewController, animated: true, completion: nil)
    }

    
    @IBAction func changeTypeAction() {
        if typeSegmentedControl.selectedSegmentIndex == 0 {
            selectedFetchedResultsController = popularFetchedResultsController
        } else {
            selectedFetchedResultsController = historyFetchedResultsController
        }
        
        do {
            try selectedFetchedResultsController!.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedFetchedResultsController = popularFetchedResultsController
        
        if let _ = selectedFetchedResultsController {
            do {
                try selectedFetchedResultsController!.performFetch()
            } catch _ {
                po("Error performing fetch products")
            }
        }
        
        
        
        //Put refresh control
        refreshControl = UIRefreshControl()
        tableView?.addSubview(refreshControl!)
        refreshControl!.addTarget(self, action: #selector(refreshData), for: .valueChanged)

    }
    

    @objc func refreshData() {
        
        if typeSegmentedControl.selectedSegmentIndex == 0 {
            Popular.fetchAll { (populars) in
                populars.forEach { (popularObj) in
                    CoreDataManager.shared.delete(object: popularObj!)
                }
                CoreDataManager.shared.saveContext()
                
                Connector.shared.getPopular(with: { (json) in
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        self!.refreshControl?.endRefreshing()
                        LoadingPopup.shared.hide()
                        self!.tableView.reloadData()
                    }
                })
            }
            
        } else {
            
            History.fetchAll { (history) in
                history.forEach { (historyObj) in
                    CoreDataManager.shared.delete(object: historyObj!)
                }
                CoreDataManager.shared.saveContext()
                
                guard let token = AppManager.loadToken() else { return }
                LoadingPopup.shared.show(onView: (self.navigationController?.view)!)
                Connector.shared.getHistory(with: token, with: { (json) in
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        self!.refreshControl?.endRefreshing()
                        LoadingPopup.shared.hide()
                        self!.tableView.reloadData()
                    }
                })
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [weak self] in
            self?.refreshControl!.endRefreshing()
        }
    }
}


extension TrendsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = selectedFetchedResultsController!.sections else {
            return 1
        }
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = selectedFetchedResultsController!.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if typeSegmentedControl.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "popularCellIdentifier")!
            guard let popular = selectedFetchedResultsController!.object(at: indexPath) as? Popular else {
                return cell
            }
            
            if let titleLabel = cell.viewWithTag(100) as? UILabel,
                let categoryLabel = cell.viewWithTag(101) as? UILabel {
                
                titleLabel.text = popular.caption
                titleLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
                categoryLabel.text = popular.category
                
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "historyCellIdentifier")!
            guard let history = selectedFetchedResultsController!.object(at: indexPath) as? History else {
                return cell
            }
            
            if let titleLabel = cell.viewWithTag(100) as? UILabel,
                let dateLabel = cell.viewWithTag(101) as? UILabel {
                
                titleLabel.text = history.caption
                titleLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
                dateLabel.text = beautyDateFormatter.string(from: history.postedDate ?? Date())
                
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var caption = ""
        
        if typeSegmentedControl.selectedSegmentIndex == 0 {
            guard let data = selectedFetchedResultsController?.object(at: indexPath) as? Popular else {
                return
            }
            caption = data.caption ?? ""
        } else {
            guard let data = selectedFetchedResultsController?.object(at: indexPath) as? History else {
                return
            }
            caption = data.caption ?? ""
        }
        
        
        
        var style: UIAlertControllerStyle = .actionSheet
        if UI_USER_INTERFACE_IDIOM() == .pad {
            style = .alert
        }
        
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: style)
        
        alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
        let copyAction = UIAlertAction(title: "Copy to clipboard", style: .default) { (alert) in
            UIPasteboard.general.string = caption
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in }
        
        alertViewController.addAction(copyAction)
        alertViewController.addAction(cancelAction)
        self.present(alertViewController, animated: true, completion: nil)
    }
}



//MARK: - Fetch Results Controller Delegate
extension TrendsViewController: NSFetchedResultsControllerDelegate {
    
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
    }
}
