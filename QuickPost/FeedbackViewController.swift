//
//  FeedbackViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/5/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class FeedbackViewController: UITableViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    
    @IBAction func closeAction() {
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func sendAction() {
        
        guard let token = AppManager.loadToken(),
            let text = textView.text,
            text.count > 0 else {
                return
        }
        
        var trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmedText = trimmedText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        guard trimmedText.count > 1 else { return }
        
        LoadingPopup.shared.show(onView: (navigationController?.view!)!)
        Connector.shared.sendFeedback(with: token, and: trimmedText) { (json) in

            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                LoadingPopup.shared.hide()
                
                let alertViewController = UIAlertController(title: "🎉", message: "Thanks for your feedback", preferredStyle: .alert)
                alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                let okAction = UIAlertAction(title: "Close", style: .cancel) { [weak self] (alert) in
                    guard let _ = self else { return }
                    self!.closeAction()
                }
                
                alertViewController.addAction(okAction)
                self!.present(alertViewController, animated: true, completion: nil)
            }
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        textView.becomeFirstResponder()
    }
}
