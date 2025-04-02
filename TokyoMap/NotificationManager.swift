//
//  NotificationManager.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/03.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let instance: NotificationManager = NotificationManager()
    
    // 権限リクエスト
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { (granted, _) in
                print("Permission granted: \(granted)")
            }
    }
    
    // notificationの登録
    func sendNotification(_ title: String, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "newPlace", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
