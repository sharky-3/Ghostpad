import CoreGraphics
import Foundation

nonisolated struct KeypadKey: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var action: KeyAction
    var column: Int
    var row: Int
    var columnSpan = 1
    var rowSpan = 1

    var label: String {
        action.label
    }

    var systemImage: String? {
        action.systemImage
    }

    var isWord: Bool {
        systemImage == nil && label.count > 1
    }

    func covers(column: Int, row: Int) -> Bool {
        column >= self.column && column < self.column + columnSpan && row >= self.row && row < self.row + rowSpan
    }

    func overlaps(_ other: KeypadKey) -> Bool {
        column < other.column + other.columnSpan && other.column < column + columnSpan && row < other.row + other.rowSpan && other.row < row + rowSpan
    }
}

nonisolated struct KeypadLayout: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var name: String
    var columns: Int
    var rows: Int
    var keys: [KeypadKey]
    var isBuiltIn = false

    static let columnRange = 1...8
    static let rowRange = 1...6

    func key(at point: CGPoint) -> KeypadKey? {
        let column = min(max(Int(point.x * Double(columns)), 0), columns - 1)
        let row = min(max(Int(point.y * Double(rows)), 0), rows - 1)
        return key(column: column, row: row)
    }

    func key(column: Int, row: Int) -> KeypadKey? {
        keys.first { $0.covers(column: column, row: row) }
    }

    func fits(_ key: KeypadKey) -> Bool {
        key.column >= 0 && key.row >= 0 && key.column + key.columnSpan <= columns && key.row + key.rowSpan <= rows && !keys.contains { $0.id != key.id && $0.overlaps(key) }
    }

    func maximumColumnSpan(for key: KeypadKey) -> Int {
        var candidate = key
        while candidate.columnSpan < columns {
            candidate.columnSpan += 1
            if !fits(candidate) { return candidate.columnSpan - 1 }
        }
        return candidate.columnSpan
    }

    func maximumRowSpan(for key: KeypadKey) -> Int {
        var candidate = key
        while candidate.rowSpan < rows {
            candidate.rowSpan += 1
            if !fits(candidate) { return candidate.rowSpan - 1 }
        }
        return candidate.rowSpan
    }

    mutating func resize(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        keys = keys.compactMap { key in
            guard key.column < columns, key.row < rows else { return nil }
            var key = key
            key.columnSpan = min(key.columnSpan, columns - key.column)
            key.rowSpan = min(key.rowSpan, rows - key.row)
            return key
        }
    }

    func copy(named name: String) -> KeypadLayout {
        KeypadLayout(id: UUID().uuidString, name: name, columns: columns, rows: rows, keys: keys.map { KeypadKey(action: $0.action, column: $0.column, row: $0.row, columnSpan: $0.columnSpan, rowSpan: $0.rowSpan) })
    }

    private static func key(_ action: KeyAction, _ column: Int, _ row: Int, width: Int = 1, height: Int = 1) -> KeypadKey {
        KeypadKey(action: action, column: column, row: row, columnSpan: width, rowSpan: height)
    }

    static let standard = KeypadLayout(id: "standard", name: "Standard", columns: 5, rows: 4, keys: [
        key(.digit7, 0, 0), key(.digit8, 1, 0), key(.digit9, 2, 0), key(.divide, 3, 0), key(.delete, 4, 0),
        key(.digit4, 0, 1), key(.digit5, 1, 1), key(.digit6, 2, 1), key(.multiply, 3, 1), key(.clear, 4, 1),
        key(.digit1, 0, 2), key(.digit2, 1, 2), key(.digit3, 2, 2), key(.minus, 3, 2), key(.equals, 4, 2),
        key(.digit0, 0, 3, width: 2), key(.decimal, 2, 3), key(.plus, 3, 3), key(.enter, 4, 3)
    ], isBuiltIn: true)

    static let classic = KeypadLayout(id: "classic", name: "Classic", columns: 4, rows: 5, keys: [
        key(.clear, 0, 0), key(.equals, 1, 0), key(.divide, 2, 0), key(.multiply, 3, 0),
        key(.digit7, 0, 1), key(.digit8, 1, 1), key(.digit9, 2, 1), key(.minus, 3, 1),
        key(.digit4, 0, 2), key(.digit5, 1, 2), key(.digit6, 2, 2), key(.plus, 3, 2),
        key(.digit1, 0, 3), key(.digit2, 1, 3), key(.digit3, 2, 3), key(.enter, 3, 3, height: 2),
        key(.digit0, 0, 4, width: 2), key(.decimal, 2, 4)
    ], isBuiltIn: true)

    static let builtIn = [standard, classic]
}
