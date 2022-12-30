//
// Created by John Griffin on 12/29/22
//

import Foundation

/**
 easy way to measure the executaion time of a block
 inspired by https://www.objc.io/blog/2018/06/14/quick-performance-timing/
 */
@discardableResult
public func measureTime<A>(name: String = "", _ block: () async -> A) async -> A {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = await block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time: \(name) - \(timeElapsed)")
    return result
}

@discardableResult
public func measureTime<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time: \(name) - \(timeElapsed)")
    return result
}
