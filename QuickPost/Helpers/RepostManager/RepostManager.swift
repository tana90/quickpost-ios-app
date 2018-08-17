//
//  RepostManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/26/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import UIKit
import SwiftLinkPreview
import UserNotifications

var phoneLocked: Bool {
    get {
        return UserDefaults.standard.bool(forKey: "PHONE_LOCKED")
    }
    
    set {
        UserDefaults.standard.set(newValue, forKey: "PHONE_LOCKED")
    }
}

class RepostManager: NSObject {
    
    //var timer: Timer?
    //var oldClipboard = ""
    //var oldChangeCount = UIPasteboard.general.changeCount
    
    static let shared: RepostManager = {
        let instance = RepostManager()
//        instance.oldChangeCount = UIPasteboard.general.changeCount
//        instance.timer = Timer.scheduledTimer(timeInterval: 2, target: instance, selector: #selector(timerLoop), userInfo: nil, repeats: true)
//        instance.timer?.fire()
        return instance
    }()
    
    
//    @objc func timerLoop() {
//
//
//            if UIPasteboard.general.changeCount != oldChangeCount {
//                po("++++++++++++")
//                repostNotification()
//                oldChangeCount = UIPasteboard.general.changeCount
//            } else {
//                po("------------")
//            }
//
//    }
    
    
    @objc func checkClipboard() {
        
        po(UIPasteboard.general.string)
        guard let pasteboard = UIPasteboard.general.string else {
            return
        }
        po(pasteboard)
        loadPostFrom(url: pasteboard)
    }
    
    
    
