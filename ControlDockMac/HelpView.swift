//
//  HelpView.swift
//  ControlDockMac
//
//  A dedicated, well-structured help window with a topic sidebar and richly
//  formatted content for each topic.
//

import SwiftUI

enum HelpTopic: String, CaseIterable, Identifiable {
    case start, buttons, actions, pairing, permissions, troubleshooting, tips

    var id: String { rawValue }

    var title: String {
        switch self {
        case .start:           return "Erste Schritte"
        case .buttons:         return "Buttons erstellen"
        case .actions:         return "Aktionstypen"
        case .pairing:         return "Pairing & Sicherheit"
        case .permissions:     return "Berechtigungen"
        case .troubleshooting: return "Problembehebung"
        case .tips:            return "Tipps & Tricks"
        }
    }

    var icon: String {
        switch self {
        case .start:           return "flag.checkered"
        case .buttons:         return "square.grid.2x2"
        case .actions:         return "bolt.fill"
        case .pairing:         return "lock.shield"
        case .permissions:     return "checkmark.seal"
        case .troubleshooting: return "wrench.and.screwdriver"
        case .tips:            return "lightbulb"
        }
    }

    var tint: Color {
        switch self {
        case .start:           return Color(hex: "#3B82F6")
        case .buttons:         return Color(hex: "#22C55E")
        case .actions:         return Color(hex: "#F59E0B")
        case .pairing:         return Color(hex: "#A855F7")
        case .permissions:     return Color(hex: "#06B6D4")
        case .troubleshooting: return Color(hex: "#EF4444")
        case .tips:            return Color(hex: "#EC4899")
        }
    }
}

struct HelpView: View {
    @State private var selection: HelpTopic? = .start

    var body: some View {
        NavigationSplitView {
            List(HelpTopic.allCases, selection: $selection) { topic in
                Label(topic.title, systemImage: topic.icon)
                    .tag(topic)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .navigationTitle("Hilfe")
        } detail: {
            ScrollView {
                HelpContent(topic: selection ?? .start)
                    .padding(28)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 760, minHeight: 540)
    }
}

// MARK: - Content per topic

private struct HelpContent: View {
    let topic: HelpTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HelpHeader(topic: topic)
            switch topic {
            case .start:           startContent
            case .buttons:         buttonsContent
            case .actions:         actionsContent
            case .pairing:         pairingContent
            case .permissions:     permissionsContent
            case .troubleshooting: troubleshootingContent
            case .tips:            tipsContent
            }
        }
    }

    // MARK: Erste Schritte

