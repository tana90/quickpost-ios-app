//
//  EditCaptionViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/4/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class EditCaptionViewController: UITableViewController {
    
    @IBOutlet weak var captionTextView: UITextView!
    
    public var completionHandler: ((String) -> ())?
    var selectedText: String?
    
    
    @IBAction func closeAction() {
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneAction() {
        
        if let _ = completionHandler {
            completionHandler!(captionTextView.text)
        }
        closeAction()
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        captionTextView.text = selectedText ?? ""
        captionTextView.becomeFirstResponder()
    }
}
