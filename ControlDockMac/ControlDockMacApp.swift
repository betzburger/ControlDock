//
//  ControlDockMacApp.swift
//  ControlDockMac
//
//  The Mac companion: configure deck buttons and run their actions when
//  triggered from an iPhone or iPad over the local network.
//

import SwiftUI

@main
struct ControlDockMacApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("ControlDock", id: "main") {
            ConfigView()
                .environment(model)
                .frame(minWidth: 880, minHeight: 560)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .help) {
                HelpMenuCommand()
            }
        }

        Window("ControlDock-Hilfe", id: "help") {
            HelpView()
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentMinSize)
    }
}

/// Opens the dedicated help window from the Help menu (⌘?).
struct HelpMenuCommand: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("ControlDock-Hilfe") { openWindow(id: "help") }
            .keyboardShortcut("?", modifiers: [.command])
    }
}
