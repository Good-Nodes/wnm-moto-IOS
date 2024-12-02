//
//  myWebview.swift
//  wnm-moto-IOS
//
//  Created by 이연주 on 12/2/24.
//

import SwiftUI
@preconcurrency import WebKit

// uikit의 uiview를 사용할 수 있도록 하는 것
// UIViewControllerRepresentable
struct MyWebView: UIViewRepresentable {

    var urlToLoad: String
    
    // ui view 만들기
    func makeUIView(context: Context) -> some WKWebView {
        
        // unwrapping
//        guard let url = URL(string: self.urlToLoad) else {
//            return WKWebView()
//        }
        
        // webview instance 생성
        let webview = WKWebView()
        
        // JavaScript에서 보내는 메시지를 수신하기 위한 핸들러 설정
        webview.configuration.userContentController.add(context.coordinator, name: "updateIntegratedNotification")
        
        // 캐시 및 쿠키 초기화 함수
        func clearWebViewCacheAndCookies() {
            let websiteDataTypes = NSSet(array: [
                WKWebsiteDataTypeMemoryCache,
                WKWebsiteDataTypeDiskCache,
                WKWebsiteDataTypeOfflineWebApplicationCache,
                WKWebsiteDataTypeCookies,
                WKWebsiteDataTypeLocalStorage,
                WKWebsiteDataTypeSessionStorage,
                WKWebsiteDataTypeIndexedDBDatabases,
                WKWebsiteDataTypeWebSQLDatabases
            ])
            
            let dateFrom = Date(timeIntervalSince1970: 0) // 1970년 1월 1일부터의 데이터 모두 삭제
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                print("웹뷰 캐시 및 쿠키 초기화 완료")
            }
        }

        // userAgent 설정: userAgent 값을 가져온 후 커스텀 값을 추가
        webview.evaluateJavaScript("navigator.userAgent") { (result, error) in
            if let userAgent = result as? String {
                print(userAgent)
                let customUserAgent =
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" + " APP_Wnm"
                //  let customUserAgent = userAgent + " APP_Dewbee"
                
                // 실제 사용하는 webView에 설정
                webview.customUserAgent = customUserAgent

                // 이제 URL 로드
                if let url = URL(string: self.urlToLoad) {
                    webview.load(URLRequest(url: url))
                }
            }
        }
        
        webview.uiDelegate = context.coordinator // UI 대리자 설정
        webview.navigationDelegate = context.coordinator // 내비게이션 대리자 설정
        webview.allowsBackForwardNavigationGestures = true // 스와이프 제스쳐
        
        return webview
    }
    
    // 업데이트 ui view
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<MyWebView>) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MyWebView

        init(_ parent: MyWebView) {
            self.parent = parent
        }
            
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.scheme == "mailto" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel) // WebView에서 기본 동작을 중지합니다.
            } else {
                decisionHandler(.allow) // 기본 웹 뷰 탐색을 계속합니다.
            }
        }

        // 새 창 열기 처리
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // 새 창이나 팝업 링크의 경우 현재 웹뷰에서 로드
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // JavaScript 메시지를 받아 처리하는 메서드
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "updateIntegratedNotification" {
                print("Received message: \(message.body)")  // 로그로 메시지 확인
                if let body = message.body as? [String: Any] {
                    if let notificationKey = body["notificationKey"] as? String,
                       let notificationValue = body["notificationValue"] as? Bool {
                        print("notificationKey: \(notificationKey), notificationValue: \(notificationValue)")
                        self.updateAppBadge(with: notificationValue ? "true" : "false")
                    }
                }
            }
        }
                    
        // 앱 뱃지 상태 업데이트
        private func updateAppBadge(with value: String) {
            let badgeCount = value.lowercased() == "true" ? 1 : 0
            setAppBadgeCount(badgeCount)
        }
                    
        // iOS 17+ 뱃지 업데이트
        private func setAppBadgeCount(_ count: Int) {
            let center = UNUserNotificationCenter.current()
            center.setBadgeCount(count) { error in
            if let error = error {
                    print("Error setting badge count: \(error.localizedDescription)")
                } else {
                    print("Badge count updated to \(count)")
                }
            }
        }
            
        // 필요에 따라 추가 WKUIDelegate 및 WKNavigationDelegate 메소드 구현
    }
  
    // 메일 링크 처리
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "mailto" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        print("메일 앱 열기 성공")
                    } else {
                        print("메일 앱을 열 수 없습니다.")
                    }
                }
            } else {
                print("이 디바이스에서는 mailto 링크를 처리할 수 없습니다.")
            }
            decisionHandler(.cancel) // WebView에서 기본 동작을 중지합니다.
        } else {
            decisionHandler(.allow) // 기본 웹 뷰 탐색을 계속합니다.
        }
    }
    
    // 새 창 열기 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // 새 창이나 팝업 링크의 경우 현재 웹뷰에서 로드
        if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
