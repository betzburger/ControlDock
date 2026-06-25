//
//  ButtonEditorView.swift
//  ControlDockMac
//
//  Editor for the currently selected deck button.
//

import SwiftUI

struct EditorPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if let index = model.buttons.firstIndex(where: { $0.id == model.selectedButtonID }) {
            ButtonEditorView(button: $model.buttons[index])
                .id(model.buttons[index].id)
        } else {
            ContentUnavailableView("Kein Button ausgewählt",
                                   systemImage: "hand.tap",
                                   description: Text("Wähle links einen Button oder erstelle einen neuen."))
        }
    }
}

struct ButtonEditorView: View {
    @Environment(AppModel.self) private var model
    @Binding var button: DeckButton

    private let suggestedSymbols = [
        "bolt.fill", "play.fill", "pause.fill", "speaker.wave.2.fill", "moon.fill",
        "sun.max.fill", "lock.fill", "camera.fill", "mic.fill", "video.fill",
        "folder.fill", "terminal.fill", "safari.fill", "envelope.fill", "music.note",
        "house.fill", "power", "command", "arrow.clockwise", "gearshape.fill",
        "star.fill", "heart.fill", "flame.fill", "bell.fill"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                preview

                section("Titel") {
                    TextField("Titel", text: $button.title)
                        .textFieldStyle(.roundedBorder)
                }

                section("Symbol") {
                    HStack {
                        TextField("SF Symbol", text: $button.symbol)
                            .textFieldStyle(.roundedBorder)
                        Image(systemName: button.symbol.isEmpty ? "questionmark" : button.symbol)
                            .frame(width: 24)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedSymbols, id: \.self) { name in
                                Button {
                                    button.symbol = name
                                } label: {
                                    Image(systemName: name)
                                        .font(.system(size: 16))
                                        .frame(width: 32, height: 32)
                                        .background(button.symbol == name ? MacTheme.accent.opacity(0.25) : Color(nsColor: .controlBackgroundColor),
                                                    in: RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                section("Farbe") {
                    ColorPicker("Button-Farbe", selection: Binding(
                        get: { Color(hex: button.colorHex) },
                        set: { button.colorHex = $0.toHex() }
                    ), supportsOpacity: false)
                }

                section("Aktion") {
                    Picker("Typ", selection: $button.actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.symbol).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    if button.actionType == .shellScript {
                        TextEditor(text: $button.payload)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 80)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                    } else {
                        TextField("", text: $button.payload)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text(button.actionType.payloadHint)
                        .font(.caption).foregroundStyle(.secondary)
                }

                Button {
                    model.test(button)
                } label: {
                    Label("Aktion testen", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var preview: some View {
        VStack(spacing: 10) {
            Image(systemName: button.symbol.isEmpty ? "questionmark" : button.symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
            Text(button.title.isEmpty ? "Titel" : button.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(width: 130, height: 130)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: button.colorHex).opacity(0.9),
                                              Color(hex: button.colorHex).opacity(0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.25)))
        }
        .shadow(color: Color(hex: button.colorHex).opacity(0.4), radius: 14, y: 8)
        .frame(maxWidth: .infinity)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary).textCase(.uppercase)
            content()
        }
    }
}
