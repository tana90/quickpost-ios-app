//
//  EventManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

final class EventManager {
    
    let eventsUrl = URL(string: "https://www.aww-coding.com/intuition/v/1.0/api.php")!
    let payload = """
    {
    "version": "1.0",
    "method": "addEvent",
    "content": {
        "token": "%@",
        "eventName": "%@",
        "eventType": "%@",
        "appName": "%@",
        "appVersion": "%@",
        "region": "%@"
        }
    }
    """
    
    static let shared: EventManager = {
        let instance = EventManager()
        return instance
    }()
    
    func sendEvent(name: String!, type: String!) {
        
        if !DisableEvents {
            guard let token = AppManager.loadToken()else { return }
            let appName = "igQuickPost"
            let appVersion = "1.0"
            
            let status = PROVersion ? "PRO" : "FREE"
            let region = String(format: "%@-%@-%@-%@", "QP", Locale.current.regionCode ?? "x", Locale.current.languageCode ?? "x", status)
            
            let payload = String(format: self.payload, token, name, type, appName, appVersion, region)
            let json = encode(text: payload).data(using: .utf8)
            var request = URLRequest(url: APIUrl)
            request.httpBody = json
            request.timeoutInterval = 30
            request.httpMethod = "POST"
            
            URLSession.shared.dataTask(with: request) { (_, _, _) in
                }.resume()
        }
    }
}
