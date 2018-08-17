//
//  BannerPreview.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/28/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit

final class BannerPreview: UIView {
    
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerTextLabel: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    
    var timer: Timer?
    var newShown = true
    
    static let shared: BannerPreview = {
        var instance = BannerPreview()
        instance = Bundle.main.loadNibNamed("BannerPreview", owner: instance, options: nil)?.first as! BannerPreview
        instance.alpha = 0.0
        return instance
    }()
    
    func show(onView: UIView, with text: String) {
        if text.count > Int(0) {
            timer?.invalidate()
            onView.addSubview(self)
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { [weak self] (timer) in
                guard let _ = self else { return }
                self!.hide()
            })
            
            self.frame = CGRect(x: 0, y: 0, width: onView.bounds.size.width, height: onView.bounds.size.height)
            bannerTextLabel.text = text
            let hashes = text.components(separatedBy: "  ")
            counterLabel.text = String(format: "%ld/30", hashes.count - 1)
            if newShown == true {
                newShown = false
                self.bannerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                
            }
            UIView.animate(withDuration: 0.3) { [unowned self] in
                self.alpha = 1.0
                self.bannerView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        } else {
            hide()
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: { [unowned self] in
            self.alpha = 0.0
            self.bannerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [unowned self] (finished) in
                if finished {
                    self.bannerView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.newShown = true
                    self.removeFromSuperview()
                }
        }
    }
}


