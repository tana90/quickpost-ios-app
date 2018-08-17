//
//  KeyChain.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/25/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

struct KeyChain {
    
    static func remove(_ key: String) {
        let deleteQuery = KeyChain.query(key)
        let status: OSStatus = SecItemDelete(deleteQuery as CFDictionary)
        guard status == errSecSuccess else { return }
    }
    
    static func load(_ key: String) -> Data? {
        
        var loadQuery = KeyChain.query(key)
        loadQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        loadQuery[kSecReturnData as String] = kCFBooleanTrue
        var result: AnyObject?
        let status = SecItemCopyMatching(loadQuery as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        
        return (result as! Data)
    }
    
    static func load(string key: String) -> String? {
        return String(data: KeyChain.load(key) ?? Data(), encoding: .utf8)
    }
    
    static func save(_ value: Data, forkey: String) {
        
        //Remove old
        KeyChain.remove(forkey)
        
        //Add new one
        var saveQuery = KeyChain.query(forkey)
        saveQuery[kSecValueData as String] = value
        let status: OSStatus = SecItemAdd(saveQuery as CFDictionary, nil)
        guard status == errSecSuccess else { return }
        
    }
    
    
    static func query(_ key: String) -> [String : Any] {
        
        return [kSecClass as String : kSecClassGenericPassword as String,
                kSecAttrGeneric as String : key,
                kSecAttrAccount as String : key,
                kSecAttrService as String : "com.aww.quickpostig",
                kSecAttrAccessGroup as String : "group.com.aww.quickpostig",
                kSecAttrAccessible as String : kSecAttrAccessibleAlwaysThisDeviceOnly as String]
    }
}



