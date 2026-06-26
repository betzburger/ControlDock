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
    @State private var showHelp = false

    private var layout: DeckLayout { client.layout ?? DeckLayout() }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                deckGrid(in: proxy.size)
            }
        }
        .overlay(alignment: .bottom) { feedbackToast }
        .sheet(isPresented: $showHelp) { HelpView() }
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
            HStack(spacing: 10) {
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(DeckTheme.panel, in: Circle())
                }
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Adaptive grid

    private func deckGrid(in size: CGSize) -> some View {
        Group {
            if layout.buttons.isEmpty {
                emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let gap: CGFloat = 14
                let cols = columnCount(for: layout.buttons.count, in: size)
                let rowCount = Int(ceil(Double(layout.buttons.count) / Double(cols)))
                let tileW = (size.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
                let tileH = (size.height - gap * CGFloat(rowCount + 1)) / CGFloat(rowCount)

                VStack(spacing: gap) {
                    ForEach(Array(rows(of: layout.buttons, columns: cols).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: gap) {
                            ForEach(row) { button in
                                DeckButtonView(button: button, isPressed: pressedID == button.id)
                                    .frame(width: tileW, height: tileH)
                                    .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .onTapGesture { trigger(button) }
                            }
                        }
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        }
    }

    /// Splits buttons into rows of at most `columns` items.
    private func rows(of buttons: [DeckButton], columns: Int) -> [[DeckButton]] {
        stride(from: 0, to: buttons.count, by: columns).map {
            Array(buttons[$0 ..< min($0 + columns, buttons.count)])
        }
    }

    /// Picks a balanced column count so tiles fill the screen, adapting to
    /// orientation: portrait favours more rows, landscape favours more columns.
    private func columnCount(for count: Int, in size: CGSize) -> Int {
        guard count > 1 else { return 1 }
        let base = max(1, Int(Double(count).squareRoot().rounded()))
        let columns: Int
        if size.width <= size.height {
            columns = base                                   // portrait: sqrt columns
        } else {
            columns = Int(ceil(Double(count) / Double(base))) // landscape: sqrt rows
        }
        return min(max(columns, 1), count)
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
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let iconSize = max(20, side * 0.30)
            let titleSize = min(22, max(12, side * 0.13))
            let corner = min(28, max(14, side * 0.16))

            VStack(spacing: side * 0.09) {
                Image(systemName: button.symbol)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: tint.opacity(0.8), radius: iconSize * 0.25)
                Text(button.title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .padding(side * 0.12)
            .frame(width: geo.size.width, height: geo.size.height)
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.85), tint.opacity(0.45)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    }
            }
            .shadow(color: tint.opacity(isPressed ? 0.1 : 0.45), radius: isPressed ? 4 : 14, y: isPressed ? 2 : 8)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .brightness(isPressed ? 0.08 : 0)
        }
    }
}

#Preview {
    let client = DeckClient()
    return ZStack {
        DeckTheme.background.ignoresSafeArea()
        DeckView().environment(client)
    }
}
