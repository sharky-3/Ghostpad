import Foundation

nonisolated enum EntryEdge: String, Sendable, CaseIterable {
    case left
    case right

    var inwardDirection: Double {
        self == .left ? 1 : -1
    }

    func distance(from x: Double) -> Double {
        self == .left ? x : 1 - x
    }
}

nonisolated struct SwipeConfiguration: Sendable {
    var entryEdge: EntryEdge = .left
    var edgeZoneWidth: Double = 0.08
    var companionZoneWidth: Double = 0.3
    var minimumDistance: Double = 0.15
    var maximumDuration: TimeInterval = 0.45
    var exitMaximumDuration: TimeInterval = 0.5
    var horizontalDominance: Double = 1.5
    var fingerArrivalWindow: TimeInterval = 0.25
}
