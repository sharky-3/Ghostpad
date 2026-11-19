import SwiftUI

struct HUDView: View {
    let model: HUDModel
    let margin: CGFloat

    var body: some View {
        let size = model.cardSize
        KeypadGridView(layout: model.layout, pressedKeyID: model.pressedKeyID, touches: model.touches)
            .padding(model.padding)
            .frame(width: size.width, height: size.height)
            .background {
                ZStack {
                    SoftShadow(cornerRadius: model.cornerRadius)
                    VisualEffectBlur(material: .popover, cornerRadius: model.cornerRadius)
                }
            }
            .offset(model.isPresented ? .zero : model.hiddenOffset)
            .opacity(model.isPresented ? model.opacity : 0)
            .padding(margin)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: cardAlignment)
    }
}

private extension HUDView {
    var cardAlignment: Alignment {
        switch model.anchor.slideEdge {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
}

struct KeypadGridView: View {
    let layout: KeypadLayout
    var pressedKeyID: UUID?
    var touches: [TouchPoint] = []
    var spacing: CGFloat = 6
    var keyCornerRadius: CGFloat = 11

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cell = CGSize(width: (size.width - spacing * CGFloat(layout.columns - 1)) / CGFloat(layout.columns), height: (size.height - spacing * CGFloat(layout.rows - 1)) / CGFloat(layout.rows))
            let hovered = Set(touches.compactMap { layout.key(at: $0.position)?.id })
            ZStack(alignment: .topLeading) {
                ForEach(layout.keys) { key in
                    KeycapView(key: key, state: key.id == pressedKeyID ? .pressed : hovered.contains(key.id) ? .hovered : .idle, fontSize: min(cell.height * 0.4, cell.width * 0.4, 22), cornerRadius: keyCornerRadius)
                        .frame(width: span(cell.width, key.columnSpan), height: span(cell.height, key.rowSpan))
                        .offset(x: CGFloat(key.column) * (cell.width + spacing), y: CGFloat(key.row) * (cell.height + spacing))
                }
                ForEach(touches, id: \.id) { touch in
                    TouchDot()
                        .position(x: touch.position.x * size.width, y: touch.position.y * size.height)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .animation(.smooth(duration: 0.16), value: touches.map(\.id))
        }
    }

    private func span(_ length: CGFloat, _ count: Int) -> CGFloat {
        length * CGFloat(count) + spacing * CGFloat(count - 1)
    }
}

struct TouchDot: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.primary.opacity(0.12))
                .frame(width: 30, height: 30)
                .blur(radius: 6)
            Circle()
                .fill(.primary.opacity(0.5))
                .frame(width: 11, height: 11)
        }
        .allowsHitTesting(false)
    }
}

struct KeycapView: View {
    enum State {
        case idle
        case hovered
        case pressed
    }

    let key: KeypadKey
    let state: State
    let fontSize: CGFloat
    var cornerRadius: CGFloat = 11

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
            .overlay {
                label
                    .foregroundStyle(foreground)
            }
            .scaleEffect(state == .pressed ? 0.94 : 1)
            .animation(.spring(duration: 0.22, bounce: 0), value: state)
    }

    private var fill: AnyShapeStyle {
        if key.action.isAccent {
            return AnyShapeStyle(Color.accentColor.opacity(state == .pressed ? 0.6 : state == .hovered ? 0.92 : 0.82))
        }
        switch state {
        case .idle: return AnyShapeStyle(.primary.opacity(0.06))
        case .hovered: return AnyShapeStyle(.primary.opacity(0.12))
        case .pressed: return AnyShapeStyle(.primary.opacity(0.24))
        }
    }

    private var foreground: AnyShapeStyle {
        if key.action.isAccent {
            return AnyShapeStyle(.white)
        }
        return key.action.isPrimary ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
    }

    @ViewBuilder
    private var label: some View {
        if let symbol = key.systemImage {
            Image(systemName: symbol)
                .font(.system(size: fontSize * 0.72, weight: .medium))
        } else {
            Text(key.label)
                .font(.system(size: key.isWord ? fontSize * 0.58 : fontSize, weight: key.isWord ? .medium : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 2)
        }
    }
}
