//
//  AppModel.swift
//  ControlDockMac
//
//  Main-actor observable state: the deck configuration, pairing settings,
//  server status and connected devices. Owns the DeckServer and persistence.
//

import Foundation
import Observation
import AppKit
import SwiftUI

/// Codable snapshot persisted to UserDefaults.
private struct PersistedConfig: Codable {
    var deckName: String
    var buttons: [DeckButton]
    var requirePIN: Bool
    var pin: String
}

@MainActor
@Observable
final class AppModel {

    // Deck configuration
    var deckName: String { didSet { sync() } }
    var buttons: [DeckButton] { didSet { sync() } }

    // Pairing
    var requirePIN: Bool { didSet { sync() } }
    var pin: String { didSet { sync() } }

    // Live status (updated from the server)
    private(set) var serverRunning = false
    private(set) var serviceName = ""
    private(set) var clients: [DeckServer.ClientInfo] = []
    private(set) var activityLog: [String] = []

    // Editor selection
    var selectedButtonID: DeckButton.ID?

    private let server = DeckServer()
    private let defaults = UserDefaults.standard
    private let storageKey = "controldock.config.v1"
    private var loaded = false

    var hasKeystrokeButtons: Bool { buttons.contains { $0.actionType == .keystroke } }
    var accessibilityGranted: Bool { KeystrokeSimulator.isTrusted }

    init() {
        if let data = defaults.data(forKey: storageKey),
           let config = try? JSONDecoder().decode(PersistedConfig.self, from: data) {
            deckName = config.deckName
            buttons = config.buttons
            requirePIN = config.requirePIN
            pin = config.pin
        } else {
            deckName = "Mein Deck"
            buttons = AppModel.starterButtons
            requirePIN = true
            pin = String(format: "%04d", Int.random(in: 0...9999))
        }
        loaded = true
        configureServer()
    }

    private var layout: DeckLayout {
        DeckLayout(deckName: deckName, buttons: buttons)
    }

    // MARK: - Server

    private func configureServer() {
        server.onStatusChange = { [weak self] running, name in
            Task { @MainActor in
                self?.serverRunning = running
                self?.serviceName = name
            }
        }
        server.onClientsChange = { [weak self] infos in
            Task { @MainActor in self?.clients = infos }
        }
        server.onActivity = { [weak self] message in
            Task { @MainActor in self?.log(message) }
        }
        server.updateConfig(layout: layout, requirePIN: requirePIN, pin: pin)
        let name = Host.current().localizedName ?? "Mac"
        server.start(serviceName: name)
    }

    private func sync() {
        guard loaded else { return }
        persist()
        server.updateConfig(layout: layout, requirePIN: requirePIN, pin: pin)
    }

    private func persist() {
        let config = PersistedConfig(deckName: deckName,
                                     buttons: buttons, requirePIN: requirePIN, pin: pin)
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func log(_ message: String) {
        let stamp = DateFormatter.logTime.string(from: Date())
        activityLog.insert("\(stamp)  \(message)", at: 0)
        if activityLog.count > 100 { activityLog.removeLast(activityLog.count - 100) }
    }

    // MARK: - Button CRUD

    func addButton() {
        var button = DeckButton()
        button.colorHex = AppModel.palette.randomElement() ?? "#3B82F6"
        buttons.append(button)
        selectedButtonID = button.id
    }

    func deleteSelectedButton() {
        guard let id = selectedButtonID else { return }
        buttons.removeAll { $0.id == id }
        selectedButtonID = buttons.first?.id
    }

    func binding(for id: DeckButton.ID) -> DeckButton? {
        buttons.first { $0.id == id }
    }

    func update(_ button: DeckButton) {
        guard let index = buttons.firstIndex(where: { $0.id == button.id }) else { return }
        buttons[index] = button
    }

    func move(from offsets: IndexSet, to destination: Int) {
        buttons.move(fromOffsets: offsets, toOffset: destination)
    }

    /// Runs a button's action locally (the "Test" button in the editor).
    func test(_ button: DeckButton) {
        log("Test: \(button.title)")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ActionExecutor.execute(button)
            Task { @MainActor in self.log(result.success ? "✓ \(result.message)" : "✗ \(result.message)") }
        }
    }

    func regeneratePIN() {
        pin = String(format: "%04d", Int.random(in: 0...9999))
    }

    func requestAccessibility() {
        KeystrokeSimulator.requestAccess()
    }

    // MARK: - Defaults

    static let palette = ["#3B82F6", "#22C55E", "#EF4444", "#A855F7", "#F59E0B", "#06B6D4", "#EC4899"]

    static let starterButtons: [DeckButton] = [
        DeckButton(title: "Sperren", symbol: "lock.fill", colorHex: "#EF4444",
                   actionType: .keystroke, payload: "ctrl+cmd+q"),
        DeckButton(title: "Screenshot", symbol: "camera.fill", colorHex: "#22C55E",
                   actionType: .keystroke, payload: "cmd+shift+4"),
        DeckButton(title: "Safari", symbol: "safari.fill", colorHex: "#3B82F6",
                   actionType: .launchApp, payload: "Safari"),
        DeckButton(title: "Sag Hallo", symbol: "speaker.wave.2.fill", colorHex: "#A855F7",
                   actionType: .shellScript, payload: "say Hallo Peter"),
    ]
}

private extension DateFormatter {
    static let logTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
