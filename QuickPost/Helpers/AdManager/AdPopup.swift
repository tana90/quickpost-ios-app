//
//  AdPopup.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/30/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class AdPopup: UIView {
    
    @IBOutlet weak var adImageView: UIImageView!
    var newShown = true
    var noAdActionHandler: (() -> ())?
    var adActionHandler: ((String) -> ())?
    var adData: AdData?
    
    @IBAction func closeAction() {
        hide()
    }
    
    @IBAction func noAdAction() {
        if let _ = noAdActionHandler {
            noAdActionHandler!()
        }
        closeAction()
    }
    
    @IBAction func adAction() {
        if let _ = adActionHandler,
            let actionUrl = adData?.actionUrl {
            adActionHandler!(actionUrl)
        }
        closeAction()
    }
    
    static let shared: AdPopup = {
        var instance = AdPopup()
        instance = Bundle.main.loadNibNamed("AdPopup", owner: instance, options: nil)?.first as! AdPopup
        instance.alpha = 0.0
        return instance
    }()
    
    func show(onView: UIView, with adData: AdData) {
        
        self.adData = adData
        guard let imageUrl = adData.imageUrl,
            let _ = adData.actionUrl else { return }
        
        adImageView.imageFrom(url: imageUrl)
        
        onView.addSubview(self)
        self.frame = CGRect(x: 0, y: 0, width: onView.bounds.size.width, height: onView.bounds.size.height)
        
        
        if newShown == true {
            newShown = false
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
        }
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.alpha = 1.0
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, animations: { [unowned self] in
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0.0
        }) { [unowned self] (finished) in
            if finished {
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.newShown = true
                    self.removeFromSuperview()
            }
        }
    }
}
