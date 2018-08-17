//
//  AppManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/25/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

let SettingsURL = URL(string: "https://www.aww-coding.com/intuition/settings.php")!
var DisableAds: Bool {
    get { return UserDefaults.standard.bool(forKey: "DISABLEADS") }
    set { UserDefaults.standard.set(newValue, forKey: "DISABLEADS") }
}

var DisableEvents: Bool {
    get { return UserDefaults.standard.bool(forKey: "DISABLEEVENTS") }
    set { UserDefaults.standard.set(newValue, forKey: "DISABLEEVENTS") }
}

var DisableSEO: Bool {
    get { return UserDefaults.standard.bool(forKey: "DISABLESEO") }
    set { UserDefaults.standard.set(newValue, forKey: "DISABLESEO") }
}


var TermsAndConditionsURL: String {
    get { return UserDefaults.standard.string(forKey: "TCURL") ?? "https://www.aww-coding.com/intuition/v/1.0/terms.html" }
    set { UserDefaults.standard.set(newValue, forKey: "TCURL") }
}

var HelpURL: String {
    get { return UserDefaults.standard.string(forKey: "HELPURL") ?? "https://www.aww-coding.com/intuition/v/1.0/help.html" }
    set { UserDefaults.standard.set(newValue, forKey: "HELPURL") }
}

var MaxFavorite: Int {
    get { return UserDefaults.standard.integer(forKey: "MAXFAVORITE") }
    set { UserDefaults.standard.set(newValue, forKey: "MAXFAVORITE") }
}

var MaxPhotos: Int {
    get { return UserDefaults.standard.integer(forKey: "MAXPHOTOS") }
    set { UserDefaults.standard.set(newValue, forKey: "MAXPHOTOS") }
}

var MaxReposts: Int {
    get { return UserDefaults.standard.integer(forKey: "MAXREPOSTS") }
    set { UserDefaults.standard.set(newValue, forKey: "MAXREPOSTS") }
}

var AdFrequency: Int {
    get { return UserDefaults.standard.integer(forKey: "ADFREQUENCY") }
    set { UserDefaults.standard.set(newValue, forKey: "ADFREQUENCY") }
}

var ShowHashtagsTip: Bool {
    get { return UserDefaults.standard.bool(forKey: "SHOWHASHTAGTIP") }
    set { UserDefaults.standard.set(newValue, forKey: "SHOWHASHTAGTIP") }
}

var ShowRateTip: Bool {
    get { return UserDefaults.standard.bool(forKey: "SHOWRATETIP") }
    set { UserDefaults.standard.set(newValue, forKey: "SHOWRATETIP") }
}

var RateAppOffer: Int {
    get { return UserDefaults.standard.integer(forKey: "RATEAPPOFFER") }
    set { UserDefaults.standard.set(newValue, forKey: "RATEAPPOFFER") }
}

var LastTrendsCheckTimestamp: Int {
    get { return UserDefaults.standard.integer(forKey: "LASTTRENDSCHECKTIMESTAMP") }
    set { UserDefaults.standard.set(newValue, forKey: "LASTTRENDSCHECKTIMESTAMP") }
}


class AppManager {
    
    static let shared: AppManager = {
        let instance = AppManager()
        return instance
    }()
    
    
    func loadSettings(finished: @escaping (Bool)->()) {
        var request = URLRequest(url: SettingsURL)
        request.timeoutInterval = 30
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let httpBody = request.httpBody {
            request.addValue(String(format: "%ld", httpBody.count), forHTTPHeaderField: "Content-Length")
        }
        
        URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
            
            do {
                guard error == nil,
                    let _ = data else {
                        finished(false)
                        return
                }
                
                let json = try JSON(data: data!)
                
                if let settings = json["settings"].dictionary {
                    
                    if let adsStr = settings["disable_ads"]?.string,
                        let ads = Int(adsStr) {
                        DisableAds = ads == 0 ? false : true
                    }
                    if let eventsStr = settings["disable_events"]?.string,
                        let events = Int(eventsStr) {
                        DisableEvents = events == 0 ? false : true
                    }
                    
                    if let seoStr = settings["disable_seo"]?.string,
                        let seo = Int(seoStr) {
                        DisableSEO = seo == 0 ? false : true
                    }

                    if let tcurl = settings["tc_url"]?.string {
                        TermsAndConditionsURL = tcurl
                    }
                    if let helpurl = settings["help_url"]?.string {
                        HelpURL = helpurl
                    }
                    if let maxPhotosStr = settings["max_photos"]?.string,
                        let maxPhotos = Int(maxPhotosStr) {
                        MaxPhotos = maxPhotos
                    }  else {
                        MaxPhotos = 5
                    }
                    if let maxFavoriteStr = settings["max_favorite"]?.string,
                        let maxFavorite = Int(maxFavoriteStr) {
                        MaxFavorite = maxFavorite
                    } else {
                        MaxFavorite = 5
                    }
                    if let maxRepostsStr = settings["max_reposts"]?.string,
                        let maxReposts = Int(maxRepostsStr) {
                        MaxReposts = maxReposts
                    } else {
                        MaxReposts = 5
                    }
                    if let adFrequencyStr = settings["ad_frequency"]?.string,
                        let adFrequency = Int(adFrequencyStr) {
                        AdFrequency = adFrequency
                    }
                }
                
                po(MaxPhotos)
                po(MaxFavorite)
                po(DisableAds)
                po(DisableSEO)
                po(DisableEvents)
                po(AdFrequency)
                po("----")
                po(MaxReposts)
                
                finished(true)
            } catch {
                po(error)
                finished(false)
            }
            
            }.resume()
    }
}

extension AppManager {
    
    //Token
    static func initApp() -> String! {
        if let token = loadToken(),
            token.count > 0 {
            //Do nothing.. we already have token
        } else {
            save(token: UUID().uuidString)
        }
        
        return loadToken() ?? "unknowtoken"
    }
    
    static func save(token: String!) {
        KeyChain.save(token.data(using: .utf8)!, forkey: "TOKEN")
    }
    
    static func loadToken() -> String? {
        return KeyChain.load(string: "TOKEN")
    }
    
    
    
    //Number of scans
    static func save(numberOfScans: String!) {
        KeyChain.save(numberOfScans.data(using: .utf8)!, forkey: "NUM_OF_SCANS")
    }
    
    static func loadNumberOfScans() -> String {
        return KeyChain.load(string: "NUM_OF_SCANS") ?? "0"
    }
    
    static func removeNumberOfScans() {
        KeyChain.remove("NUM_OF_SCANS")
        save(numberOfScans: "0")
    }
    
    static func incrementNumberOfScans() {
        let numOfScans = AppManager.loadNumberOfScans()
        let int =  (Int(numOfScans) ?? 0) + 1
        save(numberOfScans: String(format: "%ld", int))
    }
    
    
    
    //Number of reposts
    static func save(numberOfReposts: String!) {
        KeyChain.save(numberOfReposts.data(using: .utf8)!, forkey: "NUM_OF_REPOSTS")
    }
    
    static func loadNumberOfReposts() -> String {
        return KeyChain.load(string: "NUM_OF_REPOSTS") ?? "0"
    }
    
    static func removeNumberOfReposts() {
        KeyChain.remove("NUM_OF_REPOSTS")
        save(numberOfReposts: "0")
    }
    
    static func incrementNumberOfReposts() {
        let numOfReposts = AppManager.loadNumberOfReposts()
        let int =  (Int(numOfReposts) ?? 0) + 1
        save(numberOfReposts: String(format: "%ld", int))
    }
}
