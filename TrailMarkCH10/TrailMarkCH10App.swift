//
//  TrailMarkCH10App.swift
//  TrailMarkCH10
//
//  Created by Ramses Garcia on 05/09/26.
//

import SwiftUI

@main
struct TrailMarkCH10App: App {
    @State private var model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
