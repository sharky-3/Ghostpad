import AppKit
import OSLog

final class AppCoordinator {
    private let settings = SettingsStore()
    private let permissions = PermissionMonitor()
    private let multitouch = MultitouchMonitor()
    private let swipeRecognizer = EdgeSwipeRecognizer()
    private let tapRecognizer = TapRecognizer()
    private let hud = HUDController()
    private let logger = Logger(subsystem: "app.ghostpad", category: "keypad")
    private lazy var inputBlocker = InputBlocker { [weak self] in
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                self?.setKeypadActive(false)
            }
        }
    }
    private var menuBar: MenuBarController?
    private lazy var settingsWindow = SettingsWindowController { [unowned self] in
        SettingsView(settings: self.settings, permissions: self.permissions, aspectRatio: self.multitouch.geometry.aspectRatio) { [weak self] in
            self?.previewHUD()
        }
    }
    private var previewToken = 0
    private var isKeypadActive = false
    private var suppressesGestures = false
    private var suppressionToken = 0
    private var inactivityTimer: Timer?

    func start() {
        menuBar = MenuBarController { [weak self] in
            self?.showSettings()
        }
        swipeRecognizer.onSwipe = { [weak self] swipe in
            self?.handle(swipe)
        }
        tapRecognizer.onTap = { [weak self] point in
            self?.press(at: point)
        }
        multitouch.onFrame = { [weak self] frame in
            self?.handle(frame)
        }
        permissions.onGranted = { [weak self] in
            self?.startInputBlocker()
        }
        multitouch.start()
        if permissions.isTrusted {
            startInputBlocker()
        } else {
            permissions.request()
        }
    }

    func showSettings() {
        settingsWindow.show()
    }

    func stop() {
        inputBlocker.stop()
        multitouch.stop()
    }

    private func startInputBlocker() {
        if inputBlocker.start() {
            logger.info("Input blocker running")
        } else {
            logger.error("Input blocker could not start")
        }
    }

    private func handle(_ frame: TouchFrame) {
        swipeRecognizer.process(frame)
        let contacts = frame.contacts
        if contacts.isEmpty && suppressesGestures {
            endSuppressionSoon()
        }
        updateBlocking()
        guard isKeypadActive else { return }
        hud.update(touches: contacts)
        tapRecognizer.process(frame)
        if !contacts.isEmpty {
            restartInactivityTimer()
        }
    }

    private func handle(_ swipe: EdgeSwipe) {
        suppressesGestures = true
        suppressionToken += 1
        setKeypadActive(swipe == .enter)
    }

    private func endSuppressionSoon() {
        suppressionToken += 1
        let token = suppressionToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.suppressionToken == token else { return }
            self.suppressesGestures = false
            self.updateBlocking()
        }
    }

    private func updateBlocking() {
        if isKeypadActive {
            inputBlocker.setMode(.all)
        } else if swipeRecognizer.isEdgeCandidate || suppressesGestures {
            inputBlocker.setMode(.gestures)
        } else {
            inputBlocker.setMode(.none)
        }
    }

    private func press(at point: CGPoint) {
        guard let key = settings.layout.key(at: point) else { return }
        hud.flash(key)
        KeySender.send(key.action)
        restartInactivityTimer()
    }

    private func restartInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: settings.inactivityTimeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.setKeypadActive(false)
            }
        }
    }

    private func showHUD() {
        hud.show(layout: settings.layout, anchor: settings.anchor, width: settings.hudWidth, opacity: settings.hudOpacity, aspectRatio: multitouch.geometry.aspectRatio)
    }

    private func previewHUD() {
        guard !isKeypadActive else { return }
        previewToken += 1
        let token = previewToken
        hud.hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.previewToken == token, !self.isKeypadActive else { return }
            self.showHUD()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self, self.previewToken == token, !self.isKeypadActive else { return }
                self.hud.hide()
            }
        }
    }

    private func setKeypadActive(_ active: Bool) {
        guard active != isKeypadActive else { return }
        isKeypadActive = active
        swipeRecognizer.isKeypadActive = active
        tapRecognizer.reset()
        menuBar?.setActive(active)
        updateBlocking()
        if active {
            if !permissions.isTrusted {
                permissions.request()
            }
            previewToken += 1
            showHUD()
            restartInactivityTimer()
        } else {
            hud.hide()
            inactivityTimer?.invalidate()
            inactivityTimer = nil
        }
        logger.info("Keypad mode \(active ? "on" : "off", privacy: .public)")
    }
}
