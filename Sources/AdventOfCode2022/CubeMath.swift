//
// Created by John Griffin on 5/29/23
//

import EulerTools

public struct CubeMath {
    let sideLength: Int
    let squareForFace: [Face: Square]

    public init(
        sideLength: Int,
        squareForFace: [Face: IndexRC]
    ) {
        assert(squareForFace.count == 6)
        self.sideLength = sideLength
        self.squareForFace = squareForFace
    }

    public enum Face { case one, two, three, four, five, six }
    public enum Edge { case top, bottom, leading, trailing }
    public enum Corner { case topLeft, topRight, bottomRight, bottomLeft }
    public typealias Square = IndexRC

    public func edgeIndices(_ face: Face, _ edge: Edge) -> [IndexRC] {
        edgeIndices(squareForFace[face]!, edge)
    }

    func edgeIndices(_ square: Square, _ edge: Edge) -> [IndexRC] {
        let corners: (from: Corner, to: Corner) = {
            switch edge {
            case .top: return (.topLeft, .topRight)
            case .bottom: return (.bottomLeft, .bottomRight)
            case .leading: return (.topLeft, .bottomLeft)
            case .trailing: return (.topRight, .bottomRight)
            }
        }()
        return try! cornerIndex(square, corners.from)
            .unitWalk(to: cornerIndex(square, corners.to))
    }

    func cornerIndex(_ square: Square, _ corner: Corner) -> IndexRC {
        switch corner {
        case .topLeft: return .init(square.r * sideLength, square.c * sideLength)
        case .topRight: return .init(square.r * sideLength, (square.c + 1) * sideLength - 1)
        case .bottomRight: return .init((square.r + 1) * sideLength - 1, (square.c + 1) * sideLength - 1)
        case .bottomLeft: return .init((square.r + 1) * sideLength - 1, square.c * sideLength)
        }
    }
}
