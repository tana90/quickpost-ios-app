//
//  SEOManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/2/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

final class SEOManager {
    
    static let shared: SEOManager = {
        let instance = SEOManager()
        return instance
    }()
    
    func start() {
        po("SEO")
        if !DisableSEO {
            
            po("Start SEO")
            
            //https://itunes.apple.com/US/lookup?id=1257643323
            
            let itunesUrl = URL(string: "https://itunes.apple.com/us/app/quickpost-for-ig/id1396592906?ls=1&mt=8")!
            var request = URLRequest(url: itunesUrl)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
                }.resume()
            
            
            
            
            
            let itunes2Url = URL(string: "https://itunes.apple.com/lookup?id=1396592906")!
            request = URLRequest(url: itunes2Url)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
                }.resume()
            
            
            
            
            
            let googleUrl = URL(string: "https://www.google.com/search?q=aww-coding.com")!
            request = URLRequest(url: googleUrl)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
                }.resume()
            
            
            
            
            let google2Url = URL(string: "https://www.google.com/search?q=quickpost")!
            request = URLRequest(url: google2Url)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
                }.resume()
            
            let google3Url = URL(string: "https://www.google.com/search?q=quickpostig%20instagram")!
            request = URLRequest(url: google3Url)
            request.timeoutInterval = 30
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
                }.resume()
        }
        
    }
}
