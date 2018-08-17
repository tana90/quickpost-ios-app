//
//  LocationManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 6/29/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    
    /*var locationManager = CLLocationManager()
    
    static let shared: LocationManager = {
        let instance = LocationManager()
        
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
    
    
    func start() {
        locationManager = CLLocationManager()
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
//        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.delegate = nil
//        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
    }
    
    func isAuthorized() -> Bool {
        if CLLocationManager.locationServicesEnabled(),
            CLLocationManager.authorizationStatus() == .authorizedAlways {
            return true
        }
        return false
    }
    */
}

extension LocationManager: CLLocationManagerDelegate {
    
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //po("Update location")
    }*/
}
