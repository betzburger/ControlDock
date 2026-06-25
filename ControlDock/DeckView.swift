//
//  DeckView.swift
//  ControlDock (iOS)
//
//  The live control surface: a Steam Deck-styled grid of action buttons.
//

import SwiftUI

struct DeckView: View {
    @Environment(DeckClient.self) private var client
    @State private var pressedID: UUID?

    private var layout: DeckLayout { client.layout ?? DeckLayout() }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                deckGrid(in: proxy.size)
            }
        }
        .overlay(alignment: .bottom) { feedbackToast }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(layout.deckName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Verbunden mit \(client.connectedServerName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            Spacer()
            Button {
                client.disconnect()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(DeckTheme.panel, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Grid

    private func deckGrid(in size: CGSize) -> some View {
        let columns = max(1, layout.columns)
        let spacing: CGFloat = 16
        let cols = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

        return ScrollView {
            if layout.buttons.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, minHeight: size.height * 0.7)
            } else {
                LazyVGrid(columns: cols, spacing: spacing) {
                    ForEach(layout.buttons) { button in
                        DeckButtonView(
                            button: button,
                            isPressed: pressedID == button.id
                        )
                        .onTapGesture {
                            trigger(button)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.3))
            Text("Noch keine Buttons")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))
            Text("Lege auf dem Mac in ControlDock Buttons an.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func trigger(_ button: DeckButton) {
        withAnimation(.easeOut(duration: 0.08)) { pressedID = button.id }
        client.press(button)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeIn(duration: 0.15)) {
                if pressedID == button.id { pressedID = nil }
            }
        }
    }

    // MARK: Feedback toast

    @ViewBuilder
    private var feedbackToast: some View {
        if let feedback = client.lastFeedback {
            HStack(spacing: 10) {
                Image(systemName: feedback.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(feedback.success ? .green : .orange)
                Text(feedback.message.isEmpty ? (feedback.success ? "Ausgeführt" : "Fehler") : feedback.message)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(DeckTheme.panelStroke, lineWidth: 1))
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(feedback.id)
            .task(id: feedback.id) {
                try? await Task.sleep(for: .seconds(2.2))
                withAnimation { client.lastFeedback = nil }
            }
        }
    }
}

// MARK: - Single button

struct DeckButtonView: View {
    let button: DeckButton
    let isPressed: Bool

    private var tint: Color { Color(hex: button.colorHex) }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: button.symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.8), radius: 8)
            Text(button.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.85), tint.opacity(0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                }
        }
        .shadow(color: tint.opacity(isPressed ? 0.1 : 0.45), radius: isPressed ? 4 : 14, y: isPressed ? 2 : 8)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .brightness(isPressed ? 0.08 : 0)
    }
}

#Preview {
    let client = DeckClient()
    return ZStack {
        DeckTheme.background.ignoresSafeArea()
        DeckView().environment(client)
    }
}
