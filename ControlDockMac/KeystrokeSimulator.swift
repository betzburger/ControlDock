//
//  KeystrokeSimulator.swift
//  ControlDockMac
//
//  Parses key combinations like "cmd+shift+4" and posts them as system-wide
//  keyboard events via CoreGraphics. Also supports the special media/hardware
//  keys above the function row (volume, brightness, playback, keyboard light)
//  via NX system-defined events. Requires Accessibility permission.
//

import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

enum KeystrokeSimulator {

    /// Whether the app is allowed to post keyboard events (Accessibility).
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Opens System Settings → Accessibility and prompts the user to grant access.
    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Sends the key combination described by `combo` (e.g. "cmd+shift+4").
    static func send(_ combo: String) -> (success: Bool, message: String) {
        guard isTrusted else {
            return (false, "Bedienungshilfen-Berechtigung fehlt")
        }
        let tokens = combo.lowercased()
            .split(whereSeparator: { $0 == "+" || $0 == " " })
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return (false, "Leere Tastenkombination") }

        var flags: CGEventFlags = []
        var keyCode: CGKeyCode?
        var mediaKey: Int32?

        for token in tokens {
            if let modifier = modifiers[token] {
                flags.insert(modifier)
            } else if let media = mediaKeys[token] {
                mediaKey = media
            } else if let code = keyCodes[token] {
                keyCode = code
            } else {
                return (false, "Unbekannte Taste: \(token)")
            }
        }

        // Special media / hardware keys (volume, brightness, playback …)
        if let mediaKey {
            return sendMediaKey(mediaKey, flags: flags)
        }

        guard let code = keyCode else {
            return (false, "Keine Haupttaste angegeben")
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else {
            return (false, "Event konnte nicht erstellt werden")
        }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return (true, "Tastendruck gesendet")
    }

    /// Posts a special media/hardware key (volume, brightness, playback, …) as
    /// an NX system-defined event, the way the keys above the function row work.
    private static func sendMediaKey(_ key: Int32, flags: CGEventFlags) -> (success: Bool, message: String) {
        func post(keyDown: Bool) -> Bool {
            let state = keyDown ? 0xA : 0xB           // NX key down / up state
            let data1 = (Int(key) << 16) | (state << 8)
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,                            // NX_SUBTYPE_AUX_CONTROL_BUTTONS
                data1: data1,
                data2: -1
            ), let cgEvent = event.cgEvent else { return false }
            cgEvent.flags = flags
            cgEvent.post(tap: .cghidEventTap)
            return true
        }
        guard post(keyDown: true), post(keyDown: false) else {
            return (false, "Medientaste konnte nicht gesendet werden")
        }
        return (true, "Medientaste gesendet")
    }

    // MARK: - Tables

    /// Special keys above the function row, delivered as NX system events.
    /// Values are the NX_KEYTYPE_* constants from IOKit's ev_keymap.h.
    private static let mediaKeys: [String: Int32] = [
        "volumeup": 0, "volup": 0, "lauter": 0,
        "volumedown": 1, "voldown": 1, "leiser": 1,
        "mute": 7, "stumm": 7,
        "brightnessup": 2, "brightup": 2, "heller": 2,
        "brightnessdown": 3, "brightdown": 3, "dunkler": 3,
        "play": 16, "playpause": 16, "pause": 16,
        "next": 17, "nexttrack": 17, "weiter": 17,
        "previous": 18, "prev": 18, "prevtrack": 18, "zurueck": 18,
        "fastforward": 19, "forward": 19,
        "rewind": 20,
        "keyboardbrightnessup": 21, "kbbrightup": 21,
        "keyboardbrightnessdown": 22, "kbbrightdown": 22,
        "keyboardbrightnesstoggle": 23, "kbbrighttoggle": 23,
        "eject": 14
    ]

    private static let modifiers: [String: CGEventFlags] = [
        "cmd": .maskCommand, "command": .maskCommand, "⌘": .maskCommand,
        "shift": .maskShift, "⇧": .maskShift,
        "alt": .maskAlternate, "option": .maskAlternate, "opt": .maskAlternate, "⌥": .maskAlternate,
        "ctrl": .maskControl, "control": .maskControl, "⌃": .maskControl,
        "fn": .maskSecondaryFn
    ]

    private static let keyCodes: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26,
        "-": 27, "8": 28, "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35,
        "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45,
        "m": 46, ".": 47, "`": 50,
        "return": 36, "enter": 36, "tab": 48, "space": 49, "delete": 51, "backspace": 51,
        "escape": 53, "esc": 53,
        "left": 123, "right": 124, "down": 125, "up": 126,
        "home": 115, "end": 119, "pageup": 116, "pagedown": 121, "forwarddelete": 117,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97, "f7": 98, "f8": 100,
        "f9": 101, "f10": 109, "f11": 103, "f12": 111
    ]
}
