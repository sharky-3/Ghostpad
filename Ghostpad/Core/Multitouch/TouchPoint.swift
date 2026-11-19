import CoreGraphics
import Foundation

nonisolated enum TouchState: Int, Sendable {
    case notTracking
    case startInRange
    case hoverInRange
    case makeTouch
    case touching
    case breakTouch
    case lingerInRange
    case outOfRange

    init(raw: Int32) {
        self = TouchState(rawValue: Int(raw)) ?? .notTracking
    }

    var isContact: Bool {
        self == .makeTouch || self == .touching
    }
}

nonisolated struct TouchPoint: Sendable, Hashable {
    let id: Int
    let state: TouchState
    let position: CGPoint
    let velocity: CGVector
    let size: Double
    let majorAxis: Double
    let minorAxis: Double
}

nonisolated struct TouchFrame: Sendable {
    let touches: [TouchPoint]
    let timestamp: TimeInterval
    let number: Int

    var contacts: [TouchPoint] {
        touches.filter(\.state.isContact)
    }
}

nonisolated struct TrackpadGeometry: Sendable {
    let width: Double
    let height: Double

    static let fallback = TrackpadGeometry(width: 160, height: 100)

    var aspectRatio: Double {
        width / height
    }
}
