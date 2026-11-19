import AppKit
import SwiftUI

final class HUDController {
    let model = HUDModel()

    private let margin: CGFloat = 56
    private let screenInset: CGFloat = 14
    private var panel: HUDPanel?
    private var visibilityToken = 0
    private var pressToken = 0

    func show(layout: KeypadLayout, anchor: HUDAnchor, width: Double, opacity: Double, aspectRatio: Double) {
        let wasPresented = model.isPresented
        if !wasPresented {
            model.anchor = anchor
            model.width = width
        }
        model.opacity = opacity
        model.layout = layout
        model.aspectRatio = aspectRatio
        model.touches = []
        model.pressedKeyID = nil
        let panel = preparePanel(moving: !wasPresented)
        visibilityToken += 1
        panel.orderFrontRegardless()
        DispatchQueue.main.async { [weak self] in
            withAnimation(.spring(duration: 0.5, bounce: 0)) {
                self?.model.isPresented = true
            }
        }
    }

    func hide() {
        visibilityToken += 1
        let token = visibilityToken
        model.touches = []
        withAnimation(.spring(duration: 0.38, bounce: 0)) {
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

    private func preparePanel(moving: Bool) -> HUDPanel {
        let panel = self.panel ?? makePanel()
        guard moving, let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main else { return panel }
        let card = model.cardSize
        let origin = model.anchor.origin(for: card, in: screen.visibleFrame, inset: screenInset)
        let cardFrame = CGRect(origin: origin, size: card)
        let offset = hiddenOffset(for: cardFrame, on: screen.frame)
        model.hiddenOffset = offset
        let visibleFrame = cardFrame.insetBy(dx: -margin, dy: -margin)
        let hiddenFrame = visibleFrame.offsetBy(dx: offset.width, dy: -offset.height)
        panel.setFrame(visibleFrame.union(hiddenFrame), display: true)
        return panel
    }

    private func hiddenOffset(for card: CGRect, on screen: CGRect) -> CGSize {
        let clearance: CGFloat = 40
        switch model.anchor.slideEdge {
        case .top: return CGSize(width: 0, height: -(screen.maxY - card.minY + clearance))
        case .bottom: return CGSize(width: 0, height: card.maxY - screen.minY + clearance)
        case .leading: return CGSize(width: -(card.maxX - screen.minX + clearance), height: 0)
        case .trailing: return CGSize(width: screen.maxX - card.minX + clearance, height: 0)
        }
    }

    private func makePanel() -> HUDPanel {
        let panel = HUDPanel()
        let host = NSHostingView(rootView: HUDView(model: model, margin: margin))
        host.sizingOptions = []
        panel.contentView = host
        self.panel = panel
        return panel
    }
}
