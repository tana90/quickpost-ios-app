//
//  EventHandler.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation

final class EventHandler {
    
    typealias Event = () -> (Void)
    static let shared: EventHandler = {
        return EventHandler()
    }()
    
    public func removeAll() {
        upgradeToPROEvents?.removeAll()
    }
    
    //MARK: App become PRO
    private var upgradeToPROEvents: [Event]? = []
    public func upgradeToPRO() {
        upgradeToPROEvents?.forEach { (event) in event() }
    }
    
    public func upgradeToPRO(_ event: @escaping Event) {
        upgradeToPROEvents?.append(event)
    }
    
    
    //MARK: Open Favorites
    private var openFavoritesEvents: [Event]? = []
    public func openFavorites() {
        openFavoritesEvents?.forEach { (event) in event() }
    }
    
    public func openFavorites(_ event: @escaping Event) {
        openFavoritesEvents?.append(event)
    }
    
    //MARK: Repost available
    private var repostAvailableEvents: [Event]? = []
    public func repostAvailable() {
        repostAvailableEvents?.forEach { (event) in event() }
    }
    
    public func repostAvailable(_ event: @escaping Event) {
        repostAvailableEvents?.append(event)
    }
    
    //MARK: Allow background change
    private var allowBackgroundChangeEvents: [Event]? = []
    public func allowBackgroundChange() {
        allowBackgroundChangeEvents?.forEach { (event) in event() }
    }
    
    public func allowBackgroundChange(_ event: @escaping Event) {
        allowBackgroundChangeEvents?.append(event)
    }
}
