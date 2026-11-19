import AppKit

final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let toggleItem = NSMenuItem(title: "Show Keypad", action: #selector(toggle), keyEquivalent: "")
    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        super.init()
        statusItem.button?.image = GhostGlyph.image(filled: false)
        toggleItem.target = self
        let menu = NSMenu()
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Ghostpad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    func setActive(_ active: Bool) {
        statusItem.button?.image = GhostGlyph.image(filled: active)
        toggleItem.title = active ? "Hide Keypad" : "Show Keypad"
    }

    @objc private func toggle() {
        onToggle()
    }
}
