import Foundation
import OSLog

final class TouchLogger {
    private let logger = Logger(subsystem: "app.ghostpad", category: "touch")
    private var previousStates: [Int: TouchState] = [:]
    private var lastLogTime: TimeInterval = 0
    private let interval: TimeInterval = 0.1

    func log(_ frame: TouchFrame) {
        let states = Dictionary(uniqueKeysWithValues: frame.touches.map { ($0.id, $0.state) })
        let changed = states != previousStates
        previousStates = states
        guard changed || (!frame.touches.isEmpty && frame.timestamp - lastLogTime >= interval) else { return }
        lastLogTime = frame.timestamp
        guard !frame.touches.isEmpty else {
            logger.debug("— no touches")
            return
        }
        let summary = frame.touches.map(describe).joined(separator: "   ")
        logger.debug("[\(frame.contacts.count)] \(summary, privacy: .public)")
    }

    private func describe(_ touch: TouchPoint) -> String {
        let x = String(format: "%.2f", touch.position.x)
        let y = String(format: "%.2f", touch.position.y)
        let size = String(format: "%.2f", touch.size)
        let axes = String(format: "%.1f/%.1f", touch.majorAxis, touch.minorAxis)
        return "#\(touch.id) \(touch.state) x:\(x) y:\(y) size:\(size) axes:\(axes)"
    }
}
