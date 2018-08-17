//
//  RepostPreviewViewController.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/27/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import Photos
import StoreKit

final class RepostPreviewViewController: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var mediaView: MediaView!
    @IBOutlet weak var videoInfoView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    
    var selectedRepost: Repost?
    var isVideo: Bool = false
    
    @IBAction func closeAction() {
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func postAction() {
        
        if MaxReposts + RateAppOffer > Int(AppManager.loadNumberOfReposts()) ?? 0 || PROVersion {
            
            
            if isVideo {
                //Post video
                guard let videoUrl = self.selectedRepost?.imageUrl, let url = URL(string: videoUrl) else {
                    return
                }
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    PhotoPoster.postVideoToInstagram(url: url, caption: self!.captionLabel.text ?? "", callBackViewController: self!) {
                        AppManager.incrementNumberOfReposts()
                        EventManager.shared.sendEvent(name: "repost_repost", type: "action")
                    }
                }
            } else {
                guard let image = self.mediaView.image else {
                    return
                }
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    PhotoPoster.postPhotoToInstagram(image: image, caption: self!.captionLabel.text ?? "", callBackViewController: self!, completion: {
                        AppManager.incrementNumberOfReposts()
                        EventManager.shared.sendEvent(name: "repost_repost", type: "action")
                    })
                    
                    //Send history
                    guard let caption = self!.captionLabel.text else { return }
                    Connector.setUserHistory(caption: caption)
                }
            }
            
            
            
        } else {
            var style: UIAlertControllerStyle = .actionSheet
            if UI_USER_INTERFACE_IDIOM() == .pad {
                style = .alert
            }
            EventManager.shared.sendEvent(name: "repost_limit_reached", type: "state")
            let alertViewController = UIAlertController(title: "Reposts limit reached", message: "You have reach the limit of \(MaxReposts + RateAppOffer) free reposts. To continue repost upgrade to PRO.", preferredStyle: style)
            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
            let upgradeAction = UIAlertAction(title: "Upgrade to PRO", style: .default) { [weak self] (alert) in
                guard let _ = self else { return }
                self!.performSegue(withIdentifier: "showStoreSegue", sender: self!)
            }
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (alert) in
                
                self.showRateTip()
            }
            
            alertViewController.addAction(upgradeAction)
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveAction() {
        
        
        
        if isVideo {
            guard let videoUrl = self.selectedRepost?.imageUrl, let url = URL(string: videoUrl) else {
                return
            }
            
            //Save video
            PhotoPoster.saveVideo(url: url) {
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    EventManager.shared.sendEvent(name: "repost_save_video", type: "action")
                    let alertViewController = UIAlertController(title: "🎉", message: "Video saved to Camera Roll", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "Close", style: .cancel) { (alert) in
                    }
                    
                    alertViewController.addAction(okAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            }
        } else {
            
            guard let image = self.mediaView.image else {
                return
            }
            
            PhotoPoster.savePhoto(image: image, completion: {
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    EventManager.shared.sendEvent(name: "repost_save_photo", type: "action")
                    let alertViewController = UIAlertController(title: "🎉", message: "Photo saved to Camera Roll", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "Close", style: .cancel) { (alert) in
                    }
                    
                    alertViewController.addAction(okAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        guard let _ = selectedRepost else { return }
        EventManager.shared.sendEvent(name: "open_repost_preview", type: "app")
        usernameLabel.text = selectedRepost!.username
        captionLabel.text = selectedRepost!.caption
        captionLabel.colorHashtag(with: UIColor(red: 0, green: 53/255, blue: 105/255, alpha: 1))
        PhotoPoster.requestSavePhotoPermission()
        
        
        guard let mediaUrl = URL(string: selectedRepost!.imageUrl!) else { return }
        mediaView.allowSound = true
        mediaView.allowAutoplay = true
        mediaView.show(mediaUrl: mediaUrl, thumbnailUrl: URL(string: selectedRepost!.thumbnailUrl ?? ""))
        
        if mediaUrl.absoluteString.lowercased().contains("jpg") || mediaUrl.absoluteString.lowercased().contains("png") {
            videoInfoView?.isHidden = true
        } else {
            videoInfoView?.isHidden = false
        }
        
        guard let profileUrl = URL(string: selectedRepost!.profileUrl!) else { return }
        profileImageView.kf.setImage(with: profileUrl)
        
        
        if (selectedRepost?.imageUrl ?? "").contains("mp4") {
            isVideo = true
        }
        
    }
}


extension RepostPreviewViewController {
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
}


extension RepostPreviewViewController {
    
    func showRateTip() {
        
        if !PROVersion {
            
            if ShowRateTip == false {
                ShowRateTip = true
                
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    let alertViewController = UIAlertController(title: "QuickPost", message: "Rate our app and get 5 free more reposts.", preferredStyle: .alert)
                    alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                    let okAction = UIAlertAction(title: "Rate app", style: .cancel) { (alert) in
                        SKStoreReviewController.requestReview()
                        
                        if RateAppOffer == 0 {
                            let alertViewController = UIAlertController(title: "🎉", message: "Now you have 5 free more reposts", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) {(alert) in
                            }
                            alertViewController.addAction(okAction)
                            self!.present(alertViewController, animated: true, completion: nil)
                            
                            EventManager.shared.sendEvent(name: "rate_app", type: "action")
                        }
                        
                        RateAppOffer = 5
                    }
                    let cancelAction = UIAlertAction(title: "Later", style: .default) { (alert) in
                    }
                    
                    alertViewController.addAction(okAction)
                    alertViewController.addAction(cancelAction)
                    self!.present(alertViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
