import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day16Tests: XCTestCase {
    // MARK: - Part 1
    
    func testBestValveCombinationExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let best = await volcano.bestValveCombinationAsync()
        XCTAssertEqual(best?.count, 30 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 1651)
    }
    
    func testBestValveCombinationInput() throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let best = volcano.bestValveCombination()
        XCTAssertEqual(best?.count, 30 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 1923)
    }

    func testBestValveCombinationAsyncInput() async throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let best = await volcano.bestValveCombinationAsync()
        XCTAssertEqual(best?.count, 30 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 1923)
    }

    // MARK: - Part 1 dynamic

    func testBestValveCombinationDynamicExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let pressureMaximizer = PressureMaximizer(volcano.valvesById)
        let start = ValveState(
            minutesRemaining: 30,
            open: .init(),
            current: volcano.valvesById["AA"]!,
            current2: nil
        )
        
        let best = await pressureMaximizer.highestPressure(start)
        XCTAssertEqual(best, 1651)
    }

    func testBestValveCombinationDynamicInput() async throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let pressureMaximizer = PressureMaximizer(volcano.valvesById)
        let start = ValveState(
            minutesRemaining: 30,
            open: .init(),
            current: volcano.valvesById["AA"]!,
            current2: nil
        )
        
        let best = await pressureMaximizer.highestPressureTaskGroup(start)
        XCTAssertEqual(best, 1923)
    }

    // MARK: - Part 2

    func testBestValveCombinationElephantExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let best = await volcano.bestValveCombininationWithElephantAsync()
        XCTAssertEqual(best?.count, 26 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 1707)
    }
    
    func testBestValveCombinationElephantAyncExample() async throws {
        let volcano = try Self.volcanoParser.parse(Self.example)
        let best = await volcano.bestValveCombininationWithElephantAsync()
        XCTAssertEqual(best?.count, 26 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 1707)
    }
    
    func testBestValveCombinationElephantAyncInput() async throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        let best = await volcano.bestValveCombininationWithElephantAsync()
        XCTAssertEqual(best?.count, 26 + 1)
        XCTAssertEqual(best?.first?.flowToEnd, 0)
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
        var valvesByFlowRate: [Valve]
        var valvesById: [Valve.ID: Valve]

        init(valves: [Valve]) {
            self.valvesByFlowRate = valves.sorted(by: \.flowRate).reversed()
            self.valvesById = Dictionary(uniqueKeysWithValues: valves.map { ($0.id, $0) })
        }
        
        // MARK: - state
        
        func hScore(_ state: State) -> Int {
            var openableFlowRates = valvesByFlowRate.compactMap { valve -> Int? in
                guard !state.open.contains(valve.id) else { return nil }
                return valve.flowRate
            }.makeIterator()

            var maxFlowRemaining = 0
            var minutesRemaining = state.minutesRemaining
            while minutesRemaining > 0 {
                guard let nextFlowRate = openableFlowRates.next() else { break }
                maxFlowRemaining += nextFlowRate * minutesRemaining
                
                if state.current2 != nil {
                    guard let nextFlowRate = openableFlowRates.next() else { break }
                    maxFlowRemaining += nextFlowRate * minutesRemaining
                }

                minutesRemaining -= 2
            }
            
            return state.flowToEnd + maxFlowRemaining
        }
        
        func currentActions(_ state: State) -> [State.Action] {
            var actions: [State.Action] = state.current.leadsTo.map { .moveTo(valvesById[$0]!) }
            if !state.open.contains(state.current.id) {
                actions.append(.openValve)
            }
            return actions
        }
        
        func current2Actions(_ state: State) -> [State.Action]? {
            guard let current2 = state.current2 else { return nil }
            var actions: [State.Action] = current2.leadsTo.map { .moveTo(valvesById[$0]!) }
            if !state.open.contains(current2.id) {
                actions.append(.openValve)
            }
            return actions
        }

        func neighbors(_ state: State) -> [State] {
            guard state.minutesRemaining > 0 else { return [] }

            let currentActions = currentActions(state)
            
            guard let current2Actions = current2Actions(state) else {
                return currentActions.map { state.afterActions($0, action2: nil) }
            }
            
            return product(currentActions, current2Actions).map {
                state.afterActions($0.first!, action2: $0.last!)
            }
        }

        func bestValveCombination() -> [State]? {
            let solver = AStarSolver(
                hScorer: hScore,
                neighborGenerator: neighbors
            )
            
            let start = State(
                minutesRemaining: 30,
                current: valvesById["AA"]!,
                current2: nil,
                open: .init(),
                flowToEnd: 0
            )
            
            let best = solver.solve(
                from: start,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )
            
            return best
        }

        func bestValveCombinationAsync() async -> [State]? {
            let solver = AStarSolverAsync(
                hScorer: hScore,
                neighborGenerator: neighbors
            )
            
            let start = State(
                minutesRemaining: 30,
                current: valvesById["AA"]!,
                current2: nil,
                open: .init(),
                flowToEnd: 0
            )
            
            let best = await solver.solve(
                from: start,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )
            
            return best
        }

        func bestValveCombininationWithElephantAsync() async -> [State]? {
            let solver = AStarSolverAsync(
                hScorer: hScore,
                neighborGenerator: neighbors
            )
            
            let start = State(
                minutesRemaining: 26,
                current: valvesById["AA"]!,
                current2: valvesById["AA"]!,
                open: .init(),
                flowToEnd: 0
            )
            
            let best = await solver.solve(
                from: start,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )
            
            return best
        }
    }
    
    struct State: Hashable {
        let minutesRemaining: Int
        let current: Valve
        let current2: Valve?
        let open: Set<Valve.ID>
        let flowToEnd: Int
        
        enum Action {
            case openValve
            case moveTo(Valve)
        }
        
        func afterActions(_ action: Action, action2: Action?) -> State {
            var newCurrent = current
            var newOpen = open
            var newFlowToEnd = flowToEnd
            
            switch action {
            case .openValve:
                if newOpen.insert(current.id).inserted {
                    newFlowToEnd += (minutesRemaining - 1) * current.flowRate
                }
            case let .moveTo(valve):
                newCurrent = valve
            }
            
            guard var newCurrent2 = current2 else {
                return .init(
                    minutesRemaining: minutesRemaining - 1,
                    current: newCurrent,
                    current2: nil,
                    open: newOpen,
                    flowToEnd: newFlowToEnd
                )
            }
            
            switch action2 {
            case nil: break
            case .openValve:
                if newOpen.insert(newCurrent2.id).inserted {
                    newFlowToEnd += (minutesRemaining - 1) * newCurrent2.flowRate
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
                open: newOpen,
                flowToEnd: newFlowToEnd
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
    
    static let valveIdParser = Parse(Valve.ID.init) {
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
        XCTAssertEqual(volcano.valvesByFlowRate.count, 10)
    }
    
    func testParseInput() throws {
        let volcano = try Self.volcanoParser.parse(Self.input)
        XCTAssertEqual(volcano.valvesByFlowRate.count, 51)
    }
}
