import AppKit

final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let onSettings: () -> Void

    init(onSettings: @escaping () -> Void) {
        self.onSettings = onSettings
        super.init()
        statusItem.button?.image = GhostGlyph.image(filled: false)
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ghostpad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func setActive(_ active: Bool) {
        statusItem.button?.image = GhostGlyph.image(filled: active)
    }

    @objc private func openSettings() {
        onSettings()
    }
}
