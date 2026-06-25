//
//  PinEntryView.swift
//  ControlDock (iOS)
//
//  Prompts for the 4-digit pairing PIN shown on the Mac.
//

import SwiftUI

struct PinEntryView: View {
    @Environment(DeckClient.self) private var client
    let reason: String
    @State private var pin: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundStyle(DeckTheme.accent)

            Text("Pairing")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text(reason)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { index in
                    let char = index < pin.count
                        ? String(Array(pin)[index]) : ""
                    Text(char)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 68)
                        .background(DeckTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(index == pin.count ? DeckTheme.accent : DeckTheme.panelStroke,
                                        lineWidth: index == pin.count ? 2 : 1)
                        )
                }
            }
            .onTapGesture { focused = true }

            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .focused($focused)
                .opacity(0.001)
                .frame(height: 1)
                .onChange(of: pin) { _, newValue in
                    pin = String(newValue.filter(\.isNumber).prefix(4))
                    if pin.count == 4 { client.retryWithPIN(pin) }
                }

            Button("Abbrechen") { client.disconnect() }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)
        }
        .padding(40)
        .onAppear { focused = true }
    }
}

#Preview {
    ZStack { DeckTheme.background.ignoresSafeArea()
        PinEntryView(reason: "PIN vom Mac eingeben")
    }.environment(DeckClient())
}
