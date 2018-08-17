//
//  HomeViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreMedia
import Photos
import CoreData
import StoreKit

final class HomeViewController: UIViewController {
    
    var blockOperations: [BlockOperation] = []
    
    lazy var tagsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
        let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
        let favoriteSortDescriptor = NSSortDescriptor(key: "favorite", ascending: false)
        let utilitySortDescriptor =  NSSortDescriptor(key: "utility", ascending: false)
        
        let predicate = NSPredicate(format: "confirmed == true")
        request.sortDescriptors = [utilitySortDescriptor, favoriteSortDescriptor, timestampSortDescriptor]
        request.predicate = predicate
        request.fetchBatchSize = 100
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataManager.shared.managedObjectContext,
                                             sectionNameKeyPath: "favorite",
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
    @IBOutlet weak var scheduleBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var resultsCollectionView: UICollectionView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var selectPictureButton: UIButton!
    @IBOutlet weak var placeholderImageView: UIImageView!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    var finishedScrolling = false
    
    @IBOutlet weak var aspiectConstraint: NSLayoutConstraint!
    
    let imagePicker = UIImagePickerController()
    
    var instagramURL: URL = URL(string: "instagram://")!
    
    var selectedScheduleData: ScheduleData = ScheduleData()
    
    @IBAction func schedulesAction() {
        performSegue(withIdentifier: "showScheduledPostsSegue", sender: self)
    }
    
    
    @IBAction func selectPhotoAction() {
        
        
        if MaxPhotos + RateAppOffer > Int(AppManager.loadNumberOfScans()) ?? 0 || PROVersion {
            
            var style: UIAlertControllerStyle = .actionSheet
            if UI_USER_INTERFACE_IDIOM() == .pad {
                style = .alert
            }
            
            let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: style)
            
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            imagePicker.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            let camera = UIAlertAction(title: "Camera", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.imagePicker.allowsEditing = false
                self!.imagePicker.sourceType = .camera
                self!.imagePicker.navigationBar.topItem?.rightBarButtonItem?.tintColor = .black
                self!.present(self!.imagePicker, animated: true, completion: nil)
                self!.requestSavePhotoPermission()
                EventManager.shared.sendEvent(name: "open_camera", type: "action")
            }
            
            let library = UIAlertAction(title: "Photo library", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.imagePicker.allowsEditing = false
                self!.imagePicker.sourceType = .photoLibrary
                self!.imagePicker.navigationBar.topItem?.rightBarButtonItem?.tintColor = .black
                self!.present(self!.imagePicker, animated: true, completion: nil)
                self!.requestSavePhotoPermission()
                EventManager.shared.sendEvent(name: "open_photo_library", type: "action")
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            }
            
            alertViewController.addAction(camera)
            alertViewController.addAction(library)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
        } else {
            EventManager.shared.sendEvent(name: "scan_limit_reached", type: "state")
            var style: UIAlertControllerStyle = .actionSheet
            if UI_USER_INTERFACE_IDIOM() == .pad {
                style = .alert
            }
            
            let alertViewController = UIAlertController(title: "Photos limit reached", message: "You have reach the limit of \(MaxPhotos + RateAppOffer) free photos. To continue using the app upgrade to PRO.", preferredStyle: style)
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            let upgradeAction = UIAlertAction(title: "Upgrade to PRO", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.performSegue(withIdentifier: "showStoreSegue", sender: self!)
            }
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
                
                self.showRateTip()
            }
            
