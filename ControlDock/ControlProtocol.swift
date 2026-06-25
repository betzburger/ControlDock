//
//  ControlProtocol.swift
//  Shared wire protocol for ControlDock.
//
//  This file is duplicated verbatim in both the iOS client target and the
//  macOS server target. Keep the two copies in sync.
//

import Foundation

// MARK: - Service discovery

enum ControlDockService {
    /// Bonjour service type advertised by the Mac and browsed for by iOS.
    static let type = "_controldock._tcp"
    /// Bonjour domain (local network).
    static let domain = "local."
    /// Current protocol version. Bump on breaking changes.
    static let protocolVersion = 1
}

// MARK: - Action model

/// The kinds of action the Mac can perform when a button is pressed.
enum ActionType: String, Codable, CaseIterable, Hashable, Sendable {
    case launchApp      // payload = app name, bundle id, or full path
    case shellScript    // payload = shell command / script source
    case keystroke      // payload = key combo, e.g. "cmd+shift+4"
    case openURL        // payload = url string

    var displayName: String {
        switch self {
        case .launchApp:   return "App starten"
        case .shellScript: return "Shell-Befehl"
        case .keystroke:   return "Tastendruck"
        case .openURL:     return "URL öffnen"
        }
    }

    var symbol: String {
        switch self {
        case .launchApp:   return "app.dashed"
        case .shellScript: return "terminal"
        case .keystroke:   return "keyboard"
        case .openURL:     return "link"
        }
    }

    /// Hint text shown in the editor for the payload field.
    var payloadHint: String {
        switch self {
        case .launchApp:   return "App-Name, Bundle-ID oder Pfad (z. B. Safari)"
        case .shellScript: return "Shell-Befehl (z. B. say \"Hallo\")"
        case .keystroke:   return "Tastenkombination (z. B. cmd+shift+4)"
        case .openURL:     return "URL (z. B. https://apple.com)"
        }
    }
}

/// A single configurable button on the deck.
struct DeckButton: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    /// SF Symbol name used as the icon.
    var symbol: String
    /// Tint color encoded as "#RRGGBB".
    var colorHex: String
    var actionType: ActionType
    /// Action-specific payload (path / script / key combo / url).
    var payload: String

    init(id: UUID = UUID(),
         title: String = "Neuer Button",
         symbol: String = "bolt.fill",
         colorHex: String = "#3B82F6",
         actionType: ActionType = .shellScript,
         payload: String = "") {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.colorHex = colorHex
        self.actionType = actionType
        self.payload = payload
    }
}

/// The full deck definition that the Mac sends to connected clients.
struct DeckLayout: Codable, Hashable, Sendable {
    var deckName: String
    var columns: Int
    var buttons: [DeckButton]

    init(deckName: String = "ControlDock", columns: Int = 3, buttons: [DeckButton] = []) {
        self.deckName = deckName
        self.columns = columns
        self.buttons = buttons
    }
}

// MARK: - Wire messages

/// Messages sent from the iOS client to the Mac server.
enum ClientMessage: Codable, Sendable {
    case hello(deviceName: String, pin: String, protocolVersion: Int)
    case requestLayout
    case press(buttonID: UUID)
}

/// Messages sent from the Mac server to the iOS client.
enum ServerMessage: Codable, Sendable {
    case helloAck(accepted: Bool, reason: String)
    case layout(DeckLayout)
    case actionResult(buttonID: UUID, success: Bool, message: String)
}

// MARK: - Framing / codec

/// Length-prefixed JSON framing: a 4-byte big-endian UInt32 length header
/// followed by that many bytes of JSON payload.
enum MessageCodec {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let payload = try JSONEncoder().encode(value)
        var header = UInt32(payload.count).bigEndian
        var data = Data(bytes: &header, count: 4)
        data.append(payload)
        return data
    }

    static func decode<T: Decodable>(_ type: T.Type, from payload: Data) throws -> T {
        try JSONDecoder().decode(type, from: payload)
    }
}

/// Accumulates incoming bytes and yields complete frame payloads as they
/// arrive. Not thread-safe; confine to a single queue.
struct FrameBuffer {
    private var buffer = Data()

    mutating func append(_ data: Data) {
        buffer.append(data)
    }

    /// Returns the next complete frame payload, or nil if more bytes are needed.
    mutating func nextFrame() -> Data? {
        guard buffer.count >= 4 else { return nil }
        let length = buffer.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let total = 4 + Int(length)
        guard buffer.count >= total else { return nil }
        let payload = buffer.subdata(in: 4..<total)
        buffer.removeSubrange(0..<total)
        return payload
    }
}
