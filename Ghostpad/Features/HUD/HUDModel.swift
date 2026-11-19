import SwiftUI

@Observable
final class HUDModel {
    var layout = KeypadLayout.standard
    var aspectRatio = TrackpadGeometry.fallback.aspectRatio
    var anchor = HUDAnchor.bottomCenter
    var width: CGFloat = 360
    var opacity: Double = 1
    var isPresented = false
    var hiddenOffset = CGSize.zero
    var touches: [TouchPoint] = []
    var pressedKeyID: UUID?

    let padding: CGFloat = 12
    let cornerRadius: CGFloat = 24

    var cardSize: CGSize {
        let gridWidth = width - padding * 2
        return CGSize(width: width, height: gridWidth / aspectRatio + padding * 2)
    }
}
