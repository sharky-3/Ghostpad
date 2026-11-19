import SwiftUI

enum EditorSelection: Hashable {
    case key(UUID)
    case cell(column: Int, row: Int)
}

struct LayoutSettingsView: View {
    @Bindable var settings: SettingsStore
    let aspectRatio: Double

    @State private var selection: EditorSelection?

    var body: some View {
        let layout = settings.layout
        Form {
            Section {
                Picker("Layout", selection: $settings.layoutID) {
                    Section("Built-in") {
                        ForEach(KeypadLayout.builtIn) { item in
                            Text(item.name).tag(item.id)
                        }
                    }
                    if !settings.customLayouts.isEmpty {
                        Section("Custom") {
                            ForEach(settings.customLayouts) { item in
                                Text(item.name).tag(item.id)
                            }
                        }
                    }
                }
                HStack {
                    Button("New Layout") {
                        settings.createLayout(from: nil)
                    }
                    Button("Duplicate") {
                        settings.createLayout(from: layout)
                    }
                    Spacer()
                    if !layout.isBuiltIn {
                        Button("Delete", role: .destructive) {
                            settings.deleteLayout(id: layout.id)
                        }
                    }
                }
            }
            Section {
                LayoutEditorGrid(layout: layout, selection: $selection, isEditable: !layout.isBuiltIn)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            } footer: {
                Text(layout.isBuiltIn ? "Built-in layouts can’t be changed. Duplicate one to make it your own." : "Select a key or an empty cell to edit it.")
            }
            if !layout.isBuiltIn {
                Section("Grid") {
                    TextField("Name", text: binding(\.name))
                    Stepper("Columns: \(layout.columns)", value: gridBinding(columns: true), in: KeypadLayout.columnRange)
                    Stepper("Rows: \(layout.rows)", value: gridBinding(columns: false), in: KeypadLayout.rowRange)
                }
                keySection(layout)
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings.layoutID) {
            selection = nil
        }
    }

    @ViewBuilder
    private func keySection(_ layout: KeypadLayout) -> some View {
        switch selection {
        case .key(let id):
            if let key = layout.keys.first(where: { $0.id == id }) {
                Section("Key") {
                    Picker("Key", selection: actionBinding(for: key)) {
                        actionOptions
                    }
                    Stepper("Width: \(key.columnSpan)", value: spanBinding(for: key, columns: true), in: 1...layout.maximumColumnSpan(for: key))
                    Stepper("Height: \(key.rowSpan)", value: spanBinding(for: key, columns: false), in: 1...layout.maximumRowSpan(for: key))
                    Button("Remove Key", role: .destructive) {
                        mutate { $0.keys.removeAll { $0.id == id } }
                        selection = .cell(column: key.column, row: key.row)
                    }
                }
            }
        case .cell(let column, let row):
            if column < layout.columns, row < layout.rows, layout.key(column: column, row: row) == nil {
                Section("Empty Cell") {
                    Picker("Key", selection: newKeyBinding(column: column, row: row)) {
                        Text("None").tag(KeyAction?.none)
                        actionOptions
                    }
                }
            }
        case nil:
            EmptyView()
        }
    }

    private var actionOptions: some View {
        ForEach(KeyAction.Group.allCases, id: \.self) { group in
            Section(group.rawValue) {
                ForEach(KeyAction.allCases.filter { $0.group == group }) { action in
                    Text(action.title).tag(Optional(action))
                }
            }
        }
    }

    private func mutate(_ change: (inout KeypadLayout) -> Void) {
        var layout = settings.layout
        change(&layout)
        settings.update(layout)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<KeypadLayout, Value>) -> Binding<Value> {
        Binding(get: { settings.layout[keyPath: keyPath] }, set: { value in mutate { $0[keyPath: keyPath] = value } })
    }

    private func gridBinding(columns: Bool) -> Binding<Int> {
        Binding(get: { columns ? settings.layout.columns : settings.layout.rows }, set: { value in
            mutate { $0.resize(columns: columns ? value : $0.columns, rows: columns ? $0.rows : value) }
        })
    }

    private func actionBinding(for key: KeypadKey) -> Binding<KeyAction?> {
        Binding(get: { key.action }, set: { action in
            guard let action else { return }
            mutate { layout in
                guard let index = layout.keys.firstIndex(where: { $0.id == key.id }) else { return }
                layout.keys[index].action = action
            }
        })
    }

    private func spanBinding(for key: KeypadKey, columns: Bool) -> Binding<Int> {
        Binding(get: { columns ? key.columnSpan : key.rowSpan }, set: { value in
            mutate { layout in
                guard let index = layout.keys.firstIndex(where: { $0.id == key.id }) else { return }
                if columns {
                    layout.keys[index].columnSpan = value
                } else {
                    layout.keys[index].rowSpan = value
                }
            }
        })
    }

    private func newKeyBinding(column: Int, row: Int) -> Binding<KeyAction?> {
        Binding(get: { nil }, set: { action in
            guard let action else { return }
            let key = KeypadKey(action: action, column: column, row: row)
            mutate { $0.keys.append(key) }
            selection = .key(key.id)
        })
    }
}

struct LayoutEditorGrid: View {
    private struct Cell: Hashable {
        let column: Int
        let row: Int
    }

    let layout: KeypadLayout
    @Binding var selection: EditorSelection?
    let isEditable: Bool

    private let spacing: CGFloat = 6
    private let cornerRadius: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cell = CGSize(width: max((size.width - spacing * CGFloat(layout.columns - 1)) / CGFloat(layout.columns), 1), height: max((size.height - spacing * CGFloat(layout.rows - 1)) / CGFloat(layout.rows), 1))
            ZStack(alignment: .topLeading) {
                if isEditable {
                    ForEach(emptyCells, id: \.self) { item in
                        let isSelected = selection == .cell(column: item.column, row: item.row)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : .primary.opacity(0.14), style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [3, 3]))
                            .frame(width: cell.width, height: cell.height)
                            .contentShape(Rectangle())
                            .onTapGesture { selection = .cell(column: item.column, row: item.row) }
                            .offset(x: CGFloat(item.column) * (cell.width + spacing), y: CGFloat(item.row) * (cell.height + spacing))
                    }
                }
                ForEach(layout.keys) { key in
                    KeycapView(key: key, state: .idle, fontSize: max(min(cell.height * 0.4, cell.width * 0.4, 22), 1), cornerRadius: cornerRadius)
                        .overlay {
                            if selection == .key(key.id) {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            }
                        }
                        .frame(width: span(cell.width, key.columnSpan), height: span(cell.height, key.rowSpan))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isEditable {
                                selection = .key(key.id)
                            }
                        }
                        .offset(x: CGFloat(key.column) * (cell.width + spacing), y: CGFloat(key.row) * (cell.height + spacing))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .animation(.smooth(duration: 0.2), value: layout)
        }
    }

    private var emptyCells: [Cell] {
        (0..<layout.rows).flatMap { row in
            (0..<layout.columns).compactMap { column in
                layout.key(column: column, row: row) == nil ? Cell(column: column, row: row) : nil
            }
        }
    }

    private func span(_ length: CGFloat, _ count: Int) -> CGFloat {
        length * CGFloat(count) + spacing * CGFloat(count - 1)
    }
}
