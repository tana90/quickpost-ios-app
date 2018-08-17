//
//  RepostViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/26/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData

final class RepostViewController: UITableViewController {
    
    lazy var repostsResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Repost")
        let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        let newSortDescriptor = NSSortDescriptor(key: "new", ascending: false)
        request.sortDescriptors = [newSortDescriptor, timestampSortDescriptor]
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    @IBOutlet weak var repostInfoLabel: UILabel!
    var selectedRepost: Repost?
    
    @IBAction func helpAction() {
        present(helpSafariViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        EventManager.shared.sendEvent(name: "open_repost", type: "app")
        
        do {
            try repostsResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        Repost.count { (count) in
            if count == 0 {
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.repostInfoLabel.text = "Copy wanted Instagram Photo link"
                }
                
                let alertViewController = UIAlertController(title: "🎉 How it works  ", message: "\nOpen Instagram app\n\nCopy Link from post\n\nCome back here.", preferredStyle: .alert)
                
                alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                
                let cancelAction = UIAlertAction(title: "Later", style: .default) { (alert) in
                }
                
                let openInstaAction = UIAlertAction(title: "Open Instagram", style: .cancel) { (alert) in
                    guard let url = URL(string: "instagram://") else { return }
                    UIApplication.shared.open(url, options: [:], completionHandler: { [weak self] (success) in
                        
                        if !success {
                            guard let _ = self else { return }
                            let alertViewController = UIAlertController(title: "Instagram app not found", message: "Looks like you don't have Instagram app installed", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                            }
                            
                            alertViewController.addAction(okAction)
                            self!.present(alertViewController, animated: true, completion: nil)
                        }
                    })
                }
                
                alertViewController.addAction(openInstaAction)
                alertViewController.addAction(cancelAction)
                self.present(alertViewController, animated: true, completion: nil)
            } else {
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.repostInfoLabel.text = String(format: "%ld reposts", count)
                }
            }
        }
        
        //Put refresh control
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl!)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    
    @objc func refreshData() {
        
        RepostManager.shared.checkClipboard()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            guard let _ = self else { return }
            self!.refreshControl?.endRefreshing()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        
        if segue.identifier == "showRepostPreviewSegue" {
            let repostPreviewController = segue.destination as! RepostPreviewViewController
            repostPreviewController.selectedRepost = selectedRepost
            selectedRepost?.new = false
            CoreDataManager.shared.saveContext()
        }
    }
}


extension RepostViewController {
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 88
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sections = repostsResultsController.sections,
            sections.count > 0
            else {
                return 1
        }
        return sections.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        guard let sections = repostsResultsController.sections,
            sections.count > 0 else {
                return 0
        }
        
        let currentSection = sections[section]
        return currentSection.numberOfObjects
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "repostCellIdentifier")
        
        guard let repost = repostsResultsController.object(at: indexPath) as? Repost else {
            return cell!
        }
        
        cell?.backgroundColor = UIColor.white
        
        let mediaView = cell?.viewWithTag(100) as! MediaView
        let profileImageView = cell?.viewWithTag(101) as! UIImageView
        let usernameLabel = cell?.viewWithTag(102) as! UILabel
        let captionLabel = cell?.viewWithTag(103) as! UILabel
        let videoInfoView = cell?.viewWithTag(110)
        
        usernameLabel.text = repost.username
        captionLabel.text = repost.caption?.removeSpecialCharsFromString()
        captionLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
        
        if repost.new {
            cell?.backgroundColor = UIColor.groupTableViewBackground
        }
        
        guard let mediaUrl = URL(string: repost.imageUrl!) else { return cell! }
        mediaView.allowSound = false
        mediaView.show(mediaUrl: mediaUrl, thumbnailUrl: URL(string: repost.thumbnailUrl ?? ""))
 
        guard let profileUrl = URL(string: repost.profileUrl!) else { return cell! }
        profileImageView.kf.setImage(with: profileUrl)
        
        if mediaUrl.absoluteString.lowercased().contains("jpg") || mediaUrl.absoluteString.lowercased().contains("png") {
            videoInfoView?.isHidden = true
        } else {
            videoInfoView?.isHidden = false
        }
        
        return cell!
    }
    
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let repost = repostsResultsController.object(at: indexPath) as? Repost else {
            return
        }
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.backgroundColor = .white
        
        selectedRepost = repost
        performSegue(withIdentifier: "showRepostPreviewSegue", sender: self)
    }
    
    
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            guard let repost = repostsResultsController.object(at: indexPath) as? Repost else {
                return
            }
            repost.delete()
            CoreDataManager.shared.saveContext()
        }
    }
}


extension RepostViewController: NSFetchedResultsControllerDelegate {
    
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
            break
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
        
        Repost.count { (count) in
            if count == 0 {
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.repostInfoLabel.text = "Copy wanted Instagram Photo link"
                }
            } else {
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.repostInfoLabel.text = String(format: "%ld reposts", count)
                }
            }
        }
    }
}
