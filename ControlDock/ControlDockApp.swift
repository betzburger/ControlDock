//
//  ControlDockApp.swift
//  ControlDock (iOS)
//
//  Created by Peter Betz on 25.06.26.
//

import SwiftUI

@main
struct ControlDockApp: App {
    @State private var client = DeckClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(client)
                .preferredColorScheme(.dark)
        }
    }
}
