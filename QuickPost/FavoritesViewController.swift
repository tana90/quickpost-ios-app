//
//  FavoritesViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/24/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData

final class FavoritesViewController: UICollectionViewController {
    
    var blockOperations: [BlockOperation] = []
    var refreshControl = UIRefreshControl()
    let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    lazy var favoritesFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timestampSortDescriptor]
        let predicate = NSPredicate(format: "favorite == YES AND utility == NO")
        
        request.predicate = predicate
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    deinit {
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    @IBAction func helpAction() {
        present(helpSafariViewController, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try favoritesFetchedResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        //Put refresh control
        collectionView?.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)

    }
    
    @objc func refreshData() {
        
        Tag.fetchFavorites { (tags) in
            tags.forEach { (tag) in
                CoreDataManager.shared.delete(object: tag!)
            }
            CoreDataManager.shared.saveContext()
            
            guard let token = AppManager.loadToken() else { return }
            LoadingPopup.shared.show(onView: (self.navigationController?.view)!)
            Connector.shared.getFavoriteTags(with: token, with: { (json) in
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.refreshControl.endRefreshing()
                    LoadingPopup.shared.hide()
                }
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}







extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = favoritesFetchedResultsController.sections else {
            return 1
        }
        return sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        guard let sections = favoritesFetchedResultsController.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "addTagSectionHeader", for: indexPath)
        if let textField = headerView.viewWithTag(100) as? UITextField {
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        return headerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCellIdentifier", for: indexPath)
        
        guard let tag = favoritesFetchedResultsController.object(at: indexPath) as? Tag else {
            return cell
        }
        
        if let label = cell.viewWithTag(100) as? UILabel,
            let selectView = cell.viewWithTag(101) {
            
            let text = NSMutableAttributedString(string: tag.tag ?? "")
            text.set(color: UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1), for: "#")
            label.attributedText = text
            
            
            if let selectImageView = selectView.viewWithTag(100) as? UIImageView {
                if tag.confirmed {
                    selectImageView.alpha = 1.0
                } else {
                    selectImageView.alpha = 0.0
                }
            }
        }
        
        return cell
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let tag = favoritesFetchedResultsController.object(at: indexPath) as? Tag else {
            return
        }
        
        let alertViewController = UIAlertController(title: "Remove \(tag.tag ?? "")", message: "Are you sure you want to remove this hashtag ?", preferredStyle: .alert)
        alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
        let openAction = UIAlertAction(title: "Remove", style: .default) { [weak self] (alert) in
            guard let _ = self,
                let token = AppManager.loadToken() else { return }
            LoadingPopup.shared.show(onView: (self!.navigationController?.view)!)
            EventManager.shared.sendEvent(name: "remote_hashtag", type: "action")
            Connector.shared.removeFavoriteTag(with: token, and: tag.tag ?? "", with: { (json) in
                CoreDataManager.shared.delete(object: tag)
                CoreDataManager.shared.saveContext()
                DispatchQueue.main.safeAsync {
                    LoadingPopup.shared.hide()
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
        }
        
        alertViewController.addAction(openAction)
        alertViewController.addAction(cancelAction)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemsPerRow: CGFloat = 2
        if UI_USER_INTERFACE_IDIOM() == .pad {
            itemsPerRow = 4
        }
        let finalSize = CGSize(width: collectionView.bounds.size.width / itemsPerRow - 12, height: 44)
        return finalSize
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
}


extension FavoritesViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            
            var hashValue = textField.text?.replacingOccurrences(of: " ", with: "")
            hashValue = textField.text?.replacingOccurrences(of: "#", with: "")
            if (hashValue?.count)! > Int(0) {
                hashValue = String(format: "#%@", (hashValue?.lowercased())!)
                
                insert(hashTag: hashValue!, from:  textField)
            }

        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if (textField.text?.hasSuffix(" "))! {
            
            var hashValue = textField.text?.replacingOccurrences(of: " ", with: "")
            hashValue = textField.text?.replacingOccurrences(of: "#", with: "")
            if (hashValue?.count)! > Int(0) {
                hashValue = String(format: "#%@", (hashValue?.lowercased())!)
                
                insert(hashTag: hashValue!, from: textField)
                
                
            }
            
        }
    }
}


extension FavoritesViewController {
    
    func insert(hashTag: String, from textField: UITextField) {
        
        var trimmedHashtag = hashTag.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmedHashtag.contains(" ") {
            trimmedHashtag = trimmedHashtag.replacingOccurrences(of: " ", with: "")
        }
        
        guard trimmedHashtag.count > 1 else { return }
        
        AdManager.shared.registerAction(onView: tabBarController?.view)
        
        if PROVersion || favoritesFetchedResultsController.fetchedObjects?.count ?? 0 < MaxFavorite {
            
            
            var newTag = TagData()
            newTag.tag = trimmedHashtag
            newTag.favorite = true
            newTag.selected = false
            newTag.confirmed = false
            newTag.utility = false
            Tag.add(tagData: newTag)
            CoreDataManager.shared.saveContext()
            textField.text = ""
            textField.becomeFirstResponder()
            EventManager.shared.sendEvent(name: "add_hashtag", type: "action")
            Connector.setUser(tag: trimmedHashtag)
        } else {
            textField.resignFirstResponder()
            EventManager.shared.sendEvent(name: "favorites_limit_reached", type: "state")
            var style: UIAlertControllerStyle = .actionSheet
            if UI_USER_INTERFACE_IDIOM() == .pad {
                style = .alert
            }
            let alertViewController = UIAlertController(title: "Favorites limit reached", message: "You have reach the limit of \(MaxFavorite) free favourite hashtags. To continue using the app upgrade to PRO.", preferredStyle: style)
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            let upgradeAction = UIAlertAction(title: "Upgrade to PRO", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.performSegue(withIdentifier: "showStoreSegue", sender: self!)
            }
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
            }
            
            alertViewController.addAction(upgradeAction)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
}



extension FavoritesViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.insertSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.reloadSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView?.deleteSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView?.performBatchUpdates({ [weak self] in
            guard let _ = self else { return }
            for operation: BlockOperation in self!.blockOperations {
                operation.start()
            }
            }, completion: { (finished) in
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.blockOperations.removeAll(keepingCapacity: false)
                }
                
                
        })
    }
}
