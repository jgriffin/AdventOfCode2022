//
// Created by John Griffin on 12/26/22
//

import Combine
import Foundation
import HeapModule

public actor AStarSolverAsync<State: Hashable> {
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
    public typealias NeighborGenerator = (_ state: State) async -> AnySequence<State>

    // return the legal moves from a state
    public typealias StepCoster = (_ from: State, _ to: State) -> Int

    // returns true if we should stop
    // getCost can be used to get the co
    public typealias IsAtGoal = (State) -> Bool

    // MARK: - initialization

    public init(
        hScore: @escaping HScorer,
        neighborGenerator: @escaping (State) async -> some Sequence<State>,
        stepCoster: @escaping StepCoster,
        minimizeScore: Bool,
        isAtGoal: @escaping IsAtGoal
    ) {
        self.hScore = hScore
        self.neighborGenerator = { state in AnySequence(await neighborGenerator(state)) }
        self.stepCoster = stepCoster
        self.isAtGoal = isAtGoal
        self.minimizeScore = minimizeScore
    }

    // MARK: - dependencies

    let hScore: HScorer
    let neighborGenerator: NeighborGenerator
    let stepCoster: StepCoster
    let isAtGoal: IsAtGoal
    let minimizeScore: Bool

    // MARK: - internal state

    var openSet = Set<State>()
    var closedSet = Set<State>()

    var cameFrom = [State: State]()
    var gScore = [State: Int]()
    var fScore = [State: Int]()

    // fScoreQueue
    // updating value priorities is a little expensive,
    // so we'll just allow extra (higher) priorities that are no longer open
    var fScoreQueue = Heap<PriorityNode<State>>()

    // MARK: - solve

    public typealias Solution = (cost: Int, path: [State])
    var bestSoFar: Solution?

    public func solve(start: State) async -> AnyPublisher<Solution, Never> {
        openSet.insert(start)
        gScore[start] = 0

        let hScore = await hScore(start)
        fScore[start] = hScore
        fScoreQueue.insert(.init(start, priority: hScore))

        let output = PassthroughSubject<Solution, Never>()

        var task: Task<Void, Never>?
        task = Task {
            while let current = bestOpenFScore() {
                guard !Task.isCancelled else {
                    output.send(completion: .finished)
                    return
                }
                let currentGScore = gScore[current]!

                if isAtGoal(current) {
                    if minimizeScore ?
                        currentGScore < bestSoFar?.cost ?? .max :
                        currentGScore > bestSoFar?.cost ?? .min
                    {
                        let path = reconstuctPath(to: current, cameFrom: cameFrom)
                        bestSoFar = (currentGScore, path)
                        output.send(bestSoFar!)
                    }
                }

                openSet.remove(current)

                await tryNeighbors(current, currentGScore: currentGScore)

                closedSet.insert(current)
            }
            
            print("all solutions explored")
            output.send(completion: .finished)
        }

        var subscriberCount = 0

        return output
            .handleEvents(
                receiveSubscription: { _ in
                    subscriberCount += 1
                },
                receiveCancel: {
                    task?.cancel()
                }
            )
            .share()
            .eraseToAnyPublisher()
    }

    func tryNeighbors(_ current: State, currentGScore: Int) async {
        let neighbors = await neighborGenerator(current)
        for neighbor in neighbors {
            let stepCost = stepCoster(current, neighbor)
            let neighborGScore = currentGScore + stepCost

            guard minimizeScore ?
                neighborGScore < gScore[neighbor, default: .max] :
                neighborGScore > gScore[neighbor, default: .min]
            else {
                continue
            }

            let neighborHScore = await hScore(neighbor)
            let neighborFScore = neighborGScore + neighborHScore

            cameFrom[neighbor] = current
            gScore[neighbor] = neighborGScore
            fScore[neighbor] = neighborFScore
            fScoreQueue.insert(.init(neighbor, priority: neighborFScore))

            // Might already be in the open set
            openSet.insert(neighbor)
        }
    }

    // MARK: - helpers

    struct PriorityNode<State>: Comparable {
        let state: State
        let priority: Int

        init(_ state: State, priority: Int) {
            self.state = state
            self.priority = priority
        }

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.priority < rhs.priority }
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.priority == rhs.priority }
    }

    func bestOpenFScore() -> State? {
        var nextState: State?
        repeat {
            nextState = (minimizeScore ? fScoreQueue.popMin() : fScoreQueue.popMax())?.state
        } while nextState.flatMap { !openSet.contains($0) } == true

        return nextState
    }

    func reconstuctPath(to: State, cameFrom: [State: State]) -> [State] {
        var path = [to]
        var current = to
        while let from = cameFrom[current] {
            path.append(from)
            current = from
        }
        return path
    }
}
