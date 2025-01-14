//
//  ContentView.swift
//  wnm-moto-IOS
//
//  Created by 이연주 on 12/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MyWebView(urlToLoad: "https://moto.wnm.zone")
            .ignoresSafeArea()
            .scrollIndicators(/*@START_MENU_TOKEN@*/.never/*@END_MENU_TOKEN@*/, axes: /*@START_MENU_TOKEN@*/[.vertical, .horizontal]/*@END_MENU_TOKEN@*/)
    }
}
