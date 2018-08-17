//
//  Connector.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/24/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

let SearchHashtagURL = "http://hashmeapi-stage.us-west-2.elasticbeanstalk.com/search?q=%@"
let APIUrl = URL(string: "https://www.aww-coding.com/intuition/v/2.0/api.php")!
let TrendsUrl = URL(string: "https://www.aww-coding.com/intuition/v/2.0/trends.php")!

enum Payload: String {
    
    case registerUser = """
    {
    "version": "1.0",
    "method": "registerUser",
    "content": {
    "token": "%@"
    }
    }
    """
    
    case registerDevice = """
    {
    "version": "1.0",
    "method": "registerDevice",
    "content": {
    "token": "%@",
    "deviceId": "%@"
    }
    }
    """
    
    case getUserTags = """
    {
    "version": "1.0",
    "method": "getUserTags",
    "content": {
    "token": "%@"
    }
    }
    """
    
    case setUserTag = """
    {
    "version": "1.0",
    "method": "setUserTag",
    "content": {
    "token": "%@",
    "tag": "%@"
    }
    }
    """
    
    case removeUserTag = """
    {
    "version": "1.0",
    "method": "removeUserTag",
    "content": {
    "token": "%@",
    "tag": "%@"
    }
    }
    """
    
    case getUserHistory = """
    {
    "version": "1.0",
    "method": "getUserHistory",
    "content": {
    "token": "%@"
    }
    }
    """
    
    case setUserHistory = """
    {
    "version": "1.0",
    "method": "setUserHistory",
    "content": {
    "token": "%@",
    "caption": "%@",
    "date": "%@"
    }
    }
    """
    
    case getPopularHashtags = """
    {
    "version": "1.0",
    "method": "getPopular",
    "content": {
    }
    }
    """
    
    case setFeedback = """
    {
    "version": "1.0",
    "method": "setFeedback",
    "content": {
    "token": "%@",
    "text": "%@"
    }
    }
    """
}

final class Connector {
    
    static let shared: Connector = {
        let instance = Connector()
        return instance
    }()
    
    //Get hastags from HASH ME
    func getHashtagsFor(keyword: String,
                        completion: @escaping (JSON) -> Void) {
        
        let urlString = String(format: SearchHashtagURL, keyword)
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        Connector.begin(request) { (response) in
            completion(response!)
        }
    }
    
