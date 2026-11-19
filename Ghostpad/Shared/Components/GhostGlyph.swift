import AppKit

enum GhostGlyph {
    static func image(filled: Bool, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = rect.width / 18
            let transform = AffineTransform(scale: scale)
            let body = bodyPath()
            body.transform(using: transform)
            let eyes = eyesPath()
            eyes.transform(using: transform)
            NSColor.black.set()
            if filled {
                body.append(eyes)
                body.windingRule = .evenOdd
                body.fill()
            } else {
                body.lineWidth = 1.4 * scale
                body.lineJoinStyle = .round
                body.stroke()
                eyes.fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Ghostpad"
        return image
    }

    private static func bodyPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 3.5, y: 9.5))
        path.appendArc(withCenter: NSPoint(x: 9, y: 9.5), radius: 5.5, startAngle: 180, endAngle: 0, clockwise: true)
        path.line(to: NSPoint(x: 14.5, y: 2.5))
        let points: [CGFloat] = [14.5, 10.83, 7.17, 3.5]
        for index in 1..<points.count {
            let start = points[index - 1]
            let end = points[index]
            path.curve(to: NSPoint(x: end, y: 2.5), controlPoint: NSPoint(x: (start + end) / 2, y: 5))
        }
        path.close()
        return path
    }

    private static func eyesPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.appendOval(in: NSRect(x: 6.6, y: 8.6, width: 1.7, height: 2.4))
        path.appendOval(in: NSRect(x: 9.7, y: 8.6, width: 1.7, height: 2.4))
        return path
    }
}
