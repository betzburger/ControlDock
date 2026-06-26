//
//  ServerListView.swift
//  ControlDock (iOS)
//
//  Discovery screen listing ControlDock Macs found on the local network.
//

import SwiftUI

struct ServerListView: View {
    @Environment(DeckClient.self) private var client
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(DeckTheme.accent)
                    .shadow(color: DeckTheme.accent.opacity(0.6), radius: 18)
                Text("ControlDock")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Mac im selben WLAN auswählen")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.top, 40)

            if client.servers.isEmpty {
                VStack(spacing: 14) {
                    ProgressView().tint(.white)
                    Text("Suche nach Macs …")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(client.servers) { server in
                            Button {
                                client.connect(to: server)
                            } label: {
                                ServerRow(name: server.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer(minLength: 0)
        }
        .overlay(alignment: .topTrailing) {
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(20)
        }
        .sheet(isPresented: $showHelp) { HelpView() }
    }
}

private struct ServerRow: View {
    let name: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "macbook")
                .font(.title2)
                .foregroundStyle(DeckTheme.accent)
                .frame(width: 44, height: 44)
                .background(DeckTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline).foregroundStyle(.white)
                Text("Tippen zum Verbinden").font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
        .background(DeckTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(DeckTheme.panelStroke, lineWidth: 1))
    }
}

#Preview {
    ZStack { DeckTheme.background.ignoresSafeArea(); ServerListView() }
        .environment(DeckClient())
}