            alertViewController.addAction(upgradeAction)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
            
            
        }
        
        
    }
    
    @IBAction func postAction() {
        
        if previewImageView.image != nil {
            AdManager.shared.registerAction(onView: tabBarController?.view)
            
            Tag.fetchSelected { (results) in
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    
                    guard results.count > 0 else {
                        let alertViewController = UIAlertController(title: "Warning", message: "You haven't selected any hastags.", preferredStyle: .alert)
                        alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                        let openAction = UIAlertAction(title: "Post anyway", style: .default) { [weak self] (alert) in
                            guard let _ = self else { return }
                            self!.openInsagram()
                        }
                        let scheduleAction = UIAlertAction(title: "Schedule post", style: .default) { (alert) in
                            DispatchQueue.main.safeAsync { [weak self] in
                                guard let _ = self else { return }
                                var scheduleData = ScheduleData()
                                scheduleData.objectId = NSUUID().uuidString
                                scheduleData.picture = UIImageJPEGRepresentation(self!.previewImageView.image!, 1.0);
                                scheduleData.caption = ""
                                self!.selectedScheduleData = scheduleData
                                self?.performSegue(withIdentifier: "showAddScheduleSegue", sender: self)
                            }
                        }
                        let cancelAction = UIAlertAction(title: "Review", style: .cancel) { (alert) in
                        }
                        
                        alertViewController.addAction(openAction)
                        alertViewController.addAction(scheduleAction)
                        alertViewController.addAction(cancelAction)
                        self!.present(alertViewController, animated: true, completion: nil)
                        return
                    }
                    
                    
                    var message: String = ""
                    results.forEach { (tag) in
                        if let _ = tag?.tag {
                            message.append("\(tag!.tag!) ")
                        }
                    }
                    
                    UIPasteboard.general.string = message
                    let alertViewController = UIAlertController(title: "You're ready!", message: "Hashtags copied to clipboard.\nPaste them in Caption area. 👏\nOr schedule this post for later.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let openAction = UIAlertAction(title: "Post now", style: .default) { (alert) in
                        self!.openInsagram()
                    }
                    
                    let scheduleAction = UIAlertAction(title: "Schedule post", style: .default) { (alert) in
                        DispatchQueue.main.safeAsync { [weak self] in
                            guard let _ = self else { return }
                            var scheduleData = ScheduleData()
                            scheduleData.objectId = NSUUID().uuidString
                            scheduleData.picture = UIImageJPEGRepresentation(self!.previewImageView.image!, 1.0);
                            scheduleData.caption = message
                            self!.selectedScheduleData = scheduleData
                            self?.performSegue(withIdentifier: "showAddScheduleSegue", sender: self)
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
                    }
                    
                    alertViewController.addAction(openAction)
                    alertViewController.addAction(scheduleAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            }
        } else {
            selectPhotoAction()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        countView.alpha = 0.0
        infoLabel.alpha = 1.0
        imagePicker.delegate = self
        resultsCollectionView.alpha = 0
        Tag.deleteUnfavorite()
        
        do {
            try self.tagsFetchedResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
        
        //Add utility tag
        var tagData = TagData()
        tagData.confirmed = true
        tagData.tag = "Add new"
        tagData.favorite = true
        tagData.selected = false
        tagData.utility = true
        Tag.add(tagData: tagData)
        
        
        AppManager.shared.loadSettings { (finished) in
            SEOManager.shared.start()
        }
        
        titleImageView.image = UIImage(named: PROVersion ? "navtitlepro" : "navtitle")
        EventHandler.shared.upgradeToPRO {
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                self!.titleImageView.image = UIImage(named: PROVersion ? "navtitlepro" : "navtitle")
            }
        }
        
        EventHandler.shared.openFavorites {
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                self!.performSegue(withIdentifier: "showFavoritesSegue", sender: self!)
            }
        }
        
        
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            aspiectConstraint.constant = (UIScreen.main.bounds.size.height * (30/100))
        } else {
            aspiectConstraint.constant = 66
        }

        RepostManager.shared.checkClipboard()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddScheduleSegue" {
            let destination = (segue.destination as! UINavigationController).viewControllers[0] as! AddScheduleViewController
            destination.selectedScheduleData = self.selectedScheduleData
            destination.completionHandler = {
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.showScheduleAnimation()
                }
            }
        }
    }
    
    func requestSavePhotoPermission() {
        PHPhotoLibrary.shared().performChanges({
        }, completionHandler: { success, error in
        })
    }
}

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        EventManager.shared.sendEvent(name: "image_picked: \(AppManager.loadNumberOfScans())", type: "action")
        AdManager.shared.registerAction(onView: tabBarController?.view)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            previewImageView.contentMode = .scaleAspectFill
            previewImageView.image = pickedImage
            infoLabel.alpha = 0.0
            placeholderImageView.alpha = 0.0
            
            Tag.deleteUnfavorite()
            resultsCollectionView.alpha = 1
            
            LoadingPopup.shared.show(onView: self.view)
            AppManager.incrementNumberOfScans()
            
            DispatchQueue.background(delay: 0.3, background: {
                Analizer.shared.analize(image: pickedImage) { (status) in
                    DispatchQueue.main.safeAsync {
                        LoadingPopup.shared.hide()
                        self.showHashtagTip()
                    }
                }
            }, completion: nil)
            
            if let imageURL = info["UIImagePickerControllerReferenceURL"] as? URL {
                let instaUrl = String(format: "instagram://library?AssetPath=%@", imageURL.absoluteString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                
                if let url = URL(string: instaUrl) {
                    instagramURL = url
                }
            } else {
                //Save image to Camera Roll
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: pickedImage)
                }, completionHandler: { success, error in
                    if success {
                        
                        DispatchQueue.main.safeAsync { [weak self] in
                            guard let _ = self else { return }
                            let lastPHAsset = self!.fetchLatestPhotos(forCount: 1)
                            guard let asset = lastPHAsset.firstObject else { return }
                            
                            var id = asset.localIdentifier
                            if id.contains("/") {
                                if let first = id.components(separatedBy: "/").first {
                                    id = first
                                }
                            }
                            let assetLibrary = String(format: "assets-library://asset/asset.JPG?id=%@&ext=JPG", id)
                            let instaUrl = String(format: "instagram://library?AssetPath=%@", assetLibrary.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                            if let url = URL(string: instaUrl) {
                                self!.instagramURL = url
                            }
                        }
                    }
                    else if let _ = error {
                    }
                    else {
                        
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
}


extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath)
        if let label = headerView.viewWithTag(100) as? UILabel,
            let favoritesButton = headerView.viewWithTag(101) as? UIButton,
            let selectAllButton = headerView.viewWithTag(102) as? UIButton {
            
            selectAllButton.addTarget(self, action: #selector(selectAllFavorites), for: .touchUpInside)
            
            if indexPath.section > 0 {
                label.text = "RECOMMENDED"
                favoritesButton.isEnabled = false
                selectAllButton.isEnabled = false
                selectAllButton.alpha = 0.0
            } else {
                label.text = "SAVED HASHTAGS"
                favoritesButton.isEnabled = true
                selectAllButton.isEnabled = true
                selectAllButton.alpha = 1.0
            }
        }
        return headerView
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard let sections = tagsFetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
        guard let sections = tagsFetchedResultsController.sections else {
            fatalError("No sections in newsFetchedREsultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCellIdentifier", for: indexPath)
        
        guard let tag = tagsFetchedResultsController.object(at: indexPath) as? Tag else {
            return cell
        }
        
        let label = cell.viewWithTag(100) as! UILabel
        let selectView = cell.viewWithTag(101)!
        
        let selectImageView = selectView.viewWithTag(100) as! UIImageView
        let selectBackImageView = selectView.viewWithTag(200) as! UIImageView
        
        let text = NSMutableAttributedString(string: tag.tag ?? "")
        
        if !tag.utility {

            if tag.selected {
                cell.backgroundColor = UIColor(red: 1, green: 6/255, blue: 84/255, alpha: 0.05)
                selectView.backgroundColor = UIColor(red: 1, green: 6/255, blue: 84/255, alpha: 1)
                label.textColor = .black
                text.set(color: UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1), for: "#")
                cell.borderColor =  UIColor(red: 1, green: 6/255, blue: 84/255, alpha: 1)
                selectBackImageView.image = UIImage(named: "banner")
            } else {
                cell.backgroundColor = .white
                selectView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
                label.textColor = .black
                text.set(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.3), for: "#")
                cell.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.04)
                selectBackImageView.image = UIImage(named: "banner-gray")
            }

            if tag.favorite {
                selectImageView.image = UIImage(named: "favorite")
            } else {
                selectImageView.image = UIImage(named: "check")
            }
            
        } else {
            
            cell.backgroundColor = .white
            cell.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.04)
            
            if selectView.backgroundColor != UIColor(red: 1, green: 6/255, blue: 84/255, alpha: 1) {
                selectView.backgroundColor = UIColor(red: 1, green: 6/255, blue: 84/255, alpha: 1)
            }
            label.textColor = .black
            text.set(color: UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1), for: "Add new")
            selectImageView.image = UIImage(named: "uncheck")
            selectBackImageView.image = UIImage(named: "banner")
        }
        
        label.attributedText = text
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var itemsPerRow: CGFloat = 2
        if UI_USER_INTERFACE_IDIOM() == .pad {
            itemsPerRow = 4
        }
        let finalSize = CGSize(width: collectionView.bounds.size.width / itemsPerRow - 12, height: 42)
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
    
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        guard let tag = tagsFetchedResultsController.object(at: indexPath) as? Tag else {
            return
        }
        
        if tag.utility == false {
            Tag.countSelected { (count) in
                
                guard count < 30 || tag.selected == true  else {
                    let alertViewController = UIAlertController(title: "", message: "Instagram has a limit of 30 hashtags.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "I understand", style: .default) { (alert) in
                    }
                    alertViewController.addAction(okAction)
                    self.present(alertViewController, animated: true, completion: nil)
                    UIView.animate(withDuration: 0.2, animations: { [weak self] in
                        guard let _ = self else { return }
                        self!.countView.transform = CGAffineTransform(scaleX: 1.7, y: 1.7)
                    }) { (finished) in
                        if finished {
                            UIView.animate(withDuration: 0.1, animations: { [weak self] in
                                guard let _ = self else { return }
                                self!.countView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                            }) { (finished) in
                                
                            }
                        }
                    }
                    return
                }
                tag.selected = !tag.selected
                
                Tag.fetchSelected { (results) in
                    var message: String = ""
                    results.forEach { (tag) in
                        if let _ = tag?.tag {
                            message.append("\(tag!.tag!)  ")
                        }
                    }
                    
                    BannerPreview.shared.show(onView: self.view, with: message)
                }
                playPressKeySound()
                CoreDataManager.shared.saveContext()
            }
        } else {
            
            Tag.fetchFavorites { (results) in
                
                if PROVersion || results.count < MaxFavorite {
                    InputTextPopup.shared.show(onView: self.view)
                } else {
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
    }  
}


extension HomeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let topValue = -(self.previewImageView.frame.size.height * (75/100))
        
        if scrollView.frame.size.height < scrollView.contentSize.height - 88 {
            
            if scrollView.contentOffset.y > 0  {
                var value = 0 - (scrollView.contentOffset.y)
                if value <= topValue {
                    value = topValue
                    finishedScrolling = true
                } else {
                    finishedScrolling = false
                }
                
                if finishedScrolling == false {
                    if UI_USER_INTERFACE_IDIOM() == .pad {
                        topConstraint.constant = 0
                    } else {
                        topConstraint.constant = value
                    }
                }
            } else   {
                topConstraint.constant = 0
            }
        }
    }
}


