//
// Created by John Griffin on 12/5/22
//

import Foundation

public extension Collection {
    var only: Element? {
        guard count == 1 else { return nil }
        return first
    }
}
