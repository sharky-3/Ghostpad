import AppKit
import SwiftUI

final class HUDController {
    let model = HUDModel()

    private let margin: CGFloat = 48
    private let screenInset: CGFloat = 12
    private var panel: HUDPanel?
    private var visibilityToken = 0
    private var pressToken = 0

    func show(layout: KeypadLayout, aspectRatio: Double) {
        model.layout = layout
        model.aspectRatio = aspectRatio
        model.touches = []
        model.pressedKeyID = nil
        let panel = preparePanel()
        visibilityToken += 1
        panel.orderFrontRegardless()
        withAnimation(.spring(duration: 0.38, bounce: 0)) {
            model.isPresented = true
        }
    }

    func hide() {
        visibilityToken += 1
        let token = visibilityToken
        model.touches = []
        withAnimation(.smooth(duration: 0.24)) {
            model.isPresented = false
        } completion: { [weak self] in
            guard let self, self.visibilityToken == token else { return }
            self.panel?.orderOut(nil)
        }
    }

    func update(touches: [TouchPoint]) {
        guard model.isPresented, touches != model.touches else { return }
        model.touches = touches
    }

    func flash(_ key: KeypadKey) {
        pressToken += 1
        let token = pressToken
        model.pressedKeyID = key.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
            guard let self, self.pressToken == token else { return }
            self.model.pressedKeyID = nil
        }
    }

    private func preparePanel() -> HUDPanel {
        let card = model.cardSize
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let origin = model.anchor.origin(for: card, in: visible, inset: screenInset)
        let frame = CGRect(origin: origin, size: card).insetBy(dx: -margin, dy: -margin)
        if let panel {
            panel.setFrame(frame, display: false)
            return panel
        }
        let panel = HUDPanel()
        let host = NSHostingView(rootView: HUDView(model: model, margin: margin))
        host.sizingOptions = []
        panel.contentView = host
        panel.setFrame(frame, display: false)
        host.layoutSubtreeIfNeeded()
        panel.displayIfNeeded()
        self.panel = panel
        return panel
    }
}
