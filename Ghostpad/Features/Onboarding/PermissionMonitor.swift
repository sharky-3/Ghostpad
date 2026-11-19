import AppKit
import ApplicationServices

@Observable
final class PermissionMonitor {
    private(set) var isTrusted = AXIsProcessTrusted()
    var onGranted: (() -> Void)?

    private var timer: Timer?

    func request() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
        if !isTrusted {
            watch()
        }
    }

    func refresh() {
        isTrusted = AXIsProcessTrusted()
        if !isTrusted {
            watch()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
        watch()
    }

    private func watch() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
    }

    private func poll() {
        guard AXIsProcessTrusted() else { return }
        isTrusted = true
        timer?.invalidate()
        timer = nil
        onGranted?()
    }
}
