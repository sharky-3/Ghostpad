import SwiftUI

struct PositionSettingsView: View {
    @Bindable var settings: SettingsStore
    let aspectRatio: Double
    let onPreview: () -> Void

    var body: some View {
        Form {
            Section {
                ScreenPreview(anchor: $settings.anchor, layout: settings.layout, hudWidth: settings.hudWidth, opacity: settings.hudOpacity, aspectRatio: aspectRatio)
                    .padding(.vertical, 6)
            } footer: {
                Text("Click a spot on the screen to place the keypad.")
            }
            Section {
                Picker("Position", selection: $settings.anchor) {
                    ForEach(HUDAnchor.allCases) { anchor in
                        Text(anchor.title).tag(anchor)
                    }
                }
                Slider(value: $settings.hudWidth, in: SettingsStore.widthRange) {
                    Text("Size")
                }
                Slider(value: $settings.hudOpacity, in: SettingsStore.opacityRange) {
                    Text("Opacity")
                }
            }
            Section {
                LabeledContent("Preview on screen") {
                    Button("Show Keypad", action: onPreview)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct ScreenMetrics {
    let size: CGSize
    let insets: EdgeInsets
    let hasNotch: Bool

    static var current: ScreenMetrics {
        guard let screen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main else {
            return ScreenMetrics(size: CGSize(width: 1512, height: 982), insets: EdgeInsets(top: 37, leading: 0, bottom: 70, trailing: 0), hasNotch: true)
        }
        let frame = screen.frame
        let visible = screen.visibleFrame
        let insets = EdgeInsets(top: frame.maxY - visible.maxY, leading: visible.minX - frame.minX, bottom: visible.minY - frame.minY, trailing: frame.maxX - visible.maxX)
        return ScreenMetrics(size: frame.size, insets: insets, hasNotch: screen.safeAreaInsets.top > 0)
    }
}

struct ScreenPreview: View {
    @Binding var anchor: HUDAnchor
    let layout: KeypadLayout
    let hudWidth: Double
    let opacity: Double
    let aspectRatio: Double

    @State private var hovered: HUDAnchor?
    private let metrics = ScreenMetrics.current

    private static let wallpaper = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(white: 0.24, alpha: 1) : NSColor(white: 0.78, alpha: 1)
    })

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = size.width / metrics.size.width
            let visible = CGRect(x: metrics.insets.leading * scale, y: metrics.insets.top * scale, width: size.width - (metrics.insets.leading + metrics.insets.trailing) * scale, height: size.height - (metrics.insets.top + metrics.insets.bottom) * scale)
            let card = cardSize(scale: scale)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Self.wallpaper)
                menuBar(width: size.width, height: max(metrics.insets.top * scale, 5))
                dock(size: size, scale: scale)
                ForEach(HUDAnchor.allCases.filter { $0 != anchor }) { target in
                    let rect = frame(for: target, card: card, in: visible, scale: scale)
                    RoundedRectangle(cornerRadius: 6 * scale * 4, style: .continuous)
                        .strokeBorder(.primary.opacity(hovered == target ? 0.4 : 0.16), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .background(RoundedRectangle(cornerRadius: 6 * scale * 4, style: .continuous).fill(.primary.opacity(hovered == target ? 0.06 : 0)))
                        .frame(width: rect.width, height: rect.height)
                        .contentShape(Rectangle())
                        .onHover { hovered = $0 ? target : (hovered == target ? nil : hovered) }
                        .onTapGesture { anchor = target }
                        .offset(x: rect.minX, y: rect.minY)
                }
                let rect = frame(for: anchor, card: card, in: visible, scale: scale)
                MiniKeypad(layout: layout, scale: scale)
                    .opacity(opacity)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .animation(.spring(duration: 0.45, bounce: 0), value: anchor)
            .animation(.smooth(duration: 0.2), value: hovered)
            .animation(.smooth(duration: 0.2), value: hudWidth)
        }
        .aspectRatio(metrics.size.width / metrics.size.height, contentMode: .fit)
        .padding(7)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.1)))
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private func cardSize(scale: CGFloat) -> CGSize {
        let padding: CGFloat = 12
        let height = (hudWidth - padding * 2) / aspectRatio + padding * 2
        return CGSize(width: hudWidth * scale, height: height * scale)
    }

    private func frame(for anchor: HUDAnchor, card: CGSize, in visible: CGRect, scale: CGFloat) -> CGRect {
        let inset = 14 * scale
        let x: CGFloat
        switch anchor.horizontal {
        case -1: x = visible.minX + inset
        case 0: x = visible.midX - card.width / 2
        default: x = visible.maxX - inset - card.width
        }
        let y = anchor.isTop ? visible.minY + inset : visible.maxY - inset - card.height
        return CGRect(origin: CGPoint(x: x, y: y), size: card)
    }

    private func menuBar(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.primary.opacity(0.07))
                .frame(height: height)
            if metrics.hasNotch {
                UnevenRoundedRectangle(bottomLeadingRadius: height * 0.4, bottomTrailingRadius: height * 0.4, style: .continuous)
                    .fill(.black)
                    .frame(width: width * 0.12, height: height)
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func dock(size: CGSize, scale: CGFloat) -> some View {
        let height = metrics.insets.bottom * scale
        if height > 2 {
            RoundedRectangle(cornerRadius: height * 0.3, style: .continuous)
                .fill(.primary.opacity(0.1))
                .frame(width: size.width * 0.4, height: height * 0.78)
                .offset(x: size.width * 0.3, y: size.height - height * 0.89)
        }
    }
}

struct MiniKeypad: View {
    let layout: KeypadLayout
    let scale: CGFloat

    var body: some View {
        KeypadGridView(layout: layout, spacing: max(6 * scale, 1.5), keyCornerRadius: max(11 * scale, 2))
            .padding(max(12 * scale, 3))
            .background {
                RoundedRectangle(cornerRadius: max(24 * scale, 5), style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            }
            .allowsHitTesting(false)
    }
}
