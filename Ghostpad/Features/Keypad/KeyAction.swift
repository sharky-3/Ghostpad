import Carbon.HIToolbox
import CoreGraphics

nonisolated enum KeyAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7, digit8, digit9
    case decimal, comma
    case plus, minus, multiply, divide, equals
    case enter, returnKey, tab, space, escape
    case clear, delete, forwardDelete
    case left, right, up, down

    enum Group: String, CaseIterable, Sendable {
        case numbers = "Numbers"
        case operators = "Operators"
        case editing = "Editing"
        case navigation = "Navigation"
    }

    var id: String {
        rawValue
    }

    var group: Group {
        switch self {
        case .digit0, .digit1, .digit2, .digit3, .digit4, .digit5, .digit6, .digit7, .digit8, .digit9, .decimal, .comma: .numbers
        case .plus, .minus, .multiply, .divide, .equals: .operators
        case .enter, .returnKey, .tab, .space, .escape, .clear, .delete, .forwardDelete: .editing
        case .left, .right, .up, .down: .navigation
        }
    }

    var label: String {
        switch self {
        case .digit0: "0"
        case .digit1: "1"
        case .digit2: "2"
        case .digit3: "3"
        case .digit4: "4"
        case .digit5: "5"
        case .digit6: "6"
        case .digit7: "7"
        case .digit8: "8"
        case .digit9: "9"
        case .decimal: "."
        case .comma: ","
        case .plus: "+"
        case .minus: "−"
        case .multiply: "×"
        case .divide: "÷"
        case .equals: "="
        case .enter: "Enter"
        case .returnKey: "Return"
        case .tab: "Tab"
        case .space: "Space"
        case .escape: "esc"
        case .clear: "Clear"
        case .delete: "Delete"
        case .forwardDelete: "Forward Delete"
        case .left: "Left"
        case .right: "Right"
        case .up: "Up"
        case .down: "Down"
        }
    }

    var title: String {
        switch self {
        case .escape: "Escape"
        case .left, .right, .up, .down: "\(label) Arrow"
        default: label
        }
    }

    var systemImage: String? {
        switch self {
        case .enter: "return"
        case .returnKey: "arrow.turn.down.left"
        case .tab: "arrow.right.to.line"
        case .space: "space"
        case .delete: "delete.left"
        case .forwardDelete: "delete.right"
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        case .down: "arrow.down"
        default: nil
        }
    }

    var keyCode: CGKeyCode {
        let code: Int
        switch self {
        case .digit0: code = kVK_ANSI_Keypad0
        case .digit1: code = kVK_ANSI_Keypad1
        case .digit2: code = kVK_ANSI_Keypad2
        case .digit3: code = kVK_ANSI_Keypad3
        case .digit4: code = kVK_ANSI_Keypad4
        case .digit5: code = kVK_ANSI_Keypad5
        case .digit6: code = kVK_ANSI_Keypad6
        case .digit7: code = kVK_ANSI_Keypad7
        case .digit8: code = kVK_ANSI_Keypad8
        case .digit9: code = kVK_ANSI_Keypad9
        case .decimal: code = kVK_ANSI_KeypadDecimal
        case .comma: code = kVK_ANSI_Comma
        case .plus: code = kVK_ANSI_KeypadPlus
        case .minus: code = kVK_ANSI_KeypadMinus
        case .multiply: code = kVK_ANSI_KeypadMultiply
        case .divide: code = kVK_ANSI_KeypadDivide
        case .equals: code = kVK_ANSI_KeypadEquals
        case .enter: code = kVK_ANSI_KeypadEnter
        case .returnKey: code = kVK_Return
        case .tab: code = kVK_Tab
        case .space: code = kVK_Space
        case .escape: code = kVK_Escape
        case .clear: code = kVK_ANSI_KeypadClear
        case .delete: code = kVK_Delete
        case .forwardDelete: code = kVK_ForwardDelete
        case .left: code = kVK_LeftArrow
        case .right: code = kVK_RightArrow
        case .up: code = kVK_UpArrow
        case .down: code = kVK_DownArrow
        }
        return CGKeyCode(code)
    }

    var flags: CGEventFlags {
        switch self {
        case .comma, .returnKey, .tab, .space, .escape, .delete: []
        case .forwardDelete: .maskSecondaryFn
        case .left, .right, .up, .down: [.maskNumericPad, .maskSecondaryFn]
        default: .maskNumericPad
        }
    }

    var isPrimary: Bool {
        group == .numbers
    }

    var isAccent: Bool {
        self == .enter
    }
}
