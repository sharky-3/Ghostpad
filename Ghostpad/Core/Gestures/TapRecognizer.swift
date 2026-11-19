import CoreGraphics
import Foundation

nonisolated struct TapConfiguration: Sendable {
    var maximumDuration: TimeInterval = 0.22
    var maximumMovement: Double = 0.03
    var maximumMajorAxis: Double = 14
    var maximumSize: Double = 1.6
}

final class TapRecognizer {
    private struct Candidate {
        let start: CGPoint
        let time: TimeInterval
        var isValid: Bool
    }

    var configuration = TapConfiguration()
    var onTap: ((CGPoint) -> Void)?

    private var candidates: [Int: Candidate] = [:]

    func process(_ frame: TouchFrame) {
        let contacts = frame.contacts
        let activeIDs = Set(contacts.map(\.id))
        for contact in contacts {
            if var candidate = candidates[contact.id] {
                if !isTapLike(contact, from: candidate, at: frame.timestamp) {
                    candidate.isValid = false
                }
                candidates[contact.id] = candidate
            } else {
                for (id, other) in candidates where frame.timestamp - other.time <= configuration.maximumDuration {
                    candidates[id]?.isValid = false
                }
                let overlaps = candidates.values.contains { frame.timestamp - $0.time <= configuration.maximumDuration }
                candidates[contact.id] = Candidate(start: contact.position, time: frame.timestamp, isValid: !overlaps && contact.majorAxis <= configuration.maximumMajorAxis)
            }
        }
        for (id, candidate) in candidates where !activeIDs.contains(id) {
            candidates[id] = nil
            if candidate.isValid && frame.timestamp - candidate.time <= configuration.maximumDuration {
                onTap?(candidate.start)
            }
        }
    }

    func reset() {
        candidates.removeAll()
    }

    private func isTapLike(_ contact: TouchPoint, from candidate: Candidate, at time: TimeInterval) -> Bool {
        let movement = hypot(contact.position.x - candidate.start.x, contact.position.y - candidate.start.y)
        return movement <= configuration.maximumMovement && contact.majorAxis <= configuration.maximumMajorAxis && contact.size <= configuration.maximumSize && time - candidate.time <= configuration.maximumDuration
    }
}
