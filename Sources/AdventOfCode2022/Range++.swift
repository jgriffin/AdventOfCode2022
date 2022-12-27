//
// Created by John Griffin on 12/23/22
//

import Foundation

public func range<Bound: Comparable>(_ minMax: (min: Bound, max: Bound)) -> ClosedRange<Bound> {
    minMax.min ... minMax.max
}
