//
//  PhotoManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import Photos
import UserNotifications


final class PhotoManager: NSObject {
    
   /* static let shared: PhotoManager = {
        let instance = PhotoManager()
        if allowRunInBackground {
            instance.start()
        } else {
            instance.stop()
        }
        
        EventHandler.shared.allowBackgroundChange {
            po(allowRunInBackground)
            
            if allowRunInBackground {
                instance.start()
            } else {
                instance.stop()
            }
        }
        return instance
    }()
    
    var allPhotos: PHFetchResult<PHAsset>?
    var lastTakenPhoto = 0
    
    
    
    func start() {
        
        PHPhotoLibrary.requestAuthorization { (status) in
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            self.allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    func stop() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let _ = allPhotos else { return }
        if let changeDetails = changeInstance.changeDetails(for: allPhotos!) {
            // Update the cached fetch result.
            
            allPhotos = changeDetails.fetchResultAfterChanges
            let insertedObjects = changeDetails.insertedObjects
            po(Date.timestamp())
            po(lastTakenPhoto)
            po("Date.timestamp() - lastTakenPhoto = \(Date.timestamp() - lastTakenPhoto)")
            if Date.timestamp() - lastTakenPhoto > 10 {
                
                lastTakenPhoto = Date.timestamp()
                PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                    guard let _ = self else { return }
                    
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    options.deliveryMode = .fastFormat
                    options.resizeMode = .exact
                    
                    insertedObjects.forEach({ (asset) in
                        
                        PHImageManager.default().requestImage(for: asset,
                                                              targetSize: CGSize(width: 256, height: 256),
                                                              contentMode: .aspectFit,
                                                              options: options) { (image, info) in
                                                                guard let _ = image else {
                                                                    return
                                                                }
                                                                
                                                                let center = UNUserNotificationCenter.current()
                                                                let content = UNMutableNotificationContent()
                                                                content.title = "🌅 New photo"
                                                                content.subtitle = "Tap to post it on Instagram"
                                                                content.categoryIdentifier = "PostPhoto"
                                                                content.sound = nil
                                                                
                                                                
                                                                if let attachment = UNNotificationAttachment.create(identifier: "PhotoIdentifierAtachament", image: image!, options: nil) {
                                                                    content.attachments = [attachment]
                                                                }
                                                                
                                                                let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
                                                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                                                                center.add(request)
                                                                
                                                                
                        }
                        
                    })
                }
                
                
                //                let options = PHImageRequestOptions()
                //                options.isSynchronous = true
                //                options.deliveryMode = .fastFormat
                //                options.resizeMode = .exact
                //
                //                DispatchQueue.background(delay: 0.0, background: { [weak self] in
                //
                //                    let fetchOptions = PHFetchOptions()
                //                    fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
                //
                //                    let allAssets = //PHAsset.fetchAssets(with: .image, options: fetchOptions)
                //
                //                    allAssets.enumerateObjects() { (asset, count, stop) in
                //
                //                        PHImageManager.default().requestImage(for: asset,
                //                                                              targetSize: CGSize(width: 256, height: 256),
                //                                                              contentMode: .aspectFit,
                //                                                              options: options) { [weak self] (image, info) in
                //                                                                guard let strongSelf = self,
                //                                                                    let _ = image else {
                //                                                                        return
                //                                                                }
                //
                //                                                                let center = UNUserNotificationCenter.current()
                //                                                                let content = UNMutableNotificationContent()
                //                                                                content.title = "🌅 New photo"
                //                                                                content.subtitle = "Tap to post it on Instagram"
                //                                                                content.categoryIdentifier = "PostPhoto"
                //                                                                content.sound = UNNotificationSound.default()
                //
                //
                //                                                                if let attachment = UNNotificationAttachment.create(identifier: "PhotoIdentifierAtachament", image: image!, options: nil) {
                //                                                                    content.attachments = [attachment]
                //                                                                }
                //
                //                                                                let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
                //                                                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                //                                                                center.add(request)
                //
                //
                //                        }
                //                    }
                //                    }, completion: {
                //                })
                
                
            }
        }
    }*/
}
