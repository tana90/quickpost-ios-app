//
//  InputTextPopup.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/4/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import CoreData

final class InputTextPopup: UIView {
    
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    var newShown = true
    
    @IBAction func closeAction() {
        hide()
    }
    
    @IBAction func addAction() {
        guard let text = inputTextField.text,
            text.count > Int(0) else { return }
        
        var hashValue = inputTextField.text?.replacingOccurrences(of: " ", with: "")
        hashValue = inputTextField.text?.replacingOccurrences(of: "#", with: "")
        if (hashValue?.count)! > Int(0) {
            hashValue = String(format: "#%@", (hashValue?.lowercased())!)
            
            insert(hashTag: hashValue!, from: inputTextField)
            
            
        }
    }
    
    static let shared: InputTextPopup = {
        var instance = InputTextPopup()
        instance = Bundle.main.loadNibNamed("InputTextPopup", owner: instance, options: nil)?.first as! InputTextPopup
        instance.alpha = 0.0
        return instance
    }()
    
    func show(onView: UIView) {
        onView.addSubview(self)
        self.frame = CGRect(x: 0, y: 0, width: onView.bounds.size.width, height: onView.bounds.size.height)
        
        
        if newShown == true {
            newShown = false
            self.popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
        }
        UIView.animate(withDuration: 0.25) { [unowned self] in
            self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.alpha = 1.0
        }
        
        inputTextField.becomeFirstResponder()
        
        inputTextField.delegate = self
        inputTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func hide() {
        addButton.alpha = 0.3
        addButton.isEnabled = true
        inputTextField.text = ""
        inputTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: { [unowned self] in
            self.popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0.0
        }) { [unowned self] (finished) in
            if finished {
                self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.newShown = true
                self.removeFromSuperview()
            }
        }
    }
}



extension InputTextPopup: UITextFieldDelegate {
    
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
        
        if (textField.text?.count)! > Int(0) {
            addButton.alpha = 1.0
            addButton.isEnabled = true
        } else {
            addButton.alpha = 0.3
            addButton.isEnabled = true
        }
        
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


extension InputTextPopup {
    
    func insert(hashTag: String, from textField: UITextField) {
        
        Tag.countSelected { (countSelected) in
            
            var trimmedHashtag = hashTag.trimmingCharacters(in: .whitespacesAndNewlines)
            while trimmedHashtag.contains(" ") {
                trimmedHashtag = trimmedHashtag.replacingOccurrences(of: " ", with: "")
            }
            
            guard trimmedHashtag.count > 1 else { return }
            
            var newTag = TagData()
            newTag.tag = trimmedHashtag
            newTag.favorite = true
            
            newTag.selected = countSelected - 1 < 29 ? true : false
            newTag.confirmed = false
            newTag.utility = false
            Tag.add(tagData: newTag)
            CoreDataManager.shared.saveContext()
            textField.text = ""
            textField.becomeFirstResponder()
            
            Connector.setUser(tag: trimmedHashtag)
            
            closeAction()
        }
    }
    
}
