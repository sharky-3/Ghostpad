import Carbon.HIToolbox
import CoreGraphics

nonisolated struct KeypadKey: Identifiable, Hashable, Sendable {
    enum Kind: Sendable {
        case digit
        case function
    }

    let id: String
    let label: String
    let systemImage: String?
    let keyCode: CGKeyCode
    let kind: Kind
    let column: Int
    let row: Int
    let columnSpan: Int
    let rowSpan: Int

    var isWord: Bool {
        label.count > 1
    }

    static func digit(_ label: String, _ code: Int, _ column: Int, _ row: Int, span: Int = 1) -> KeypadKey {
        KeypadKey(id: label, label: label, systemImage: nil, keyCode: CGKeyCode(code), kind: .digit, column: column, row: row, columnSpan: span, rowSpan: 1)
    }

    static func function(_ id: String, _ label: String, _ code: Int, _ column: Int, _ row: Int, symbol: String? = nil, rowSpan: Int = 1) -> KeypadKey {
        KeypadKey(id: id, label: label, systemImage: symbol, keyCode: CGKeyCode(code), kind: .function, column: column, row: row, columnSpan: 1, rowSpan: rowSpan)
    }
}

nonisolated struct KeypadLayout: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let columns: Int
    let rows: Int
    let keys: [KeypadKey]

    func key(at point: CGPoint) -> KeypadKey? {
        let column = min(max(Int(point.x * Double(columns)), 0), columns - 1)
        let row = min(max(Int(point.y * Double(rows)), 0), rows - 1)
        return keys.first { (column >= $0.column && column < $0.column + $0.columnSpan) && (row >= $0.row && row < $0.row + $0.rowSpan) }
    }

    static let standard = KeypadLayout(id: "standard", name: "Standard", columns: 5, rows: 4, keys: [
        .digit("7", kVK_ANSI_Keypad7, 0, 0),
        .digit("8", kVK_ANSI_Keypad8, 1, 0),
        .digit("9", kVK_ANSI_Keypad9, 2, 0),
        .function("divide", "÷", kVK_ANSI_KeypadDivide, 3, 0),
        .function("delete", "⌫", kVK_Delete, 4, 0, symbol: "delete.left"),
        .digit("4", kVK_ANSI_Keypad4, 0, 1),
        .digit("5", kVK_ANSI_Keypad5, 1, 1),
        .digit("6", kVK_ANSI_Keypad6, 2, 1),
        .function("multiply", "×", kVK_ANSI_KeypadMultiply, 3, 1),
        .function("clear", "Clear", kVK_ANSI_KeypadClear, 4, 1),
        .digit("1", kVK_ANSI_Keypad1, 0, 2),
        .digit("2", kVK_ANSI_Keypad2, 1, 2),
        .digit("3", kVK_ANSI_Keypad3, 2, 2),
        .function("minus", "−", kVK_ANSI_KeypadMinus, 3, 2),
        .function("equals", "=", kVK_ANSI_KeypadEquals, 4, 2),
        .digit("0", kVK_ANSI_Keypad0, 0, 3, span: 2),
        .digit(".", kVK_ANSI_KeypadDecimal, 2, 3),
        .function("plus", "+", kVK_ANSI_KeypadPlus, 3, 3),
        .function("enter", "Enter", kVK_ANSI_KeypadEnter, 4, 3, symbol: "return")
    ])

    static let classic = KeypadLayout(id: "classic", name: "Classic", columns: 4, rows: 5, keys: [
        .function("clear", "Clear", kVK_ANSI_KeypadClear, 0, 0),
        .function("equals", "=", kVK_ANSI_KeypadEquals, 1, 0),
        .function("divide", "÷", kVK_ANSI_KeypadDivide, 2, 0),
        .function("multiply", "×", kVK_ANSI_KeypadMultiply, 3, 0),
        .digit("7", kVK_ANSI_Keypad7, 0, 1),
        .digit("8", kVK_ANSI_Keypad8, 1, 1),
        .digit("9", kVK_ANSI_Keypad9, 2, 1),
        .function("minus", "−", kVK_ANSI_KeypadMinus, 3, 1),
        .digit("4", kVK_ANSI_Keypad4, 0, 2),
        .digit("5", kVK_ANSI_Keypad5, 1, 2),
        .digit("6", kVK_ANSI_Keypad6, 2, 2),
        .function("plus", "+", kVK_ANSI_KeypadPlus, 3, 2),
        .digit("1", kVK_ANSI_Keypad1, 0, 3),
        .digit("2", kVK_ANSI_Keypad2, 1, 3),
        .digit("3", kVK_ANSI_Keypad3, 2, 3),
        .function("enter", "Enter", kVK_ANSI_KeypadEnter, 3, 3, symbol: "return", rowSpan: 2),
        .digit("0", kVK_ANSI_Keypad0, 0, 4, span: 2),
        .digit(".", kVK_ANSI_KeypadDecimal, 2, 4)
    ])

    static let all = [standard, classic]
}
