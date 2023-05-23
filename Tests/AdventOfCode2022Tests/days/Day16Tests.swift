import AdventOfCode2022
import Algorithms
import EulerTools
import Parsing
import XCTest

final class Day16Tests: XCTestCase {
    // MARK: - Part 1

    func testBestValveCombinationAsyncExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let best = await volcano.bestValveCombinationAsync()
        XCTAssertEqual(best?.path.count, 30 + 1)
        XCTAssertEqual(best?.cost, 1651)
    }

    func testBestValveCombinationAsyncInput() async throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let best = await volcano.bestValveCombinationAsync()
        XCTAssertEqual(best?.path.count, 30 + 1)
        XCTAssertEqual(best?.cost, 1923)
    }

    // MARK: - Part 2

    func testBestValveCombinationElephantExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let best = await volcano.bestValveCombinationWithElephantAsync()
        XCTAssertEqual(best?.path.count, 26 + 1)
        XCTAssertEqual(best?.cost, 1707)
    }

    func testBestValveCombinationElephantAyncInput() async throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let best = await volcano.bestValveCombinationWithElephantAsync()
        XCTAssertEqual(best?.path.count, 26 + 1)
        XCTAssertEqual(best?.cost, 2594)
    }
}

extension Day16Tests {
    struct Valve: Hashable {
        typealias ID = String
        let id: ID
        let flowRate: Int
        let leadsTo: [Valve.ID]
    }

    struct Volcano {
        var valvesById: [Valve.ID: Valve]
        var nonZeroValves: Set<Valve>

        init(valves: [Valve]) {
            valvesById = Dictionary(uniqueKeysWithValues: valves.map { ($0.id, $0) })
            nonZeroValves = valves.filter { $0.flowRate > 0 }.asSet
        }

        // MARK:

        func bestValveCombination() -> [State]? {
            let solver = AStarSolver(
                hScorer: hScore,
                neighborGenerator: neighbors
            )

            let start = State(
                minutesRemaining: 30,
                current: valvesById["AA"]!,
                current2: nil,
                open: .init()
            )

            let best = solver.solve(
                from: start,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )

            return best
        }

        func bestValveCombinationAsync() async -> (cost: Int, path: [State])? {
            let start = State(
                minutesRemaining: 30,
                current: valvesById["AA"]!,
                current2: nil,
                open: .init()
            )

            let solver = solver()
            let bestSolution = await solver.solve(start: start).values.first(where: { _ in true })
            return bestSolution
        }

        func bestValveCombinationWithElephantAsync() async -> (cost: Int, path: [State])? {
            let start = State(
                minutesRemaining: 26,
                current: valvesById["AA"]!,
                current2: valvesById["AA"]!,
                open: .init()
            )

            let solver = solver()
            var bestSolution: (cost: Int, path: [State])?
            for await solution in await solver.solve(start: start).values.prefix(1) {
                bestSolution = solution
                print("bestCostSoFar:", solution.cost)
            }

            return bestSolution
        }

        // MARK: - AStar helpers

        func solver() -> AStarSolverAsync<State> {
            AStarSolverAsync(
                hScore: hScore,
                neighborGenerator: neighbors,
                stepCoster: stepCost,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )
        }

        func stepCost(from: State, to: State) -> Int {
            to.open.subtracting(from.open).lazy
                .map { $0.flowRate * to.minutesRemaining }
                .reduce(0, +)
        }

        func hScore(_ state: State) -> Int {
            guard state.minutesRemaining > 1 else { return 0 }
            var openableValves = nonZeroValves.subtracting(state.open).sorted(by: \.flowRate).reversed().makeIterator()

            let minutes = stride(from: state.minutesRemaining - 1, to: 0, by: -2)
            return minutes.reduce(into: 0) { result, minute in
                if let next = openableValves.next() {
                    result += minute * next.flowRate
                }
                if state.current2 != nil, let next = openableValves.next() {
                    result += minute * next.flowRate
                }
            }
        }

        func neighbors(_ state: State) -> AnySequence<State> {
            guard state.minutesRemaining > 0 else { return AnySequence([]) }

            let currentActions = actionsFrom(state.current, in: state)
            let current2Actions: [State.Action?] = state.current2.flatMap { actionsFrom($0, in: state) } ?? [nil]

            return AnySequence(
                product(currentActions, current2Actions).compactMap {
                    state.afterActions($0.0, action2: $0.1)
                }
            )
        }

        func actionsFrom(_ current: Valve, in state: State) -> [State.Action] {
            let maybeOpenValve: [State.Action] = current.flowRate > 0 && !state.open.contains(current) ?
                [.openValve] : []

            return current.leadsTo
                .reduce(into: maybeOpenValve) { result, valveId in
                    result.append(.moveTo(valvesById[valveId]!))
                }
        }
    }

    struct State: Hashable {
        let minutesRemaining: Int
        let current: Valve
        let current2: Valve?
        let open: Set<Valve>

        enum Action {
            case openValve
            case moveTo(Valve)
        }

        func afterActions(_ action: Action, action2: Action?) -> State? {
            var newCurrent = current
            var newOpen = open

            switch action {
            case .openValve:
                guard newOpen.insert(current).inserted else {
                    return nil
                }
            case let .moveTo(valve):
                newCurrent = valve
            }

            guard var newCurrent2 = current2 else {
                return .init(
                    minutesRemaining: minutesRemaining - 1,
                    current: newCurrent,
                    current2: nil,
                    open: newOpen
                )
            }

            switch action2 {
            case nil: break
            case .openValve:
                guard newOpen.insert(newCurrent2).inserted else {
                    return nil
                }
            case let .moveTo(valve):
                newCurrent2 = valve
            }

            // pick an order to reduce branching
            if newCurrent.id > newCurrent2.id {
                (newCurrent, newCurrent2) = (newCurrent2, newCurrent)
            }

            return .init(
                minutesRemaining: minutesRemaining - 1,
                current: newCurrent,
                current2: newCurrent2,
                open: newOpen
            )
        }
    }
}

extension Day16Tests {
    static let input = resourceURL(filename: "Day16Input.txt")!.readContents()!

    static let example: String =
        """
        Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
        Valve BB has flow rate=13; tunnels lead to valves CC, AA
        Valve CC has flow rate=2; tunnels lead to valves DD, BB
        Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
        Valve EE has flow rate=3; tunnels lead to valves FF, DD
        Valve FF has flow rate=0; tunnels lead to valves EE, GG
        Valve GG has flow rate=0; tunnels lead to valves FF, HH
        Valve HH has flow rate=22; tunnel leads to valve GG
        Valve II has flow rate=0; tunnels lead to valves AA, JJ
        Valve JJ has flow rate=21; tunnel leads to valve II
        """

    // MARK: - parser

    static let valveIdParser = Parse(input: Substring.self, Valve.ID.init) {
        Prefix(2, while: { ("A" ... "Z").contains($0) })
    }

    static let valveParser = Parse {
        Valve(id: $0, flowRate: $1, leadsTo: $2)
    } with: {
        "Valve "
        valveIdParser
        " has flow rate="
        Int.parser()
        OneOf { "; tunnels lead to valves "; "; tunnel leads to valve " }
        valveIdParser.many(separator: ", ")
    }

    static let volcanoParser = valveParser.manyByNewline().skipTrailingNewlines().map(Volcano.init)

    func testParseExample() throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        XCTAssertEqual(volcano.valvesById.count, 10)
    }

    func testParseInput() throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        XCTAssertEqual(volcano.valvesById.count, 51)
    }
}
