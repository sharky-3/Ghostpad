import AppKit
import OSLog

final class AppCoordinator {
    private let multitouch = MultitouchMonitor()
    private let touchLogger = TouchLogger()
    private let swipeRecognizer = EdgeSwipeRecognizer()
    private let tapRecognizer = TapRecognizer()
    private let hud = HUDController()
    private let logger = Logger(subsystem: "app.ghostpad", category: "keypad")
    private var menuBar: MenuBarController?
    private var layout = KeypadLayout.standard
    private var isKeypadActive = false

    func start() {
        menuBar = MenuBarController { [weak self] in
            guard let self else { return }
            self.setKeypadActive(!self.isKeypadActive)
        }
        swipeRecognizer.onSwipe = { [weak self] swipe in
            self?.setKeypadActive(swipe == .enter)
        }
        tapRecognizer.onTap = { [weak self] point in
            self?.press(at: point)
        }
        multitouch.onFrame = { [weak self] frame in
            self?.handle(frame)
        }
        multitouch.start()
    }

    func stop() {
        multitouch.stop()
    }

    private func handle(_ frame: TouchFrame) {
        touchLogger.log(frame)
        swipeRecognizer.process(frame)
        guard isKeypadActive else { return }
        hud.update(touches: frame.contacts)
        tapRecognizer.process(frame)
    }

    private func press(at point: CGPoint) {
        guard let key = layout.key(at: point) else { return }
        hud.flash(key)
        logger.info("Pressed \(key.label, privacy: .public)")
    }

    private func setKeypadActive(_ active: Bool) {
        guard active != isKeypadActive else { return }
        isKeypadActive = active
        swipeRecognizer.isKeypadActive = active
        tapRecognizer.reset()
        menuBar?.setActive(active)
        if active {
            hud.show(layout: layout, aspectRatio: multitouch.geometry.aspectRatio)
        } else {
            hud.hide()
        }
        logger.info("Keypad mode \(active ? "on" : "off", privacy: .public)")
    }
}
