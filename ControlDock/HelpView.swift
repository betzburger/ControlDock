//
//  HelpView.swift
//  ControlDock (iOS)
//
//  A polished, card-based help screen presented as a sheet.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero

                    HelpCard(icon: "wifi", tint: Color(hex: "#3B82F6"),
                             title: "Verbinden") {
                        Text("Stelle sicher, dass iPhone und Mac im **selben WLAN** sind und die ControlDock-App auf dem Mac läuft.")
                        HelpSteps([
                            "Öffne ControlDock auf dem Mac.",
                            "Tippe hier auf deinen Mac in der Liste.",
                            "Gib die 4-stellige PIN ein, die der Mac anzeigt."
                        ])
                    }

                    HelpCard(icon: "hand.tap.fill", tint: Color(hex: "#22C55E"),
                             title: "Steuern") {
                        Text("Tippe auf eine Kachel, um die hinterlegte Aktion sofort auf dem Mac auszulösen. Ein kurzes haptisches Feedback und eine Rückmeldung am unteren Rand bestätigen die Ausführung.")
                        Text("Das Raster passt sich automatisch an die Anzahl der Buttons und an Hoch-/Querformat an.")
                    }

                    HelpCard(icon: "macbook.and.iphone", tint: Color(hex: "#A855F7"),
                             title: "Buttons kommen vom Mac") {
                        Text("Welche Buttons es gibt und was sie tun, legst du in der **Mac-App** fest – Name, Symbol, Farbe und Aktion. Änderungen erscheinen automatisch hier auf dem iPhone.")
                    }

                    HelpCard(icon: "lock.shield.fill", tint: Color(hex: "#F59E0B"),
                             title: "PIN & Sicherheit") {
                        Text("Die PIN verhindert, dass fremde Geräte im Netzwerk Aktionen auslösen. Sie wird auf dem Mac angezeigt und kann dort jederzeit neu erzeugt werden. Die Verbindung bleibt vollständig im lokalen Netzwerk.")
                    }

                    HelpCard(icon: "wrench.and.screwdriver.fill", tint: Color(hex: "#06B6D4"),
                             title: "Problembehebung") {
                        HelpBullets([
                            ("Mac wird nicht gefunden", "Gleiches WLAN? Mac-App geöffnet? Ggf. eingehende Verbindungen in der macOS-Firewall erlauben."),
                            ("PIN abgelehnt", "Prüfe die aktuell auf dem Mac angezeigte PIN – sie kann neu erzeugt worden sein."),
                            ("Aktion ohne Wirkung", "Tastendrücke benötigen auf dem Mac die Bedienungshilfen-Berechtigung. Erteile sie in der Mac-App.")
                        ])
                    }
                }
                .padding(20)
            }
            .background(DeckTheme.background.ignoresSafeArea())
            .navigationTitle("Hilfe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(DeckTheme.accent)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(red: 0.08, green: 0.09, blue: 0.13), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 44))
                .foregroundStyle(DeckTheme.accent)
                .shadow(color: DeckTheme.accent.opacity(0.6), radius: 16)
            Text("So funktioniert ControlDock")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Dein iPhone wird zur Fernbedienung für den Mac – tippe Kacheln, um Programme, Skripte, Tastendrücke und Links auszulösen.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Building blocks

struct HelpCard<Content: View>: View {
    let icon: String
    let tint: Color
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 10) {
                content
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .tint(DeckTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DeckTheme.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(DeckTheme.panelStroke, lineWidth: 1))
    }
}

struct HelpSteps: View {
    let steps: [String]
    init(_ steps: [String]) { self.steps = steps }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(DeckTheme.accent, in: Circle())
                    Text(step)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

struct HelpBullets: View {
    let items: [(String, String)]
    init(_ items: [(String, String)]) { self.items = items }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Label(item.0, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(item.1)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.leading, 26)
                }
            }
        }
    }
}

#Preview {
    HelpView()
}
