import SwiftUI

@Observable
final class HUDModel {
    var layout = KeypadLayout.standard
    var aspectRatio = TrackpadGeometry.fallback.aspectRatio
    var anchor = HUDAnchor.topRight
    var width: CGFloat = 340
    var opacity: Double = 1
    var isPresented = false
    var touches: [TouchPoint] = []
    var pressedKeyID: String?

    let padding: CGFloat = 10
    let cornerRadius: CGFloat = 20

    var cardSize: CGSize {
        let gridWidth = width - padding * 2
        return CGSize(width: width, height: gridWidth / aspectRatio + padding * 2)
    }
}
