import AppKit
import SwiftUI

final class SettingsWindowController {
    private let makeView: () -> SettingsView
    private var window: NSWindow?

    init(makeView: @escaping () -> SettingsView) {
        self.makeView = makeView
    }

    func show() {
        let window = self.window ?? makeWindow()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let host = NSHostingController(rootView: makeView())
        host.sizingOptions = []
        let window = NSWindow(contentViewController: host)
        window.title = "Ghostpad"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 740, height: 600)
        window.setContentSize(NSSize(width: 780, height: 640))
        window.center()
        window.setFrameAutosaveName("GhostpadSettings")
        self.window = window
        return window
    }
}
