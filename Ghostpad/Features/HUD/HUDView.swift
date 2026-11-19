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
            .opacity(model.isPresented ? model.opacity : 0)
            .scaleEffect(model.isPresented ? 1 : 0.92, anchor: model.anchor.unitPoint)
            .offset(model.isPresented ? .zero : model.anchor.slideOffset)
            .padding(margin)
    }
}

struct KeypadGridView: View {
    let layout: KeypadLayout
    let pressedKeyID: String?
    let touches: [TouchPoint]

    private let spacing: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cell = CGSize(width: (size.width - spacing * CGFloat(layout.columns - 1)) / CGFloat(layout.columns), height: (size.height - spacing * CGFloat(layout.rows - 1)) / CGFloat(layout.rows))
            ZStack(alignment: .topLeading) {
                ForEach(layout.keys) { key in
                    KeycapView(key: key, isPressed: key.id == pressedKeyID, fontSize: min(cell.height * 0.42, 22))
                        .frame(width: span(cell.width, key.columnSpan), height: span(cell.height, key.rowSpan))
                        .offset(x: CGFloat(key.column) * (cell.width + spacing), y: CGFloat(key.row) * (cell.height + spacing))
                }
                ForEach(touches, id: \.id) { touch in
                    Circle()
                        .fill(.primary.opacity(0.35))
                        .frame(width: 14, height: 14)
                        .position(x: touch.position.x * size.width, y: touch.position.y * size.height)
                        .transition(.opacity)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .animation(.easeOut(duration: 0.12), value: touches.map(\.id))
        }
    }

    private func span(_ length: CGFloat, _ count: Int) -> CGFloat {
        length * CGFloat(count) + spacing * CGFloat(count - 1)
    }
}

struct KeycapView: View {
    let key: KeypadKey
    let isPressed: Bool
    let fontSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(.primary.opacity(isPressed ? 0.22 : 0.06))
            .overlay {
                label
                    .foregroundStyle(key.kind == .digit ? .primary : .secondary)
            }
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.smooth(duration: 0.18), value: isPressed)
    }

    @ViewBuilder
    private var label: some View {
        if let symbol = key.systemImage {
            Image(systemName: symbol)
                .font(.system(size: fontSize * 0.75, weight: .regular))
        } else {
            Text(key.label)
                .font(.system(size: key.isWord ? fontSize * 0.6 : fontSize, weight: .regular))
        }
    }
}
