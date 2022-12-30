// 
// Created by John Griffin on 12/29/22
//

import Foundation

public extension Sequence {
    func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        self.max { a, b in
            a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
