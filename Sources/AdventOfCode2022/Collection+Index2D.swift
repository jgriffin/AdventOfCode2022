//
// Created by John Griffin on 12/8/22
//

import Foundation

public extension RandomAccessCollection where Index == Int, Element: RandomAccessCollection, Element.Index == Int {
    typealias Index2D = (row: Int, col: Int)

    subscript(index2D: Index2D) -> Element.Element {
        self[index2D.row][index2D.col]
    }

    subscript(index2D: Index2D) -> Element.Element where Self: MutableCollection, Element: MutableCollection {
        get {
            self[index2D.row][index2D.col]
        }
        set(newValue) {
            self[index2D.row][index2D.col] = newValue
        }
    }
}
