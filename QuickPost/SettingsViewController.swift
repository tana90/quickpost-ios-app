//
//  SettingsViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/24/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit

var allowAutoSelect: Bool {
    get { return UserDefaults.standard.bool(forKey: "ALLOW_AUTO_SELECT") }
    set { UserDefaults.standard.set(newValue, forKey: "ALLOW_AUTO_SELECT") }
}

var tcSafariViewController: SFSafariViewController = {
    let viewController = SFSafariViewController(url: URL(string: TermsAndConditionsURL)!)
    viewController.view.cornerRadius = 10
    viewController.preferredBarTintColor = UIColor.white
    viewController.preferredControlTintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
    return viewController
}()

var helpSafariViewController: SFSafariViewController = {
    let viewController = SFSafariViewController(url: URL(string: HelpURL)!)
    viewController.view.cornerRadius = 10
    viewController.preferredBarTintColor = UIColor.white
    viewController.preferredControlTintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
    return viewController
}()


final class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var proVersionLabel: UILabel!
    @IBOutlet weak var autoselectSwitch: UISwitch!
    @IBOutlet weak var numberOfScans: UILabel!
    @IBOutlet weak var numberOfReposts: UILabel!
    @IBOutlet weak var numberOfFavorites: UILabel!
    
    @IBAction func helpAction() {
        present(helpSafariViewController, animated: true, completion: nil)
    }
    
    @IBAction func autoselectAction() {
        allowAutoSelect = autoselectSwitch.isOn
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        autoselectSwitch.isOn = allowAutoSelect
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUI()
        AdManager.shared.registerAction(onView: tabBarController?.view)
    }
    
    func updateUI() {
        
        numberOfScans.text = AppManager.loadNumberOfScans() == "" ? "0" : AppManager.loadNumberOfScans()
        numberOfReposts.text = AppManager.loadNumberOfReposts() == "" ? "0" : AppManager.loadNumberOfReposts()
        Tag.count { (result)  in
            DispatchQueue.main.safeAsync { [weak self] in
                guard let _ = self else { return }
                self!.numberOfFavorites.text = String(format: "%ld", result)
            }
        }
        
        if PROVersion {
            //PRO
            self.proVersionLabel.text = "PRO Upgrade Purchased"
        } else {
            //No PRO
            self.proVersionLabel.text = "Upgrade to PRO now"
        }
    }
}

extension SettingsViewController {
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            if PROVersion {
                return "Tell us your opinion about this app"
            } else {
                return "Rate this app and get 5 free more photos"
            }
        } else {
            return super.tableView(tableView, titleForFooterInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            switch indexPath.row  {
            case 0:
                break
            case 1:
                tabBarController?.selectedIndex = 0
                break
            case 2:
                tabBarController?.selectedIndex = 1
                break
            case 3:
                tabBarController?.selectedIndex = 3
                break
            case 4:
                break
            case 5:
                present(tcSafariViewController, animated: true, completion: nil)
                break
            case 6:
                present(helpSafariViewController, animated: true, completion: nil)
                break
            default:
                break
            }
        }
        
        if indexPath.section == 2 {
            if indexPath.row == 1 {
                
                
                SKStoreReviewController.requestReview()
                
                if RateAppOffer == 0 {
                    
                    EventManager.shared.sendEvent(name: "rate_app", type: "action")
                    
                    let alertViewController = UIAlertController(title: "🎉", message: "Now you have 5 free more actions", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                    }
                    alertViewController.addAction(okAction)
                    self.present(alertViewController, animated: true, completion: nil)
                }
                
                RateAppOffer = 5
                
                updateUI()
            }
        }
    }
}

extension SettingsViewController {
    
    
    
}
