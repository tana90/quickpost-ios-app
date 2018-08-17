//
//  PhotoPoster.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/4/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import Photos

class PhotoPoster {
    
    static func requestSavePhotoPermission() {
        PHPhotoLibrary.shared().performChanges({
        }, completionHandler: { success, error in
        })
    }
    
    static func postPhotoToInstagram(image: UIImage, caption: String, callBackViewController: UIViewController?, completion: @escaping () -> ()) {
        
        requestSavePhotoPermission()
        savePhoto(image: image) {
            
            let lastPHAsset = self.fetchLatestPhotos(forCount: 1)
            guard let asset = lastPHAsset.firstObject else { return }
            
            var id = asset.localIdentifier
            if id.contains("/") {
                if let first = id.components(separatedBy: "/").first {
                    id = first
                }
            }
            let assetLibrary = String(format: "assets-library://asset/asset.JPG?id=%@&ext=JPG", id)
            let instaUrl = String(format: "instagram://library?AssetPath=%@", assetLibrary.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
            UIPasteboard.general.string = caption
            if let url = URL(string: instaUrl) {
                
                //Send history
                guard let caption = UIPasteboard.general.string else { return }
                Connector.setUserHistory(caption: caption)
                
                DispatchQueue.main.safeAsync {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            let alertViewController = UIAlertController(title: "Instagram app not found", message: "Looks like you don't have Instagram app installed", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                            }
                            
                            alertViewController.addAction(okAction)
                            if let vc = callBackViewController {
                                vc.present(alertViewController, animated: true, completion: nil)
                            }
                        } else {
                            completion()
                        }
                    })
                }
            }
            
        }
    }
    
    
    
    
    
    
    
    
    static func postVideoToInstagram(url: URL, caption: String, callBackViewController: UIViewController?, completion: @escaping () -> ()) {
        
        requestSavePhotoPermission()
        
        saveVideo(url: url) {
            
            let lastPHAsset = self.fetchLatestVideo(forCount: 1)
            guard let asset = lastPHAsset.firstObject else { return }
            
            var id = asset.localIdentifier
            if id.contains("/") {
                if let first = id.components(separatedBy: "/").first {
                    id = first
                }
            }
            let assetLibrary = String(format: "assets-library://asset/asset?id=%@", id)
            let instaUrl = String(format: "instagram://library?AssetPath=%@", assetLibrary.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
            po(instaUrl)
            UIPasteboard.general.string = caption
            if let url = URL(string: instaUrl) {
                
                //Send history
                guard let caption = UIPasteboard.general.string else { return }
                Connector.setUserHistory(caption: caption)
                
                DispatchQueue.main.safeAsync {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            let alertViewController = UIAlertController(title: "Instagram app not found", message: "Looks like you don't have Instagram app installed", preferredStyle: .alert)
                            alertViewController.view.tintColor = UIColor(red: 1, green: 8/255, blue: 84/255, alpha: 1)
                            let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                            }
                            
                            alertViewController.addAction(okAction)
                            if let vc = callBackViewController {
                                vc.present(alertViewController, animated: true, completion: nil)
                            }
                        } else {
                            completion()
                        }
                    })
                }
            }
            
        }
    }
    
    
    
    
    
    
    
    
    static func fetchLatestPhotos(forCount count: Int?) -> PHFetchResult<PHAsset> {
        
        // Create fetch options.
        let options = PHFetchOptions()
        
        // If count limit is specified.
        if let count = count { options.fetchLimit = count }
        
        // Add sortDescriptor so the lastest photos will be returned.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        options.sortDescriptors = [sortDescriptor]
        
        // Fetch the photos.
        return PHAsset.fetchAssets(with: .image, options: options)
    }
    
    static func fetchLatestVideo(forCount count: Int?) -> PHFetchResult<PHAsset> {
        
        // Create fetch options.
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
    
    
        // If count limit is specified.
        if let count = count { options.fetchLimit = count }
        
        // Add sortDescriptor so the lastest photos will be returned.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        options.sortDescriptors = [sortDescriptor]
        
        // Fetch the photos.
        return PHAsset.fetchAssets(with: .video, options: options)
    }
    
    static func savePhoto(image: UIImage, completion: @escaping () -> () ) {
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                
                completion()
                
            }
            else if let _ = error {
            }
            else {
                
            }
        })
    }
    
    static func saveVideo(url: URL, completion: @escaping () -> () ) {
        
        
        DispatchQueue.global(qos: .utility).async {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let _ = data else { return }
                
                
                let md5Filename = String(format: "%ld", url.absoluteString.hashValue)
                let fileName = String(format: "%@-video.mp4", md5Filename)
                var fileURL: URL? = nil
                do {
                    fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
                } catch {
                    po(error)
                }
                
                guard let _ = fileURL else { return }
                do {
                    try data!.write(to: fileURL!, options: .atomicWrite)
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL!)
                    }, completionHandler: { success, error in
                        if success {
                            
                            completion()
                            
                        }
                        else if let _ = error {
                        }
                        else {
                            
                        }
                    })
                    
                } catch {
                    po(error)
                }
                
                }.resume()
        }
        
        
    }
    
    
    
    
    
    
    static func fileExistsAt(filename: String) -> Bool {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent(filename)?.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath!) {
            return true
        } else {
            return false
        }
    }
}
