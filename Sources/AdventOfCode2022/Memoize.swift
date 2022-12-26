//
// Created by John Griffin on 12/26/22
//

import Foundation

// https://medium.com/@mvxlr/swift-memoize-walk-through-c5224a558194

// Non Recursive
public func memoize<T: Hashable, U>(work: @escaping (T)->U)->(T)->U {
    var memo = [T: U]()

    return { x in
        if let q = memo[x] {
            return q
        }
        let r = work(x)
        memo[x] = r
        return r
    }
}

// Recursion supporting version
public func memoize<T: Hashable, U>(work: @escaping ((T)->U, T)->U)->(T)->U {
    var memo = [T: U]()

    func wrap(x: T)->U {
        if let q = memo[x] {
            return q
        }
        let r = work(wrap, x)
        memo[x] = r
        return r
    }

    return wrap
}