    private var startContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("ControlDock verwandelt dein iPhone oder iPad in eine Steuerfläche für diesen Mac. Du tippst auf eine Kachel – der Mac führt die zugehörige Aktion aus: ein Programm starten, einen Shell-Befehl ausführen, einen Tastendruck simulieren oder einen Link öffnen.")
            HelpSection("So gelingt der Start") {
                HelpNumbered([
                    "Diese Mac-App geöffnet lassen – der Server startet automatisch und ist im Bereich „Verbindung“ als aktiv markiert.",
                    "iPhone/iPad ins selbe WLAN bringen und die ControlDock-App dort öffnen.",
                    "Den Mac in der Geräteliste antippen und die angezeigte PIN eingeben.",
                    "Fertig – Buttons, die du hier anlegst, erscheinen sofort auf dem Gerät."
                ])
            }
            HelpCallout(icon: "info.circle.fill", tint: .blue,
                        text: "Mac und Mobilgerät müssen sich im selben lokalen Netzwerk befinden. Es werden keine Daten ins Internet gesendet.")
        }
    }

    // MARK: Buttons

    private var buttonsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("Im Hauptfenster verwaltest du dein Deck. Jeder Button besteht aus Titel, Symbol, Farbe und einer Aktion.")
            HelpSection("Button anlegen & bearbeiten") {
                HelpBullets([
                    "Unten in der Liste auf **+ Button** klicken.",
                    "Rechts im Editor **Titel**, **Symbol** und **Farbe** wählen.",
                    "Über **Symbol auswählen …** den durchsuchbaren Symbol-Katalog öffnen.",
                    "Aktionstyp festlegen und das passende Feld ausfüllen.",
                    "Mit **Aktion testen** direkt am Mac ausprobieren."
                ])
            }
            HelpSection("Anordnen & löschen") {
                HelpBullets([
                    "Buttons in der Liste per Drag & Drop neu anordnen – die Reihenfolge bestimmt die Anordnung auf dem Gerät.",
                    "Zum Entfernen den Button auswählen und auf das **Papierkorb**-Symbol klicken."
                ])
            }
            HelpCallout(icon: "sparkles", tint: .green,
                        text: "Das mobile Deck verteilt die Kacheln automatisch über den ganzen Bildschirm – je mehr Buttons, desto feiner das Raster. Eine Spaltenangabe ist nicht nötig.")
        }
    }

    // MARK: Aktionstypen

    private var actionsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("ControlDock kennt vier Aktionstypen. Den Typ wählst du im Editor unter „Aktion“.")

            HelpActionBlock(icon: "app.dashed", title: "App starten",
                            text: "Öffnet ein Programm. Erlaubt sind App-Name, Bundle-ID oder ein vollständiger Pfad.") {
                HelpCode(["Safari", "Visual Studio Code",
                          "/System/Applications/Music.app", "com.apple.Terminal"])
            }

            HelpActionBlock(icon: "terminal", title: "Shell-Befehl",
                            text: "Führt einen Befehl in der zsh-Login-Shell aus. Mehrere Befehle mit && oder Zeilenumbrüchen kombinieren.") {
                HelpCode(["say \"Hallo Peter\"",
                          "open -a Music && echo fertig",
                          "osascript -e 'display notification \"Fertig\"'"])
            }

            HelpActionBlock(icon: "keyboard", title: "Tastendruck",
                            text: "Simuliert eine Tastenkombination. Modifier mit + verbinden. Benötigt die Bedienungshilfen-Berechtigung.") {
                HelpCode(["cmd+shift+4", "ctrl+cmd+q", "cmd+space", "f11"])
                HelpText("Modifier: cmd, shift, alt/option, ctrl, fn. Tasten: Buchstaben, Zahlen, Pfeile (left/right/up/down), f1–f12, space, return, esc, tab, delete u. a.")
            }

            HelpActionBlock(icon: "link", title: "URL öffnen",
                            text: "Öffnet eine Adresse im Standardbrowser oder einen Deep-Link. Fehlt das Schema, wird https:// ergänzt.") {
                HelpCode(["https://apple.com", "mailto:team@example.com", "raycast://confetti"])
            }
        }
    }

    // MARK: Pairing

    private var pairingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("Da ControlDock echte Aktionen auf dem Mac ausführt, ist die Verbindung durch eine PIN geschützt.")
            HelpSection("PIN") {
                HelpBullets([
                    "Die aktuelle PIN steht im Bereich **Verbindung** in der Seitenleiste.",
                    "Beim ersten Verbinden eines Geräts wird sie einmalig abgefragt.",
                    "Mit dem **Aktualisieren**-Symbol erzeugst du jederzeit eine neue PIN.",
                    "Über **PIN erforderlich** lässt sich die Abfrage abschalten (nur in vertrauenswürdigen Netzwerken empfohlen)."
                ])
            }
            HelpCallout(icon: "lock.shield.fill", tint: .purple,
                        text: "Die Kommunikation läuft ausschließlich im lokalen Netzwerk über Bonjour. Verbundene Geräte siehst du live im Bereich „Geräte“.")
        }
    }

    // MARK: Berechtigungen

    private var permissionsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("Für **Tastendruck**-Aktionen muss macOS ControlDock erlauben, Tastatureingaben zu senden. Andere Aktionstypen benötigen diese Berechtigung nicht.")
            HelpSection("Bedienungshilfen aktivieren") {
                HelpNumbered([
                    "Sobald ein Tastendruck-Button existiert, erscheint im Hauptfenster ein Hinweisbanner mit der Schaltfläche **Erlauben**.",
                    "Alternativ: Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen.",
                    "ControlDock in der Liste aktivieren.",
                    "Danach funktionieren Tastendrücke sofort – kein Neustart nötig."
                ])
            }
            HelpCallout(icon: "checkmark.seal.fill", tint: .teal,
                        text: "Die Berechtigung wird nur lokal von macOS verwaltet. ControlDock sendet keine Tastatureingaben an Dritte.")
        }
    }

    // MARK: Problembehebung

    private var troubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpProblem(question: "Das iPhone findet den Mac nicht",
                        answers: [
                            "Sind beide Geräte im selben WLAN?",
                            "Läuft diese Mac-App und ist der Server als aktiv markiert?",
                            "Eingehende Verbindungen in den Systemeinstellungen → Netzwerk → Firewall für ControlDock erlauben.",
                            "Manche Gäste-/Firmen-WLANs blockieren Bonjour zwischen Geräten."
                        ])
            HelpProblem(question: "Die PIN wird abgelehnt",
                        answers: [
                            "Vergleiche die Eingabe mit der aktuell angezeigten PIN.",
                            "Wurde die PIN zwischenzeitlich neu erzeugt? Dann erneut eingeben."
                        ])
            HelpProblem(question: "Ein Tastendruck passiert nicht",
                        answers: [
                            "Bedienungshilfen-Berechtigung erteilt? Siehe „Berechtigungen“.",
                            "Ist die Zieltaste korrekt geschrieben (z. B. cmd statt command-Symbol)?"
                        ])
            HelpProblem(question: "Ein Shell-Befehl schlägt fehl",
                        answers: [
                            "Teste den Befehl zunächst im Terminal.",
                            "Verwende absolute Pfade, falls Programme nicht gefunden werden.",
                            "Die Rückmeldung auf dem iPhone und das Aktivitätsprotokoll zeigen die Fehlermeldung."
                        ])
        }
    }

    // MARK: Tipps

    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HelpText("Mit Shell-Befehlen lässt sich nahezu alles automatisieren. Ein paar Ideen:")
            HelpSection("Nützliche Befehle") {
                HelpCode([
                    "pmset displaysleepnow            # Bildschirm sperren",
                    "osascript -e 'set volume 0'      # Stummschalten",
                    "open -a \"Do Not Disturb\"         # Fokus umschalten",
                    "shortcuts run \"Mein Kurzbefehl\"  # Kurzbefehle starten"
                ])
            }
            HelpSection("Kombinationen") {
                HelpBullets([
                    "Mehrere Schritte mit **&&** verketten.",
                    "Mit **osascript** AppleScript für App-Steuerung nutzen.",
                    "Mit **shortcuts run** vorhandene Kurzbefehle einbinden.",
                    "Farben und Symbole konsequent vergeben – das erleichtert das Treffen auf dem Gerät."
                ])
            }
        }
    }
}

