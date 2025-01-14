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
        
        // webview configuration 생성 및 userAgent 설정
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "APP_Wnm payple-pay-app"
        
        // webview instance 생성
        let webview = WKWebView(frame: .zero, configuration: configuration)
        
        // JavaScript에서 보내는 메시지를 수신하기 위한 핸들러 설정
        webview.configuration.userContentController.add(context.coordinator, name: "updateIntegratedNotification")
        
        // 캐시 및 쿠키 초기화 함수 호출
        clearWebViewCacheAndCookies()

        // URL 로드
        if let url = URL(string: self.urlToLoad) {
            webview.load(URLRequest(url: url))
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
            guard let url = navigationAction.request.url, let scheme = url.scheme else {
                return decisionHandler(.cancel)
            }
            
            debugPrint("url : \(url)")
            
            // mailto 처리
            if scheme == "mailto" {
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
                return decisionHandler(.cancel)
            }
            
            // 3rd-party 앱 Scheme 처리
            if scheme != "http" && scheme != "https" {
                if scheme == "ispmobile", !UIApplication.shared.canOpenURL(url) {  // ISP 미설치 시
                    if let ispURL = URL(string: "http://itunes.apple.com/kr/app/id369125087?mt=8") {
                        UIApplication.shared.open(ispURL)
                    }
                } else if scheme == "kftc-bankpay", !UIApplication.shared.canOpenURL(url) {  // BANKPAY 미설치 시
                    if let bankPayURL = URL(string: "http://itunes.apple.com/us/app/id398456030?mt=8") {
                        UIApplication.shared.open(bankPayURL)
                    }
                } else {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else {
                        print("앱이 설치되지 않았거나 info.plist에 scheme이 등록되지 않았습니다.")
                    }
                }
                return decisionHandler(.cancel)
            }
            
            // 기본 웹 탐색 허용
            decisionHandler(.allow)
        }

        // 새 창 열기 처리
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // 새 창이나 팝업 링크의 경우 현재 웹뷰에서 로드
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    completionHandler()
                })
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }

        // JavaScript 메시지를 받아 처리하는 메서드
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "updateIntegratedNotification" {
                print("Received message: \(message.body)")  // 로그로 메시지 확인
                if let body = message.body as? [String: Any] {
                    guard let notificationKey = body["notificationKey"] as? String,
                          let notificationValue = body["notificationValue"] as? Bool else {
                        print("메시지 데이터가 유효하지 않습니다.")
                        return
                    }
                    print("notificationKey: \(notificationKey), notificationValue: \(notificationValue)")
                    self.updateAppBadge(with: notificationValue ? "true" : "false")
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
            if #available(iOS 17.0, *) {
                let center = UNUserNotificationCenter.current()
                center.setBadgeCount(count) { error in
                    if let error = error {
                        print("Error setting badge count: \(error.localizedDescription)")
                    } else {
                        print("Badge count updated to \(count)")
                    }
                }
            } else {
                print("iOS 17 미만에서는 앱 뱃지 설정을 지원하지 않습니다.")
            }
        }
    }

    // 캐시 및 쿠키 초기화 함수
    private func clearWebViewCacheAndCookies() {
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
}
