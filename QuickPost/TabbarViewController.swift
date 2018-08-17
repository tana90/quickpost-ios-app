//
//  TabbarViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 7/17/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import UserNotifications

final class TabbarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Connector.loadUserTags()
        Connector.loadUserHistory()
        Connector.loadPopularHashtags()
        Connector.loadTrends()
        
        
        EventHandler.shared.repostAvailable {
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                
                if self!.selectedIndex != 2 {
                    let alertViewController = UIAlertController(title: "🌅 New photo found for Repost", message: "Do you want to repost it?", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let repostAction = UIAlertAction(title: "Repost now", style: .default) { [weak self] (alert) in
                        guard let _ = self else { return }
                        AdManager.shared.registerAction(onView: self!.view)
                        self!.selectedIndex = 2
                    }
                    
                    let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
                    }
                    
                    alertViewController.addAction(repostAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
                
            }
        }
        
        
        UNUserNotificationCenter.current().delegate = self
    }
}


extension TabbarViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
}

