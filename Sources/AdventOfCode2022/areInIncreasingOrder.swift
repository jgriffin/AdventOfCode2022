//
// Created by John Griffin on 1/3/23
//

import Foundation

public func areInIncreasingOrder<Element>(
    by keyPath: KeyPath<Element, some Comparable>
) -> (Element, Element) -> Bool {
    { lhs, rhs in
        lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
    }
}

public func areInIncreasingOrder<Element>(
    by: @escaping (Element, Element) -> Bool,
    then: @escaping (Element, Element) -> Bool
) -> (Element, Element) ->  Bool {
    { lhs, rhs in
        if by(lhs, rhs) {
            return true
        }
        if by(rhs, lhs) {
            return false
        }
        return then(lhs, rhs)
    }
}

public func areInIncreasingOrder<Element>(
    by keyPath: KeyPath<Element, some Comparable>,
    then keyPath2: KeyPath<Element, some Comparable>
) -> (Element, Element) -> Bool {
    areInIncreasingOrder(by: areInIncreasingOrder(by: keyPath), then: areInIncreasingOrder(by: keyPath2))
}