    func loadPostFrom(url: String!) {
        
        guard let urlT = URL(string: url) else { return }
        
        var request = URLRequest(url: urlT)
        request.timeoutInterval = 30
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
            
            guard let dataT = data else { return }
            
            guard let responseString = String(data: dataT, encoding: .utf8) else { return }
            po(responseString)
            
            //Video
            if (responseString.contains("<script type=\"text/javascript\">window._sharedData =")),
                (responseString.contains("<meta property=\"og:video\"")) {
                
                
                let metaComponents = responseString.components(separatedBy: "<meta property=")
                let metaIndexContaining = metaComponents.index(where: { (str) -> Bool in
                    if (str.contains("\"og:video\"")) {
                        return true
                    }
                    return false
                })
                var metaJsonString = metaComponents[metaIndexContaining!]
                metaJsonString = metaJsonString.replacingOccurrences(of: "\"og:video\" content=\"", with: "")
                metaJsonString = metaJsonString.replacingOccurrences(of: "\" />", with: "")
                metaJsonString = metaJsonString.replacingOccurrences(of: "\"/>", with: "")
                
                metaJsonString = metaJsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                while metaJsonString.contains(" ") {
                    metaJsonString = metaJsonString.replacingOccurrences(of: " ", with: "")
                }
                
                let imageUrl = metaJsonString
                
                var thumbnailUrl = ""
                //Get thumbnail pic
                if (responseString.contains("<script type=\"text/javascript\">window._sharedData =")),
                    (responseString.contains("<meta property=\"og:image\"")) {
                    
                    
                    let metaComponents = responseString.components(separatedBy: "<meta property=")
                    let metaIndexContaining = metaComponents.index(where: { (str) -> Bool in
                        if (str.contains("\"og:image\"")) {
                            return true
                        }
                        return false
                    })
                    var metaJsonString = metaComponents[metaIndexContaining!]
                    metaJsonString = metaJsonString.replacingOccurrences(of: "\"og:image\" content=\"", with: "")
                    metaJsonString = metaJsonString.replacingOccurrences(of: "\" />", with: "")
                    metaJsonString = metaJsonString.replacingOccurrences(of: "\"/>", with: "")
                    
                    metaJsonString = metaJsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                    while metaJsonString.contains(" ") {
                        metaJsonString = metaJsonString.replacingOccurrences(of: " ", with: "")
                    }
                    
                    thumbnailUrl = metaJsonString
                }
                
                
                let components = responseString.components(separatedBy: "<script type=")
                let indexContaining = components.index(where: { (str) -> Bool in
                    if (str.contains("window._sharedData")) {
                        return true
                    }
                    return false
                })
                var jsonString = components[indexContaining!]
                jsonString = jsonString.replacingOccurrences(of: "\"text/javascript\">window._sharedData = ", with: "")
                jsonString = jsonString.replacingOccurrences(of: ";</script>", with: "")
                
                let json = JSON.init(parseJSON: jsonString)
                
                guard let entryData = json["entry_data"].dictionary,
                    let postPage = entryData["PostPage"]?.array,
                    let post1 = postPage[0] as? JSON,
                    let graphql = post1["graphql"].dictionary,
                    let shortcode_media = graphql["shortcode_media"]?.dictionary,
                    let owner = shortcode_media["owner"]?.dictionary,
                    let profilePic = owner["profile_pic_url"]?.string,
                    let username = owner["username"]?.string else { return }
                
                po(imageUrl)
                
                guard let media_caption = shortcode_media["edge_media_to_caption"]?.dictionary,
                    let edges = media_caption["edges"]?.array,
                    let edge1 = edges.first,
                    let node = edge1["node"].dictionary,
                    let caption = node["text"]?.string else {
                        
                        
                        EventHandler.shared.repostAvailable()
                        
                        var repostData = RepostData()
                        repostData.url = url
                        repostData.username = username
                        repostData.profileUrl = profilePic
                        repostData.caption = ""
                        repostData.imageUrl = imageUrl
                        repostData.thumbnailUrl = thumbnailUrl
                        self.save(repost: repostData)
                        return
                }
                
                var repostData = RepostData()
                repostData.url = url
                repostData.profileUrl = profilePic
                repostData.username = username
                repostData.caption = caption
                repostData.imageUrl = imageUrl
                repostData.thumbnailUrl = thumbnailUrl
                self.save(repost: repostData)
                
                
                
            } else
                //Image
                if (responseString.contains("<script type=\"text/javascript\">window._sharedData =")),
                (responseString.contains("<meta property=\"og:image\"")) {
                
                
                let metaComponents = responseString.components(separatedBy: "<meta property=")
                let metaIndexContaining = metaComponents.index(where: { (str) -> Bool in
                    if (str.contains("\"og:image\"")) {
                        return true
                    }
                    return false
                })
                var metaJsonString = metaComponents[metaIndexContaining!]
                metaJsonString = metaJsonString.replacingOccurrences(of: "\"og:image\" content=\"", with: "")
                metaJsonString = metaJsonString.replacingOccurrences(of: "\" />", with: "")
                metaJsonString = metaJsonString.replacingOccurrences(of: "\"/>", with: "")
                
                metaJsonString = metaJsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                while metaJsonString.contains(" ") {
                    metaJsonString = metaJsonString.replacingOccurrences(of: " ", with: "")
                }
                
                let imageUrl = metaJsonString
                
                
                let components = responseString.components(separatedBy: "<script type=")
                let indexContaining = components.index(where: { (str) -> Bool in
                    if (str.contains("window._sharedData")) {
                        return true
                    }
                    return false
                })
                var jsonString = components[indexContaining!]
                jsonString = jsonString.replacingOccurrences(of: "\"text/javascript\">window._sharedData = ", with: "")
                jsonString = jsonString.replacingOccurrences(of: ";</script>", with: "")
                
                let json = JSON.init(parseJSON: jsonString)
                
                guard let entryData = json["entry_data"].dictionary,
                    let postPage = entryData["PostPage"]?.array,
                    let post1 = postPage[0] as? JSON,
                    let graphql = post1["graphql"].dictionary,
                    let shortcode_media = graphql["shortcode_media"]?.dictionary,
                    let owner = shortcode_media["owner"]?.dictionary,
                    let profilePic = owner["profile_pic_url"]?.string,
                    let username = owner["username"]?.string else { return }
                
                po(imageUrl)
                
                guard let media_caption = shortcode_media["edge_media_to_caption"]?.dictionary,
                    let edges = media_caption["edges"]?.array,
                    let edge1 = edges.first,
                    let node = edge1["node"].dictionary,
                    let caption = node["text"]?.string else {
                        
                        
                        EventHandler.shared.repostAvailable()
                        
                        var repostData = RepostData()
                        repostData.url = url
                        repostData.username = username
                        repostData.profileUrl = profilePic
                        repostData.caption = ""
                        repostData.imageUrl = imageUrl
                        self.save(repost: repostData)
                        return
                }
                
                
                var repostData = RepostData()
                repostData.url = url
                repostData.profileUrl = profilePic
                repostData.username = username
                repostData.caption = caption
                repostData.imageUrl = imageUrl
                self.save(repost: repostData)
            }
            
            
            }.resume()
    }
    
    func save(repost data: RepostData) {
        Repost.add(repostData: data) { (exists) in
            if !exists {
                EventHandler.shared.repostAvailable()
            }
        }
        CoreDataManager.shared.saveContext()
        //Clear clipboard
        UIPasteboard.general.string = ""
    }
    
    func repostNotification() {
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        var timeInterval = 0.05
        if !phoneLocked {
            content.title = "🌅 Repost available"
            content.subtitle = "Tap here to repost Instagram photo"
            content.sound = nil
            timeInterval = 0.05
        } else {
            content.title = "🌅 Repost available"
            content.subtitle = "Don't forget to repost photos."
            content.sound = UNNotificationSound.default()
            timeInterval = 20
        }
        content.categoryIdentifier = "RepostNotification"
        
        content.badge = 1
        content.userInfo = ["type": "repost"]
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
}
