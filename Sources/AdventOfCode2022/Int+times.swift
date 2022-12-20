//
// Created by John Griffin on 12/15/22
//

import Foundation

public extension Int {
    func times(_ block: (Int) -> Void) {
        for i in 0 ..< self {
            block(i)
        }
    }

    func times(_ block: () -> Void) {
        for _ in 0 ..< self {
            block()
        }
    }
}
