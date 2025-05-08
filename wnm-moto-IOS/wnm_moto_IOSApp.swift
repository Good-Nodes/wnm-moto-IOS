//
//  wnm_moto_IOSApp.swift
//  wnm-moto-IOS
//
//  Created by 이연주 on 12/2/24.
//

import SwiftUI
import FacebookCore

@main
struct wnm_moto_IOSApp: App {
    // 런치스크린 로딩 시간 클래스 호출
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Facebook 앱 이벤트 활성화
                    AppEvents.shared.activateApp()
                }
        }
    }
}
