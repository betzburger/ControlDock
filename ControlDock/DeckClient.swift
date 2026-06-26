//
//  DeckClient.swift
//  ControlDock (iOS)
//
//  Discovers ControlDock Macs via Bonjour and maintains a TCP connection
//  over which it receives the deck layout and sends button presses.
//

import Foundation
import Network
import Observation
import UIKit

// MARK: - Connection session (runs off the main actor)

/// Owns a single NWConnection and its frame parsing on a background queue,
/// forwarding decoded events and messages to the main actor via callbacks.
nonisolated final class ConnectionSession: @unchecked Sendable {
    enum Event: Sendable {
        case ready
        case failed(String)
        case ended
    }

    private let connection: NWConnection
    private let queue = DispatchQueue(label: "com.betzburger.controldock.session")
    private var frameBuffer = FrameBuffer()

    var onEvent: (@Sendable (Event) -> Void)?
    var onMessage: (@Sendable (ServerMessage) -> Void)?

    init(endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.onEvent?(.ready)
                self.receiveLoop()
            case .failed(let error):
                self.onEvent?(.failed(error.localizedDescription))
            case .cancelled:
                self.onEvent?(.ended)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    func send(_ message: ClientMessage) {
        guard let data = try? MessageCodec.encode(message) else { return }
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    func cancel() {
        connection.stateUpdateHandler = nil
        connection.cancel()
    }

    private func receiveLoop() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.frameBuffer.append(data)
                while let payload = self.frameBuffer.nextFrame() {
                    if let message = try? MessageCodec.decode(ServerMessage.self, from: payload) {
                        self.onMessage?(message)
                    }
                }
            }
            if let error {
                self.onEvent?(.failed(error.localizedDescription))
                return
            }
            if isComplete {
                self.onEvent?(.ended)
                return
            }
            self.receiveLoop()
        }
    }
}

// MARK: - Deck client (main-actor UI state)

@MainActor
@Observable
final class DeckClient {

    enum Phase: Equatable {
        case browsing
        case connecting(String)
        case needsPIN(String)
        case connected
        case failed(String)
    }

    struct DiscoveredServer: Identifiable, Hashable {
        let id: String
        let name: String
        let endpoint: NWEndpoint

        static func == (lhs: DiscoveredServer, rhs: DiscoveredServer) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    struct ActionFeedback: Identifiable, Equatable {
        let id = UUID()
        let buttonID: UUID
        let success: Bool
        let message: String
    }

    private(set) var phase: Phase = .browsing
    private(set) var servers: [DiscoveredServer] = []
    private(set) var layout: DeckLayout?
    private(set) var connectedServerName: String = ""
    var lastFeedback: ActionFeedback?

    var deviceName: String = UIDevice.current.name

    private var browser: NWBrowser?
    private var session: ConnectionSession?
    private var pin: String = ""

    // MARK: - Discovery

    func startBrowsing() {
        teardownSession()
        phase = .browsing
        let params = NWParameters()
        params.includePeerToPeer = true
        let descriptor = NWBrowser.Descriptor.bonjour(type: ControlDockService.type, domain: nil)
        let browser = NWBrowser(for: descriptor, using: params)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            let mapped = results.compactMap { result -> DiscoveredServer? in
                if case let .service(name, _, _, _) = result.endpoint {
                    return DiscoveredServer(id: name, name: name, endpoint: result.endpoint)
                }
                return nil
            }
            Task { @MainActor in self.servers = mapped.sorted { $0.name < $1.name } }
        }
        browser.start(queue: .global())
        self.browser = browser
    }

    // MARK: - Connection

    func connect(to server: DiscoveredServer, pin: String = "") {
        self.pin = pin
        teardownSession()
        connectedServerName = server.name
        phase = .connecting(server.name)

        let session = ConnectionSession(endpoint: server.endpoint)
        session.onEvent = { [weak self] event in
            guard let self else { return }
            Task { @MainActor in self.handle(event) }
        }
        session.onMessage = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in self.handle(message) }
        }
        session.start()
        self.session = session
    }

    func retryWithPIN(_ pin: String) {
        self.pin = pin
        phase = .connecting(connectedServerName)
        sendHello()
    }

    func disconnect() {
        teardownSession()
        startBrowsing()
    }

    func press(_ button: DeckButton) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        session?.send(.press(buttonID: button.id))
    }

    private func sendHello() {
        session?.send(.hello(deviceName: deviceName, pin: pin, protocolVersion: ControlDockService.protocolVersion))
    }

    // MARK: - Event handling

    private func handle(_ event: ConnectionSession.Event) {
        switch event {
        case .ready:
            sendHello()
        case .failed(let message):
            phase = .failed(message)
        case .ended:
            if case .connected = phase { phase = .failed("Verbindung getrennt") }
        }
    }

    private func handle(_ message: ServerMessage) {
        switch message {
        case let .helloAck(accepted, reason):
            if accepted {
                session?.send(.requestLayout)
                phase = .connected
            } else {
                phase = .needsPIN(reason.isEmpty ? "PIN erforderlich" : reason)
            }
        case let .layout(layout):
            self.layout = layout
            phase = .connected
        case let .actionResult(buttonID, success, message):
            lastFeedback = ActionFeedback(buttonID: buttonID, success: success, message: message)
        }
    }

    private func teardownSession() {
        session?.cancel()
        session = nil
        layout = nil
    }
}
