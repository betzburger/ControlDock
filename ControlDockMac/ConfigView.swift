//
//  ConfigView.swift
//  ControlDockMac
//
//  The main configuration window: status sidebar, button list and editor.
//

import SwiftUI

struct ConfigView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            StatusSidebar()
                .frame(width: 290)
            Divider()
            ButtonListPane()
                .frame(minWidth: 280)
            Divider()
            EditorPane()
                .frame(width: 340)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Status sidebar

private struct StatusSidebar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                GroupCard(title: "Verbindung", systemImage: "wifi") {
                    HStack(spacing: 8) {
                        Circle().fill(model.serverRunning ? .green : .orange).frame(width: 9, height: 9)
                        Text(model.serverRunning ? "Server aktiv" : "Server startet …")
                            .font(.subheadline)
                        Spacer()
                    }
                    if model.serverRunning {
                        LabeledContent("Name", value: model.serviceName)
                            .font(.caption)
                    }
                    Divider().padding(.vertical, 2)
                    Toggle("PIN erforderlich", isOn: $model.requirePIN)
                        .font(.subheadline)
                    if model.requirePIN {
                        HStack {
                            Text("PIN")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(model.pin)
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .monospacedDigit()
                            Button {
                                model.regeneratePIN()
                            } label: { Image(systemName: "arrow.clockwise") }
                                .buttonStyle(.borderless)
                                .help("Neue PIN erzeugen")
                        }
                    }
                }

                GroupCard(title: "Geräte", systemImage: "iphone") {
                    if model.clients.isEmpty {
                        Text("Keine Geräte verbunden")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(model.clients) { client in
                            HStack(spacing: 8) {
                                Image(systemName: "iphone").foregroundStyle(MacTheme.accent)
                                Text(client.name).font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                }

                GroupCard(title: "Aktivität", systemImage: "list.bullet.rectangle") {
                    if model.activityLog.isEmpty {
                        Text("Noch keine Ereignisse")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(model.activityLog.prefix(12).enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(MacTheme.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text("ControlDock").font(.headline)
                Text("Mac-Steuerzentrale").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { openWindow(id: "help") } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("ControlDock-Hilfe öffnen")
        }
    }
}

// MARK: - Button list

private struct ButtonListPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            HStack {
                TextField("Deck-Name", text: $model.deckName)
                    .textFieldStyle(.plain)
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider()

            if model.accessibilityWarning {
                AccessibilityBanner()
            }

            List(selection: $model.selectedButtonID) {
                ForEach(model.buttons) { button in
                    ButtonRow(button: button)
                        .tag(button.id)
                }
                .onMove { model.move(from: $0, to: $1) }
            }
            .listStyle(.inset)

            Divider()
            HStack(spacing: 12) {
                Button {
                    model.addButton()
                } label: { Label("Button", systemImage: "plus") }
                Button {
                    model.deleteSelectedButton()
                } label: { Image(systemName: "trash") }
                    .disabled(model.selectedButtonID == nil)
                Spacer()
                Text("\(model.buttons.count) Buttons")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }
}

private extension AppModel {
    var accessibilityWarning: Bool { hasKeystrokeButtons && !accessibilityGranted }
}

private struct ButtonRow: View {
    let button: DeckButton
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(hex: button.colorHex).gradient)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: button.symbol)
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            VStack(alignment: .leading, spacing: 1) {
                Text(button.title).font(.body)
                Text(button.actionType.displayName)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct AccessibilityBanner: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Tastendrücke benötigen die Bedienungshilfen-Berechtigung.")
                .font(.caption)
            Spacer()
            Button("Erlauben") { model.requestAccessibility() }
                .controlSize(.small)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.orange.opacity(0.12))
    }
}

// MARK: - Reusable card

struct GroupCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
    }
}

#Preview {
    ConfigView().environment(AppModel())
}
