//
//  ActionExecutor.swift
//  ControlDockMac
//
//  Executes the action associated with a deck button. Runs synchronously;
//  callers should invoke it off the main thread.
//

import Foundation

enum ActionExecutor {

    static func execute(_ button: DeckButton) -> (success: Bool, message: String) {
        let payload = button.payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return (false, "Keine Aktion hinterlegt") }

        switch button.actionType {
        case .launchApp:   return launchApp(payload)
        case .shellScript: return runShell(payload)
        case .keystroke:   return KeystrokeSimulator.send(payload)
        case .openURL:     return openURL(payload)
        }
    }

    // MARK: - App launching

    private static func launchApp(_ value: String) -> (Bool, String) {
        // A path (or .app bundle): open directly.
        if value.hasPrefix("/") || value.hasPrefix("~") {
            let expanded = (value as NSString).expandingTildeInPath
            let result = runProcess("/usr/bin/open", [expanded])
            return result.status == 0 ? (true, "Geöffnet: \(value)") : (false, result.output)
        }
        // Try by application name first.
        let byName = runProcess("/usr/bin/open", ["-a", value])
        if byName.status == 0 { return (true, "Gestartet: \(value)") }
        // Fall back to bundle identifier.
        if value.contains(".") {
            let byBundle = runProcess("/usr/bin/open", ["-b", value])
            if byBundle.status == 0 { return (true, "Gestartet: \(value)") }
        }
        return (false, "App nicht gefunden: \(value)")
    }

    // MARK: - Shell

    private static func runShell(_ command: String) -> (Bool, String) {
        let result = runProcess("/bin/zsh", ["-lc", command])
        let trimmed = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.status == 0 {
            return (true, trimmed.isEmpty ? "Befehl ausgeführt" : String(trimmed.prefix(200)))
        }
        return (false, trimmed.isEmpty ? "Exit-Code \(result.status)" : String(trimmed.prefix(200)))
    }

    // MARK: - URL

    private static func openURL(_ value: String) -> (Bool, String) {
        var urlString = value
        if !urlString.contains("://") && !urlString.hasPrefix("mailto:") {
            urlString = "https://" + urlString
        }
        let result = runProcess("/usr/bin/open", [urlString])
        return result.status == 0 ? (true, "Geöffnet: \(urlString)") : (false, "URL ungültig: \(value)")
    }

    // MARK: - Process helper

    private static func runProcess(_ launchPath: String, _ arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
}
