// 
// Created by John Griffin on 12/29/22
//

import Foundation
import EulerTools

public extension Sequence {
    func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        self.max(by: areInIncreasingOrder(by: keyPath))
    }
}
