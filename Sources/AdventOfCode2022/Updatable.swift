// 
// Created by John Griffin on 12/26/22
//

import Foundation

public protocol Updatable {}

public extension Updatable {
    func updating(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
