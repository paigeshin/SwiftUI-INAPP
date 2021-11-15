//
//  SwiftUIInAppApp.swift
//  SwiftUIInApp
//
//  Created by paige on 2021/11/15.
//

import SwiftUI

@main
struct SwiftUIInAppApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
