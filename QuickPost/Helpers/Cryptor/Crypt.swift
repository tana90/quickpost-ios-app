//
//  Crypt.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/31/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

func encode(text: String) -> String {
    var t = x(text: text, key: 70)
    t = x(text: t, key: 73)
    t = x(text: t, key: 54)
    t = x(text: t, key: 24)
    return t
}

func decode(text: String) -> String {
    var t = x(text: text, key: 24)
    t = x(text: t, key: 54)
    t = x(text: t, key: 73)
    t = x(text: t, key: 70)
    return t
}


func x(text: String, key: UInt8) -> String {
    return String(bytes: text.utf8.map{$0 ^ key}, encoding: String.Encoding.utf8) ?? ""
}
