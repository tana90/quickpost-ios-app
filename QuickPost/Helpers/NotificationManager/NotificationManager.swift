//
//  NotificationManager.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/6/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject {
    
    struct Notification {
        
        struct Category {
            static let phPost = "photoPostCategory"
        }
        
        struct Action {
            static let postNow = "postNow"
            static let snooze = "snooze"
            static let cancel = "cancel"
        }
    }
    
    static let shared: NotificationManager = {
        let instance = NotificationManager()
        instance.configureUserNotificationsCenter()
        return instance
    }()
    
    private func configureUserNotificationsCenter() {
        
        UNUserNotificationCenter.current().delegate = self
        
        let actionPostNow = UNNotificationAction(identifier: Notification.Action.postNow, title: "Post now", options: [.authenticationRequired, .foreground])
        let actionSnooze = UNNotificationAction(identifier: Notification.Action.snooze, title: "Remind me in 5 min", options: [])
        let actionCancel = UNNotificationAction(identifier: Notification.Action.cancel, title: "Cancel", options: [.destructive])
        
        let category = UNNotificationCategory(identifier: Notification.Category.phPost, actions: [actionPostNow, actionSnooze, actionCancel], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    public func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
                    if let error = error {
                        print("Request Authorization Failed (\(error), \(error.localizedDescription))")
                    }
                    
                    completionHandler(success)
                }
            case .authorized:
                completionHandler(true)
                break
            case .denied:
                completionHandler(false)
                break
            }
        }
    }
    
    public func scheduleNotification(with scheduleData: ScheduleData) {
        
        if let date = scheduleData.scheduledDate,
            let caption = scheduleData.caption,
            let pictureData = scheduleData.picture {
            
            let notificationContent = UNMutableNotificationContent()
            
            // Configure Notification Content
            notificationContent.title = "Scheduled post"
            notificationContent.subtitle = caption
            notificationContent.body = ""
            
            // Set Category Identifier
            notificationContent.categoryIdentifier = Notification.Category.phPost
            
            notificationContent.userInfo = ["objectId" : scheduleData.objectId ?? NSUUID().uuidString]
            notificationContent.sound = UNNotificationSound.default()
            
            if let image = UIImage(data: pictureData) {
                if let attachment = UNNotificationAttachment.create(identifier: "PhotoIdentifierAtachament",
                                                                    image: image,
                                                                    options: nil) {
                    notificationContent.attachments = [attachment]
                }
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second, .nanosecond], from: date)
            let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            
            // Create Notification Request
            let notificationRequest = UNNotificationRequest(identifier: scheduleData.objectId ?? NSUUID().uuidString, content: notificationContent, trigger: notificationTrigger)
            
            // Add Request to User Notification Center
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                }
            }
            
        }
    }
}


extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        
        switch response.actionIdentifier {
        
        //POST NOW
        case Notification.Action.postNow:
            Schedule.fetchBy(id: response.notification.request.identifier) { (object) in
                
                let schedule = object as! Schedule
                guard let pictureData = schedule.picture,
                    let image = UIImage(data: pictureData) else {
                        completionHandler()
                        return
                }
                
                PhotoPoster.postPhotoToInstagram(image: image, caption: schedule.caption ?? "", callBackViewController: nil, completion: {
                    schedule.markAsPosted()
                    CoreDataManager.shared.saveContext()
                    AppManager.incrementNumberOfScans()
                    EventManager.shared.sendEvent(name: "schedule_post_notification", type: "action")
                    completionHandler()
                })
            }
            break
            
        //REMIND ME LATER
        case Notification.Action.snooze:
            
            
            Schedule.fetchBy(id: response.notification.request.identifier) { (object) in
                
                let schedule = object as! Schedule
                guard let date = schedule.scheduledDate else {
                        completionHandler()
                        return
                }
                
                //Add 5 minutes
                let newDate = date.addingTimeInterval(5.0 * 60)
                
                var scheduleData = schedule.getData()
                scheduleData.scheduledDate = newDate
                scheduleNotification(with: scheduleData)

            }
            
            
            
            completionHandler()
            break
            
        //CANCEL
        case Notification.Action.cancel:
            po("CANCEL")
            completionHandler()
            break
            
        //POST NOW
        default:
            
            Schedule.fetchBy(id: response.notification.request.identifier) { (object) in
                
                let schedule = object as! Schedule
                guard let pictureData = schedule.picture,
                    let image = UIImage(data: pictureData) else {
                        completionHandler()
                        return
                }
                
                PhotoPoster.postPhotoToInstagram(image: image, caption: schedule.caption ?? "", callBackViewController: nil, completion: {
                    schedule.markAsPosted()
                    CoreDataManager.shared.saveContext()
                    AppManager.incrementNumberOfScans()
                    EventManager.shared.sendEvent(name: "schedule_post_notification", type: "action")
                    completionHandler()
                })
            }
        }

    }
}
