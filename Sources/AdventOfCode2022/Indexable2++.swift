//
// Created by John Griffin on 5/29/23
//

import EulerTools

public extension Indexable2 {
    func unitWalk(to: Self) throws -> [Self] {
        try Self.unitWalk(from: self, to: to)
    }
    
    static func unitWalk(from: Self, to: Self) throws -> [Self] {
        let step = try unitStepAlongWalk(from: from, to: to)
        var steps = [from]
        var curr = from
        while curr != to {
            curr = curr + step
            steps.append(curr)
        }
        return steps
    }

    static func unitStepAlongWalk(from: Self, to: Self) throws -> Self {
        guard from != to else { throw IndexableStepError.fromAndToAreEqual }

        let firstSteps = abs(to.first - from.first)
        let secondSteps = abs(to.second - from.second)
        let maxSteps = max(firstSteps, secondSteps)
        let minSteps = min(firstSteps, secondSteps)
        guard minSteps == 0 || minSteps == maxSteps else {
            throw IndexableStepError.noUnitStepSize
        }

        return Self((to.first - from.first) / maxSteps, (to.second - from.second) / maxSteps)
    }
}

public enum IndexableStepError: Error {
    case fromAndToAreEqual
    case noUnitStepSize
}
