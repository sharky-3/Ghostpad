import CoreGraphics
import Foundation
import OSLog

enum EdgeSwipe {
    case enter
    case exit
}

final class EdgeSwipeRecognizer {
    private enum Phase {
        case idle
        case tracking
        case finished
    }

    private struct Origin {
        let position: CGPoint
        let time: TimeInterval
    }

    var configuration = SwipeConfiguration()
    var isKeypadActive = false
    var onSwipe: ((EdgeSwipe) -> Void)?

    private(set) var isEdgeCandidate = false
    private var phase = Phase.idle
    private var origins: [Int: Origin] = [:]
    private let logger = Logger(subsystem: "app.ghostpad", category: "gesture")

    func process(_ frame: TouchFrame) {
        let contacts = frame.contacts
        guard !contacts.isEmpty else {
            reset()
            return
        }
        guard phase != .finished else { return }
        phase = .tracking
        for contact in contacts where origins[contact.id] == nil {
            origins[contact.id] = Origin(position: contact.position, time: frame.timestamp)
        }
        guard contacts.count <= 2, origins.count <= 2 else {
            finish(reason: "more than two fingers")
            return
        }
        isEdgeCandidate = !isKeypadActive && origins.values.contains { configuration.entryEdge.distance(from: $0.position.x) <= configuration.edgeZoneWidth }
        guard contacts.count == 2 else { return }
        evaluate(contacts, at: frame.timestamp)
    }

    private func evaluate(_ contacts: [TouchPoint], at time: TimeInterval) {
        let pairs = contacts.compactMap { contact in origins[contact.id].map { (origin: $0, current: contact.position) } }
        guard pairs.count == 2 else { return }
        let firstArrival = pairs.map(\.origin.time).min() ?? time
        let lastArrival = pairs.map(\.origin.time).max() ?? time
        guard lastArrival - firstArrival <= configuration.fingerArrivalWindow else {
            finish(reason: "fingers arrived too far apart")
            return
        }
        if isKeypadActive {
            evaluateExit(pairs, elapsed: time - lastArrival)
        } else {
            evaluateEntry(pairs, elapsed: time - lastArrival)
        }
    }

    private func evaluateEntry(_ pairs: [(origin: Origin, current: CGPoint)], elapsed: TimeInterval) {
        let edge = configuration.entryEdge
        let distances = pairs.map { edge.distance(from: $0.origin.position.x) }
        guard let outer = distances.min(), let inner = distances.max(), outer <= configuration.edgeZoneWidth else {
            finish(reason: nil)
            return
        }
        guard inner <= configuration.companionZoneWidth else {
            finish(reason: "second finger too far from the edge")
            return
        }
        if pairs.allSatisfy({ isSwipe($0.origin.position, $0.current, direction: edge.inwardDirection) }) {
            logger.info("Entry swipe in \(elapsed * 1000, format: .fixed(precision: 0)) ms")
            finish(reason: nil)
            onSwipe?(.enter)
        } else if elapsed > configuration.maximumDuration {
            finish(reason: "entry too slow")
        }
    }

    private func evaluateExit(_ pairs: [(origin: Origin, current: CGPoint)], elapsed: TimeInterval) {
        if pairs.allSatisfy({ isSwipe($0.origin.position, $0.current, direction: -configuration.entryEdge.inwardDirection) }) {
            logger.info("Exit swipe in \(elapsed * 1000, format: .fixed(precision: 0)) ms")
            finish(reason: nil)
            onSwipe?(.exit)
        } else if elapsed > configuration.exitMaximumDuration {
            finish(reason: "exit too slow")
        }
    }

    private func isSwipe(_ start: CGPoint, _ end: CGPoint, direction: Double) -> Bool {
        let dx = (end.x - start.x) * direction
        let dy = abs(end.y - start.y)
        return dx >= configuration.minimumDistance && dx >= dy * configuration.horizontalDominance
    }

    private func finish(reason: String?) {
        if let reason, isEdgeCandidate || isKeypadActive {
            logger.debug("Swipe rejected: \(reason, privacy: .public)")
        }
        phase = .finished
        isEdgeCandidate = false
    }

    private func reset() {
        phase = .idle
        origins.removeAll()
        isEdgeCandidate = false
    }
}
