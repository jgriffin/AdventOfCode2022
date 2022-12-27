//
// Created by John Griffin on 12/13/22
//

import SwiftUI

public extension View {
    @MainActor
    func renderCGImage(scale _: CGFloat = 2) -> CGImage? {
        let renderer = ImageRenderer(content: self)
        return renderer.cgImage
    }
}
