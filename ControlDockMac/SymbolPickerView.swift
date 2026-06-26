//
//  SymbolPickerView.swift
//  ControlDockMac
//
//  A searchable SF Symbol picker shown in a popover. Browse by category or
//  filter by name, then tap a symbol to select it.
//

import SwiftUI

struct SymbolPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let columns = [GridItem(.adaptive(minimum: 46), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            ScrollView {
                if query.isEmpty {
                    categoryList
                } else {
                    resultGrid(SFSymbolCatalog.search(query))
                }
            }
        }
        .frame(width: 390, height: 460)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Symbol suchen …", text: $query)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
    }

    private var categoryList: some View {
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            ForEach(SFSymbolCatalog.categories) { category in
                Section {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(category.symbols, id: \.self) { symbol in
                            cell(symbol)
                        }
                    }
                    .padding(.horizontal, 12)
                } header: {
                    Text(category.name)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.bar)
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func resultGrid(_ symbols: [String]) -> some View {
        Group {
            if symbols.isEmpty {
                ContentUnavailableView.search(text: query)
                    .frame(height: 300)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(symbols, id: \.self) { cell($0) }
                }
                .padding(12)
            }
        }
    }

    private func cell(_ symbol: String) -> some View {
        Button {
            selection = symbol
            dismiss()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(
                    selection == symbol ? MacTheme.accent.opacity(0.30) : Color(nsColor: .controlBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(selection == symbol ? MacTheme.accent : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .help(symbol)
    }
}
