//
//  KeyboardViewController.swift
//  QuickPostKeyboard
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData

class KeyboardViewController: UIInputViewController {
    
    var blockOperations: [BlockOperation] = []
    lazy var tagsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
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

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var openAppButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    
    
    @IBAction func nextKeyboard() {
        advanceToNextInputMode()
    }
    
    @IBAction func deleteAction() {
        var value = (textDocumentProxy.documentContextBeforeInput ?? "") + (textDocumentProxy.documentContextAfterInput ?? "")
        value = reverse(value)
        
        var index = value.indexDistance(of: " ") ?? 0
        if index == 0 {
            index = value.indexDistance(of: "#") ?? 0
        }
        
        playPressKeySound()
        for _ in 0...index {
            textDocumentProxy.deleteBackward()
        }
    }
    
    @IBAction func openApp() {
        openApp("quickpost://favorites")
    }

    func reverse(_ s: String) -> String {
        var str = ""
        for character in s {
            str = "\(character)" + str
        }
        return str
    }

    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()

    
        let nib = UINib(nibName: "KeyboardView", bundle: nil)
        let objects = nib.instantiate(withOwner: self, options: nil)
        view = objects[0] as! UIView
        view.frame.size = view.frame.size
        
        
        
        let cellNib = UINib(nibName: "KeyboardTag", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "tagCellIdentifier")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        do {
            try tagsFetchedResultsController.performFetch()
        } catch _ {
            po("Error performing fetch products")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
    }
}

extension KeyboardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = tagsFetchedResultsController.sections else {
            return 1
        }
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let sections = tagsFetchedResultsController.sections else {
            infoLabel.alpha = 0.0
            openAppButton.alpha = 0.0
            return 0
        }
        let sectionInfo = sections[section]
        let numOfObjects = sectionInfo.numberOfObjects
        if numOfObjects > 0 {
            infoLabel.alpha = 0.0
            openAppButton.alpha = 0.0
        } else {
            infoLabel.alpha = 1.0
            openAppButton.alpha = 1.0
        }
        return numOfObjects
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCellIdentifier", for: indexPath)
        
        guard let tag = tagsFetchedResultsController.object(at: indexPath) as? Tag else {
            return cell
        }
        
        if let label = cell.viewWithTag(100) as? UILabel {
            
            let text = NSMutableAttributedString(string: tag.tag ?? "")
            text.set(color: UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1), for: "#")
            label.attributedText = text
        }
        
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
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8 //Horizontal
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tag = tagsFetchedResultsController.object(at: indexPath) as? Tag else {
            return
        }
        playPressKeySound()
        self.textDocumentProxy.insertText(" \(tag.tag!)")
    }
}


extension KeyboardViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        collectionView.reloadData()
    }
}



extension KeyboardViewController {

    func openApp(_ urlstring: String) {

        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))
        while responder != nil {
            if responder!.responds(to: selector) && responder != self {
                responder!.perform(selector, with: URL(string: urlstring)!)
                return
            }
            responder = responder?.next
        }
    }

    @objc func openURL(_ url: URL) {
        return
    }
}
