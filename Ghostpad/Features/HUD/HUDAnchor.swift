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

    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomCenter: "Bottom Center"
        case .bottomRight: "Bottom Right"
        }
    }

    var horizontal: Int {
        switch self {
        case .topLeft, .bottomLeft: -1
        case .topCenter, .bottomCenter: 0
        case .topRight, .bottomRight: 1
        }
    }

    var isTop: Bool {
        self == .topLeft || self == .topCenter || self == .topRight
    }

    var slideEdge: Edge {
        switch self {
        case .topCenter: .top
        case .bottomCenter: .bottom
        case .topLeft, .bottomLeft: .leading
        case .topRight, .bottomRight: .trailing
        }
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