extension HomeViewController {
    
    func openInsagram() {
        
        EventManager.shared.sendEvent(name: "post_photo_open_insta", type: "action")
        
        UIApplication.shared.open(instagramURL, options: [:], completionHandler: { [weak self] (success) in
            
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
        
        //Send history
        guard let caption = UIPasteboard.general.string else { return }
        Connector.setUserHistory(caption: caption)
    }
    
}


extension HomeViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        Tag.countSelected { (count) in
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                if count > 0 {
                    self!.countView.alpha = 1.0
                    self!.countLabel.text = String(format: "%ld/30", count)
                } else {
                    self!.countView.alpha = 0.0
                }
            }
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange sectionInfo: NSFetchedResultsSectionInfo,
                           atSectionIndex sectionIndex: Int,
                           for type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.insertSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.reloadSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.resultsCollectionView.deleteSections(IndexSet([sectionIndex]))
                    }
                })
            )
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        resultsCollectionView.performBatchUpdates({ [weak self] in
            guard let _ = self else { return }
            for operation: BlockOperation in self!.blockOperations {
                operation.start()
            }
            }, completion: { [weak self] (finished) in
                guard let _ = self else { return }
                self!.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}


extension HomeViewController {
    
    func fetchLatestPhotos(forCount count: Int?) -> PHFetchResult<PHAsset> {
        
        // Create fetch options.
        let options = PHFetchOptions()
        
        // If count limit is specified.
        if let count = count { options.fetchLimit = count }
        
        // Add sortDescriptor so the lastest photos will be returned.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        options.sortDescriptors = [sortDescriptor]
        
        // Fetch the photos.
        return PHAsset.fetchAssets(with: .image, options: options)
        
    }
    
    func showScheduleAnimation() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            let image = self.view.takeScreenshot()
            let screenshotImageView = UIImageView(image: image)
            screenshotImageView.contentMode = .scaleAspectFit
            screenshotImageView.frame = UIScreen.main.bounds
            screenshotImageView.alpha = 1.0
            screenshotImageView.cornerRadius = 10
            self.navigationController?.view.addSubview(screenshotImageView)
            
            UIView.animate(withDuration: 0.4, delay: 0.01, options: UIViewAnimationOptions.curveEaseIn, animations: {
                screenshotImageView.center = CGPoint(x: 22, y: 22)
                screenshotImageView.transform = CGAffineTransform.init(scaleX: 0.01, y: 0.01)
                screenshotImageView.alpha = 0.0
            }) { (finished) in
                screenshotImageView.removeFromSuperview()
            }
        }
        
        
    }
    
    @objc func selectAllFavorites() {
        Tag.fetchUnselectedFavorites { (results) in
            
            Tag.countSelected { (countSelected) in
                
                results.enumerated().forEach { (index, element) in
                    
                    if index < 30 - countSelected {
                        element?.selected = true
                    }
                }
                
                CoreDataManager.shared.saveContext()
                
                Tag.fetchSelected { (results) in
                    var message: String = ""
                    results.forEach { (tag) in
                        if let _ = tag?.tag {
                            message.append("\(tag!.tag!)  ")
                        }
                    }
                    
                    BannerPreview.shared.show(onView: self.view, with: message)
                }
            }
        }
    }
    
    
    func showHashtagTip() {
        if ShowHashtagsTip == false {
            ShowHashtagsTip = true
            
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                let alertViewController = UIAlertController(title: "🎉", message: "We've found some amazing hashtags for you", preferredStyle: .alert)
                alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                let okAction = UIAlertAction(title: "Let's begin", style: .cancel) { (alert) in
                }
                
                alertViewController.addAction(okAction)
                self!.present(alertViewController, animated: true, completion: nil)
            }
        }
    }
    
    
    func showRateTip() {
        
        if !PROVersion {
            
            if ShowRateTip == false {
                ShowRateTip = true
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    let alertViewController = UIAlertController(title: "QuickPost", message: "Rate our app and get 5 free more actions.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "Rate app", style: .cancel) { (alert) in
                        SKStoreReviewController.requestReview()
                        
                        if RateAppOffer == 0 {
                            let alertViewController = UIAlertController(title: "🎉", message: "Now you have 5 free more action", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) {(alert) in
                            }
                            alertViewController.addAction(okAction)
                            self!.present(alertViewController, animated: true, completion: nil)
                            
                            EventManager.shared.sendEvent(name: "rate_app", type: "action")
                        }
                        
                        RateAppOffer = 5
                    }
                    let cancelAction = UIAlertAction(title: "Later", style: .default) { (alert) in
                    }
                    
                    alertViewController.addAction(okAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