// MARK: - Building blocks

private struct HelpHeader: View {
    let topic: HelpTopic
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: topic.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(topic.tint.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            Text(topic.title)
                .font(.largeTitle.bold())
        }
        .padding(.bottom, 4)
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title3.bold())
            content
        }
    }
}

private struct HelpText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(.init(text))
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HelpBullets: View {
    let items: [String]
    init(_ items: [String]) { self.items = items }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.tertiary)
                    Text(.init(item)).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct HelpNumbered: View {
    let items: [String]
    init(_ items: [String]) { self.items = items }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold()).foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.accentColor, in: Circle())
                    Text(.init(item)).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct HelpCode: View {
    let lines: [String]
    init(_ lines: [String]) { self.lines = lines }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
    }
}

private struct HelpCallout: View {
    let icon: String
    let tint: Color
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(tint).font(.title3)
            Text(.init(text)).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.25), lineWidth: 1))
    }
}

private struct HelpActionBlock<Content: View>: View {
    let icon: String
    let title: String
    let text: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
            HelpText(text)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
    }
}

private struct HelpProblem: View {
    let question: String
    let answers: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(question, systemImage: "questionmark.circle.fill")
                .font(.headline)
            HelpBullets(answers)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
    }
}

#Preview {
    HelpView()
}