    //Register user
    func registerUser(with token: String!,
                      with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.registerUser.rawValue, token)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
        }
    }
    
    //Register device
    func registerDevice(with token: String!,
                        with deviceId: String!,
                        with response: @escaping (_ response: JSON?) -> Void) {
        let payload = String(format: Payload.registerDevice.rawValue, token, deviceId)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            po(json)
            response(json)
        }
    }
    
    
    
    //Get user tags
    func getFavoriteTags(with token: String!,
                         with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.getUserTags.rawValue, token)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
            guard let content = json?["content"].dictionary,
                let tags = content["tags"]?.array else { return }
            
            tags.forEach { (tagObj) in
                var tag = TagData()
                tag.favorite = true
                tag.selected = false
                tag.confirmed = true
                tag.tag = tagObj["tag"].string
                Tag.add(tagData: tag)
            }
            CoreDataManager.shared.saveContext()
        }
    }
    
    
    //Set user tag
    func setFavoriteTag(with token: String!,
                        and tag: String,
                        with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.setUserTag.rawValue, token, tag)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
            guard let content = json?["content"].dictionary,
                let tags = content["tags"]?.array else { return }
            
            tags.forEach { (tagObj) in
                var tag = TagData()
                tag.favorite = true
                tag.selected = false
                tag.confirmed = true
                tag.utility = false
                tag.tag = tagObj["tag"].string
                Tag.add(tagData: tag)
            }
            CoreDataManager.shared.saveContext()
        }
    }
    
    
    //Remove user tag
    func removeFavoriteTag(with token: String!,
                           and tag: String,
                           with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.removeUserTag.rawValue, token, tag)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
        }
    }
    
    
    
    //Get user history
    func getHistory(with token: String!,
                    with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.getUserHistory.rawValue, token)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
            guard let content = json?["content"].dictionary,
                let history = content["history"]?.array else { return }
            
            history.forEach { (historyObj) in
                var historyData = HistoryData()
                historyData.caption = (historyObj["caption"].string ?? "").removingPercentEncoding ?? ""
                historyData.postedDate = historyObj["postedDate"].string ?? "1990-09-26 03:00:00"
                History.add(historyData: historyData)
            }
            CoreDataManager.shared.saveContext()
        }
    }
    
    
    //Set user history
    func setHistory(with token: String!,
                    and caption: String,
                    and date: String,
                    with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.setUserHistory.rawValue, token, caption.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "", date)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        po(payload)
        Connector.begin(request) { (json) in
            guard let content = json?["content"].dictionary,
                let history = content["history"]?.array else { return }
            
            history.forEach { (historyObj) in
                var historyData = HistoryData()
                historyData.caption = (historyObj["caption"].string ?? "").removingPercentEncoding ?? ""
                historyData.postedDate = historyObj["postedDate"].string ?? "1990-09-26 03:00:00"
                History.add(historyData: historyData)
            }
            CoreDataManager.shared.saveContext()
        }
    }
    
    
    
    
    //Get popular hashtags
    func getPopular(with response: @escaping (_ response: JSON?) -> Void) {
        
        let payload = String(format: Payload.getPopularHashtags.rawValue)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        
        Connector.begin(request) { (json) in
            response(json)
            guard let content = json?["content"].dictionary,
                let sets = content["popular"]?.array else { return }
            
            sets.forEach { (set) in
                var popularData = PopularData()
                popularData.caption = set["caption"].string ?? ""
                popularData.category = set["category"].string ?? "All"
                popularData.position = Int(set["position"].string ?? "0") ?? 0
                Popular.add(popularData: popularData)
            }
            CoreDataManager.shared.saveContext()
        }
    }
    
    
    
    //Send feedback
    func sendFeedback(with token: String!,
                      and text: String,
                      with response: @escaping (_ response: JSON?) -> Void) {
        let payload = String(format: Payload.setFeedback.rawValue, token, text)
        let json = encode(text: payload).data(using: .utf8)
        var request = URLRequest(url: APIUrl)
        request.httpBody = json
        prepare(&request)
        Connector.begin(request) { (json) in
            response(json)
        }
    }
    
    
    //Get trends
    func getTrends(with response: @escaping (_ response: JSON?) -> Void) {
        var request = URLRequest(url: TrendsUrl)
        prepareGET(&request)
        Connector.begin(request) { (json) in
            response(json)
            guard let content = json?["content"].dictionary,
                let trends = content["trends"]?.array else { return }
            
            trends.enumerated().forEach { (index, trend) in
                var trendsData = TrendsData()
                trendsData.index = trend["index"].intValue
                trendsData.value = trend["value"].doubleValue
                trendsData.hour = trend["hour"].intValue
                Trends.add(trendsData: trendsData)
            }
            CoreDataManager.shared.saveContext()
        }
    }
}

extension Connector {
    
    static func begin(_ request: URLRequest,
                      with response: @escaping (_ response: JSON?) -> Void) {
        
        URLSession.shared.dataTask(with: request) { (data, httpResponse, error) in
            do {
                guard error == nil,
                    let _ = data else {
                        response(JSON())
                        return
                }
                
                let json = try JSON(data: data!)
                response(json)
            } catch {
                
                guard let _ = data else {
                    response(JSON())
                    return
                }
                var decodedResponse = decode(text: String(data: data!, encoding: .utf8)!)
                po(decodedResponse)
                decodedResponse = decodedResponse.replacingOccurrences(of: "}++", with: "}")
                
                let json = JSON.init(parseJSON: decodedResponse)
                response(json)
            }
            
            }.resume()
    }
    
    
    static func loadUserTags() {
        guard let token = AppManager.loadToken() else { return }
        Connector.shared.getFavoriteTags(with: token) { (json) in
        }
    }
    
    static func loadUserHistory() {
        guard let token = AppManager.loadToken() else { return }
        Connector.shared.getHistory(with: token) { (json) in
        }
    }
    
    static func loadPopularHashtags() {
        Connector.shared.getPopular { (json) in
        }
    }
    
    static func loadTrends() {
        Connector.shared.getTrends { (json) in
        }
    }
    
    static func setUser(tag: String) {
        guard let token = AppManager.loadToken() else { return }
        Connector.shared.setFavoriteTag(with: token, and: tag) { (json) in
        }
    }
    
    static func setUserHistory(caption: String) {
        guard let token = AppManager.loadToken(),
            caption.count > 0 else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.autoupdatingCurrent
        Connector.shared.setHistory(with: token, and: caption, and: formatter.string(from: Date())) { (json) in
            po(json)
        }
    }
}

func prepare(_ request: inout URLRequest) {
    request.timeoutInterval = 20
    request.httpMethod = "POST"
}


func prepareGET(_ request: inout URLRequest) {
    request.timeoutInterval = 20
}
