import CoreGraphics

enum KeySender {
    nonisolated static let marker: Int64 = 0x6768_6F73

    static func send(_ action: KeyAction) {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: action.keyCode, keyDown: true), let up = CGEvent(keyboardEventSource: source, virtualKey: action.keyCode, keyDown: false) else { return }
        for event in [down, up] {
            event.flags = action.flags
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            event.post(tap: .cghidEventTap)
        }
    }
}
