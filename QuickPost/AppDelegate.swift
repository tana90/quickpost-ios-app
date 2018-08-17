//
//  AppDelegate.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let token = AppManager.initApp()
    
    static let shared: AppDelegate = {
        let instance = AppDelegate()
        return instance
    }()
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        application.applicationIconBadgeNumber = 0
        PROVersion = true
        phoneLocked = false
        //Load appstore IAP
        PROUpgradeProduct.store.requestProducts { (success, products) in
            po(products)
            if success {
                guard let _ = products,
                    (products?.count)! > 0 else { return }
                CachedPrice = priceStringForProduct(item: (products?.first)!)!
            }
        }

        EventManager.shared.sendEvent(name: "app_started", type: "app")
        
        
        if !UserDefaults.standard.bool(forKey: "AUTHENTICATED") {
            allowAutoSelect = true
            Connector.shared.registerUser(with: self.token) { (json) in

                if let _ = json?.dictionary,
                    let status = json?.dictionary!["status"]?.string,
                    status == "0" {
                    UserDefaults.standard.set(true, forKey: "AUTHENTICATED")
                    
                    NotificationManager.shared.requestAuthorization(completionHandler: { (status) in
                        
                    })
                    
                    
                }
            }
        }
        
        
        if !PROVersion {
            AdManager.shared.enable()
        } else {
            AdManager.shared.disable()
        }
        
        
        //Set time interval between App Background Refreshes
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        

        return true
    }
    
    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        po("Unlock")
        phoneLocked = false
    }
    
    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
        po("Lock")
        phoneLocked = true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        var deviceId = String(format: "%@", deviceToken as CVarArg)
        deviceId = deviceId.replacingOccurrences(of: "<", with: "")
        deviceId = deviceId.replacingOccurrences(of: ">", with: "")
        deviceId = deviceId.replacingOccurrences(of: " ", with: "")
        
        Connector.shared.registerDevice(with: self.token, with: deviceId) { (json) in
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        SEOManager.shared.start()
        AppManager.shared.loadSettings { (finished) in
            po("Update from receive remote notif")
            completionHandler(.newData)
        }
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        EventHandler.shared.openFavorites()
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        SEOManager.shared.start()
        AppManager.shared.loadSettings { (finished) in
            po("Update from fetch")
            completionHandler(.newData)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        RepostManager.shared.checkClipboard()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        RepostManager.shared.checkClipboard()
    }
}


