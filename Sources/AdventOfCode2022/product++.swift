//
// Created by John Griffin on 12/23/22
//

import Algorithms

public func product3<Base1: Sequence, Base2: Collection, Base3: Collection>(
    _ s1: Base1, _ s2: Base2, _ s3: Base3
) -> some Sequence<(Base1.Element, Base2.Element, Base3.Element)> {
    product(s1, product(s2, s3))
        .lazy
        .map { ($0, $1.0, $1.1) }
}

public func productOfRanges(
    _ range1: (min: Int, max: Int), _ range2: (min: Int, max: Int)
) -> some Sequence<(Int, Int)> {
    product(range(range1), range(range2))
}

public func product3OfRanges(
    _ range1: (min: Int, max: Int),
    _ range2: (min: Int, max: Int),
    _ range3: (min: Int, max: Int)
) -> some Sequence<(Int, Int, Int)> {
    product3(range(range1), range(range2), range(range3))
}
