import SwiftUI

enum HUDAnchor: String, CaseIterable, Identifiable {
    case topLeft
    case topCenter
    case topRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    var id: String {
        rawValue
    }

    private var horizontal: Int {
        switch self {
        case .topLeft, .bottomLeft: -1
        case .topCenter, .bottomCenter: 0
        case .topRight, .bottomRight: 1
        }
    }

    private var isTop: Bool {
        self == .topLeft || self == .topCenter || self == .topRight
    }

    var unitPoint: UnitPoint {
        UnitPoint(x: Double(horizontal + 1) / 2, y: isTop ? 0 : 1)
    }

    var slideOffset: CGSize {
        let distance: CGFloat = 14
        return CGSize(width: CGFloat(horizontal) * distance, height: isTop ? -distance : distance)
    }

    func origin(for size: CGSize, in frame: CGRect, inset: CGFloat) -> CGPoint {
        let x: CGFloat
        switch horizontal {
        case -1: x = frame.minX + inset
        case 0: x = frame.midX - size.width / 2
        default: x = frame.maxX - inset - size.width
        }
        let y = isTop ? frame.maxY - inset - size.height : frame.minY + inset
        return CGPoint(x: x, y: y)
    }
}
