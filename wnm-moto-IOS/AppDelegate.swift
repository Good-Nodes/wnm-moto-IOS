//
//  AppDelegate.swift
//  wnm-moto-IOS
//
//  Created by 이연주 on 12/2/24.
//


import Foundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Thread.sleep(forTimeInterval: 1.5)
        return true
    }
    
    // 앱이 완전히 실행된 후 호출되는 메서드
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            // 알림 권한 요청
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                } else if granted {
                    print("Notification permission granted.")
                } else {
                    print("Notification permission denied.")
                }
            }
            
            return true
        }
}
