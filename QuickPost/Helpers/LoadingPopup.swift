//
//  LoadingPopup.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class LoadingPopup: UIView {

    @IBOutlet weak var loadingView: UIView!
    var newShown = true
    
    static let shared: LoadingPopup = {
        var instance = LoadingPopup()
        instance = Bundle.main.loadNibNamed("LoadingPopup", owner: instance, options: nil)?.first as! LoadingPopup
        instance.alpha = 0.0
        return instance
    }()
    
    func show(onView: UIView) {
        onView.addSubview(self)
        self.frame = CGRect(x: 0, y: 0, width: onView.bounds.size.width, height: onView.bounds.size.height)
        
        
        if newShown == true {
            newShown = false
            self.loadingView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
        }
        UIView.animate(withDuration: 0.4) { [unowned self] in
            self.loadingView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.alpha = 1.0
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.4, animations: { [unowned self] in
            self.loadingView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.alpha = 0.0
        }) { [unowned self] (finished) in
                if finished {
                    self.loadingView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.newShown = true
                    self.removeFromSuperview()
                }
        }
    }
}

