//
//  DeckServer.swift
//  ControlDockMac
//
//  Advertises a Bonjour service, accepts client connections, performs the
//  pairing handshake and dispatches button presses to the ActionExecutor.
//  Runs entirely off the main actor; reports changes back via @Sendable callbacks.
//

import Foundation
import Network

nonisolated final class DeckServer {

    struct ClientInfo: Identifiable, Sendable, Hashable {
        let id: UUID
        let name: String
    }

    // Callbacks to the UI layer (dispatched to the main actor by the receiver).
    var onStatusChange: (@Sendable (_ running: Bool, _ serviceName: String) -> Void)?
    var onClientsChange: (@Sendable ([ClientInfo]) -> Void)?
    var onActivity: (@Sendable (_ message: String) -> Void)?

    private let queue = DispatchQueue(label: "com.betzburger.controldock.server")
    private var listener: NWListener?
    private var connections: [UUID: ClientConnection] = [:]

    // Config snapshot guarded by `lock` so connection handlers can read it.
    private let lock = NSLock()
    private var layout = DeckLayout()
    private var requirePIN = true
    private var pin = "0000"

    // MARK: - Lifecycle

    func start(serviceName: String) {
        queue.async { self.startListener(serviceName: serviceName) }
    }

    func stop() {
        queue.async {
            self.listener?.cancel()
            self.listener = nil
            self.connections.values.forEach { $0.connection.cancel() }
            self.connections.removeAll()
            self.onStatusChange?(false, "")
            self.onClientsChange?([])
        }
    }

    /// Updates the config snapshot and pushes the new layout to all clients.
    func updateConfig(layout: DeckLayout, requirePIN: Bool, pin: String) {
        lock.lock()
        self.layout = layout
        self.requirePIN = requirePIN
        self.pin = pin
        lock.unlock()

        queue.async {
            for client in self.connections.values where client.authed {
                client.send(.layout(layout))
            }
        }
    }

    private func currentLayout() -> DeckLayout { lock.lock(); defer { lock.unlock() }; return layout }
    private func pinRequired() -> Bool { lock.lock(); defer { lock.unlock() }; return requirePIN }
    private func currentPIN() -> String { lock.lock(); defer { lock.unlock() }; return pin }

    // MARK: - Listener

    private func startListener(serviceName: String) {
        listener?.cancel()
        do {
            let listener = try NWListener(using: .tcp)
            listener.service = NWListener.Service(name: serviceName, type: ControlDockService.type)
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.onStatusChange?(true, serviceName)
                    self?.onActivity?("Server läuft als „\(serviceName)“")
                case .failed(let error):
                    self?.onStatusChange?(false, "")
                    self?.onActivity?("Server-Fehler: \(error.localizedDescription)")
                case .cancelled:
                    self?.onStatusChange?(false, "")
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            onStatusChange?(false, "")
            onActivity?("Server konnte nicht starten: \(error.localizedDescription)")
        }
    }

    // MARK: - Connections

    private func accept(_ nwConnection: NWConnection) {
        let client = ClientConnection(connection: nwConnection)
        connections[client.id] = client

        nwConnection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.remove(client)
            default:
                break
            }
        }
        nwConnection.start(queue: queue)
        receive(on: client)
    }

    private func receive(on client: ClientConnection) {
        client.connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                client.frame.append(data)
                while let payload = client.frame.nextFrame() {
                    if let message = try? MessageCodec.decode(ClientMessage.self, from: payload) {
                        self.handle(message, from: client)
                    }
                }
            }
            if error != nil || isComplete {
                self.remove(client)
                return
            }
            self.receive(on: client)
        }
    }

    private func handle(_ message: ClientMessage, from client: ClientConnection) {
        switch message {
        case let .hello(deviceName, providedPIN, version):
            client.name = deviceName
            guard version == ControlDockService.protocolVersion else {
                client.send(.helloAck(accepted: false, reason: "Inkompatible App-Version"))
                return
            }
            if pinRequired() && providedPIN != currentPIN() {
                client.send(.helloAck(accepted: false, reason: "Falsche PIN. Gib die auf dem Mac angezeigte PIN ein."))
                return
            }
            client.authed = true
            client.send(.helloAck(accepted: true, reason: ""))
            client.send(.layout(currentLayout()))
            onActivity?("„\(deviceName)“ verbunden")
            publishClients()

        case .requestLayout:
            guard client.authed else { return }
            client.send(.layout(currentLayout()))

        case let .press(buttonID):
            guard client.authed else { return }
            execute(buttonID: buttonID, for: client)
        }
    }

    private func execute(buttonID: UUID, for client: ClientConnection) {
        guard let button = currentLayout().buttons.first(where: { $0.id == buttonID }) else {
            client.send(.actionResult(buttonID: buttonID, success: false, message: "Button nicht gefunden"))
            return
        }
        onActivity?("„\(client.name)“ → \(button.title)")
        // Run potentially blocking work off the server queue.
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ActionExecutor.execute(button)
            self.queue.async {
                client.send(.actionResult(buttonID: buttonID, success: result.success, message: result.message))
            }
        }
    }

    private func remove(_ client: ClientConnection) {
        client.connection.cancel()
        if connections.removeValue(forKey: client.id) != nil, client.authed {
            onActivity?("„\(client.name)“ getrennt")
            publishClients()
        }
    }

    private func publishClients() {
        let infos = connections.values
            .filter { $0.authed }
            .map { ClientInfo(id: $0.id, name: $0.name) }
            .sorted { $0.name < $1.name }
        onClientsChange?(infos)
    }
}

// MARK: - Per-client connection state

private final class ClientConnection {
    let id = UUID()
    let connection: NWConnection
    var frame = FrameBuffer()
    var name = "Gerät"
    var authed = false

    init(connection: NWConnection) {
        self.connection = connection
    }

    func send(_ message: ServerMessage) {
        guard let data = try? MessageCodec.encode(message) else { return }
        connection.send(content: data, completion: .contentProcessed { _ in })
    }
}
