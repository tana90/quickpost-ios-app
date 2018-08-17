//
//  AdManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/30/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

struct AdData {
    var title: String?
    var subtitle: String?
    var imageUrl: String?
    var actionUrl: String?
}


final class AdManager {
    
    private var adIndex: Int {
        get { return UserDefaults.standard.integer(forKey: "ADD_INDEX") }
        set { UserDefaults.standard.set(newValue, forKey: "ADD_INDEX") }
    }
    
    private var numOfActions: Int {
        get { return UserDefaults.standard.integer(forKey: "ADD_NUM_OF_ACTIONS") }
        set { UserDefaults.standard.set(newValue, forKey: "ADD_NUM_OF_ACTIONS") }
    }
    
    private var active: Bool {
        get { return UserDefaults.standard.bool(forKey: "ADS_ARE_ACTIVE") }
        set { UserDefaults.standard.set(newValue, forKey: "ADS_ARE_ACTIVE") }
    }
    
    let adURL = URL(string: "https://www.aww-coding.com/ads/list.php")!
    var ads: [AdData] = []
    
    static let shared: AdManager = {
        let instance = AdManager()
        instance.loadAds()
        return instance
    }()
    
    func loadAds() {
        
        var request = URLRequest(url: adURL)
        request.timeoutInterval = 30
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { [weak self] (data, httpResponse, error) in
            
            do {
                guard error == nil,
                    let _ = data else {
                        return
                }
                
                let json = try JSON(data: data!)

                guard let _ = self,
                    let jsonArray = json["ads"].array else { return }
                
                for json in jsonArray {
                    var adData = AdData()
                    adData.title = json["title"].string
                    adData.subtitle = json["subtitle"].string
                    adData.imageUrl = json["image"].string
                    adData.actionUrl = json["url"].string
                    self!.ads.append(adData)
                }
            } catch {
                po(error)
            }
            
            }.resume()
    }
    
    func registerAction(onView: UIView?) {

        if !DisableAds {
            if active {
                numOfActions += 1
                
                guard ads.count > 0 else {
                    loadAds()
                    return
                }
                
                if numOfActions % AdFrequency == 0 {
                    guard let _ = onView else { return }
                    AdPopup.shared.show(onView: onView!, with: ads[adIndex % ads.count])
                    adIndex += 1
                    AdPopup.shared.noAdActionHandler = {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let controller = storyboard.instantiateViewController(withIdentifier: "StoreNavigationController")
                        guard let parentViewController = onView?.parentViewController else { return }
                        parentViewController.present(controller, animated: true, completion: nil)
                    }
                    AdPopup.shared.adActionHandler = { (url) in
                        if let _ = URL(string: url) {
                            let viewController = SFSafariViewController(url: URL(string: url)!)
                            viewController.view.cornerRadius = 10
                            viewController.preferredBarTintColor = UIColor.white
                            guard let parentViewController = onView?.parentViewController else { return }
                            parentViewController.present(viewController, animated: true, completion: nil)
                        }
                        
                    }
                }
            }
        }
        
    }
    
    
    func enable() {
        active = true
    }
    
    func disable() {
        active = false
    }
}
