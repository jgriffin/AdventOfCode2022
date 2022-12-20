//
// Created by John Griffin on 12/18/22
//

import EulerTools
import Foundation

public extension Int {
    var unitBias: Int {
        guard self != 0 else { return 0 }
        return self < 0 ? -1 : 1
    }
}

public extension Indexable2 {
    var unitBias: Self {
        .init(first.unitBias, second.unitBias)
    }
}
