//
//
// Created by John Griffin on 1/31/21
//

import EulerTools
import Foundation
import HeapModule

public struct AStarSolverAsync<State: Hashable,
    NeighborStates: Sequence> where NeighborStates.Element == State
{
    // HScorer
    // heuristic function that estimates the cost of the cheapest path from n to the goal.
    // A* terminates when the path it chooses to extend is a path from start to goal or
    // if there are no paths eligible to be extended.
    // The heuristic function is problem-specific.
    // If the heuristic function is admissible, meaning that it never overestimates the
    // actual cost to get to the goal, A* is guaranteed to return
    // a least-cost path from start to goal.
    public typealias HScorer = (_ state: State) async -> Int

    // return the legal moves from a state
    public typealias NeighborStatesGenerator = (_ state: State) async -> NeighborStates

    // return the legal moves from a state
    public typealias StepCoster = (_ from: State, _ to: State) -> Int

    let hScorer: HScorer
    let neighborGenerator: NeighborStatesGenerator
    let stepCoster: StepCoster?

    struct PriorityNode<State>: Comparable
    {
        let state: State
        let priority: Int

        init(_ state: State, priority: Int)
        {
            self.state = state
            self.priority = priority
        }

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.priority < rhs.priority }
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.priority == rhs.priority }
    }

    public init(hScorer: @escaping HScorer,
                neighborGenerator: @escaping NeighborStatesGenerator,
                stepCoster: StepCoster? = nil)
    {
        self.hScorer = hScorer
        self.neighborGenerator = neighborGenerator
        self.stepCoster = stepCoster
    }

    // MARK: Solve

    public func solve(from start: State,
                      goal: State) async -> [State]?
    {
        await solve(from: start, minimizeScore: true, isAtGoal: { $0 == goal })
    }

    public func solve(from start: State,
                      minimizeScore: Bool,
                      isAtGoal: (State) -> Bool) async -> [State]?
    {
        var openSet = Set<State>([start])
        var closedSet = Set<State>()

        var cameFrom = [State: State]()

        // cheapest path known from start so far
        var gScore: [State: Int] = [start: 0]

        // For node n, fScore[n] := gScore[n] + h(n).
        // fScore[n] represents our current best guess as to
        // how short a path from start to finish can be if it goes through n.
        var fScore: [State: Int] = [start: await hScorer(start)]

        // fScoreQueue
        // updating value priorities is a little expensive,
        // so we'll just allow extra (higher) priorities that are no longer open
        var fScoreQueue = Heap<PriorityNode<State>>()
        fScoreQueue.insert(.init(start, priority: fScore[start]!))

        func bestOpenFScore() -> State?
        {
            while let nextState = (minimizeScore ? fScoreQueue.popMin() : fScoreQueue.popMax())?.state
            {
                guard openSet.contains(nextState)
                else
                { continue
                }
                return nextState
            }
            return nil
        }

        // take lowest fScore
        while let current = bestOpenFScore()
        {
            if isAtGoal(current)
            {
                return reconstuctPath(to: current,
                                      cameFrom: cameFrom)
            }

            openSet.remove(current)

            let neighbors = await neighborGenerator(current)

            let currentGScore = gScore[current]!

            await withTaskGroup(of: (state: State, gScore: Int, hStore: Int).self)
            { group in
                for neighbor in neighbors
                {
                    group.addTask
                    {
                        let cost = stepCoster.map { $0(current, neighbor) } ?? 1
                        let neighborGScore = currentGScore + cost
                        let neighborHScore = await hScorer(neighbor)
                        return (neighbor, neighborGScore, neighborHScore)
                    }
                }

                var newNeighbors: [State] = []

                for await neighbor in group
                {
                    guard minimizeScore ?
                        neighbor.gScore < gScore[neighbor.state, default : .max]:
                        neighbor.gScore > gScore[neighbor.state, default: .min]
                    else
                    {
                        continue
                    }

                    cameFrom[neighbor.state] = current
                    gScore[neighbor.state] = neighbor.gScore

                    let neighborFScore = neighbor.gScore + neighbor.hStore
                    fScore[neighbor.state] = neighborFScore
                    fScoreQueue.insert(.init(neighbor.state, priority: neighborFScore))

                    newNeighbors.append(neighbor.state)
                }

                // Might already be in the open set
                openSet.formUnion(newNeighbors)
            }

            closedSet.insert(current)
        }

        print("solutions not found")
        return nil
    }

    func reconstuctPath(to: State, cameFrom: [State: State]) -> [State]
    {
        var path = [to]
        var current = to
        while let from = cameFrom[current]
        {
            path.append(from)
            current = from
        }
        return path
    }
}
