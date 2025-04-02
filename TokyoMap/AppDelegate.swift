//
//  AppDelegate.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/03.
//

import Foundation
import NotificationCenter
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
       // リクエストのメソッド呼び出し
       NotificationManager.instance.requestPermission()
       
       UNUserNotificationCenter.current().delegate = self

       return true
   }
    
    // フォアグラウンド時の通知表示
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge]) // 通知を表示するオプションを指定
    }

}
