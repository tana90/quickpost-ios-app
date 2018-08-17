//
//  StoreViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class StoreViewController: UIViewController {
    
    var unpurchasedText = """
    Get UNLIMITED hastags for Instagram photos,
        UNLIMITED reposts and schedules.  Analize as many picture as you want and get the best HASHTAGS
    """
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var detailsLabel: UILabel!
    
    
    @IBAction func closeAction() {
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func buyAction() {
        
        LoadingPopup.shared.show(onView: (navigationController?.view)!)
        PROUpgradeProduct.store.requestProducts { (success, products) in
            if success {
                guard let _ = products,
                    (products?.count)! > 0 else {
                        LoadingPopup.shared.hide()
                        
                        DispatchQueue.main.safeAsync { [weak self] in
                            guard let _ = self else { return }
                            let alertViewController = UIAlertController(title: "Oups...", message: "Something went wrong. Please try again a little bit later.", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) { _ in }
                            alertViewController.addAction(okAction)
                            self!.present(alertViewController, animated: true, completion: nil)
                        }
                        
                        return
                }
                PROUpgradeProduct.store.buyProduct((products?.first!)!)
            }
        }
    }
    
    
    @IBAction func restoreAction() {
        
        EventManager.shared.sendEvent(name: "restore_purchase", type: "action")
        LoadingPopup.shared.show(onView: (navigationController?.view)!)
        PROUpgradeProduct.store.restorePurchases()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        PROUpgradeProduct.store.requestProducts { (success, products) in
            if success {
                guard let _ = products,
                    (products?.count)! > 0 else { return }
                CachedPrice = priceStringForProduct(item: (products?.first)!)!
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    self!.updateUI()
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        
        EventHandler.shared.upgradeToPRO {
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                self!.updateUI()
                
                if PROVersion {
                    //Disable ads
                    AdManager.shared.disable()
                    
                    let alertViewController = UIAlertController(title: "Congratulations", message: "Congratulations for your purchase.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (alert) in
                        guard let _ = self else { return }
                        self!.closeAction()
                    }
                    
                    alertViewController.addAction(okAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                } else {
                    //Enable ads
                    AdManager.shared.enable()
                }
            }
        }
        updateUI()
    }
    
    
    func updateUI() {
        
        if PROVersion {
            self.detailsLabel.text = "PRO Upgrade Purchased"
            self.buyButton.alpha = 0.3
            self.buyButton.isEnabled = false
        } else {
            self.detailsLabel.text = """
            Get UNLIMITED hastags for Instagram photos,
                UNLIMITED reposts and schedules.  Analize as many picture as you want and get the best HASHTAGS for only
            \(CachedPrice)
            """
            self.buyButton.alpha = 1.0
            self.buyButton.isEnabled = true
        }
    }
    
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        
        LoadingPopup.shared.hide()
        guard let productID = notification.object as? String,
            productID == "com.aww.quickpostig.proupgradeiap" else {
                
                let alertViewController = UIAlertController(title: "Unable to purchase", message: "Please try again", preferredStyle: .alert)
                alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                }
                
                alertViewController.addAction(okAction)
                self.present(alertViewController, animated: true, completion: nil)
                return
        }
        
        PROVersion = true
        EventManager.shared.sendEvent(name: "pro_upgrade_activated", type: "action")
    }
}
