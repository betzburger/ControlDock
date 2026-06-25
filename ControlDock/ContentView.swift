//
//  ContentView.swift
//  ControlDock (iOS)
//
//  Root view that switches between discovery and the live deck.
//

import SwiftUI

struct ContentView: View {
    @Environment(DeckClient.self) private var client

    var body: some View {
        ZStack {
            DeckTheme.background.ignoresSafeArea()

            switch client.phase {
            case .browsing, .connecting:
                ServerListView()
                    .transition(.opacity)
            case .needsPIN(let reason):
                PinEntryView(reason: reason)
                    .transition(.opacity)
            case .connected:
                if client.layout != nil {
                    DeckView()
                        .transition(.opacity)
                } else {
                    LoadingView(text: "Lade Deck …")
                }
            case .failed(let message):
                FailureView(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: client.phase)
        .onAppear { client.startBrowsing() }
    }
}

// MARK: - Loading & failure

struct LoadingView: View {
    let text: String
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large).tint(.white)
            Text(text).foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct FailureView: View {
    @Environment(DeckClient.self) private var client
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("Verbindung fehlgeschlagen")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button {
                client.disconnect()
            } label: {
                Label("Erneut suchen", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(DeckTheme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(40)
    }
}

#Preview {
    ContentView().environment(DeckClient())
}
