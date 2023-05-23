import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day19Tests: XCTestCase {
    // MARK: - part 1 - dynamic

    func testBestOutputDynamicExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = blueprint1.bestGeodeOutputDynamic(.initial24)
        XCTAssertEqual(result.geodes, 9)
    }

    func testBestOutputDynamicExample() async throws {
        let blueprints = try Self.inputParser.parse(Self.example)
        let results = await geodeOutputForBlueprintsDynamic(blueprints, .initial24)

        let best = results.max(by: { lhs, rhs in lhs.geodes < rhs.geodes })
        XCTAssertEqual(best, .init(id: 2, geodes: 12))

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 33)
    }

    func testBestOutputDynamicInput() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let results = await geodeOutputForBlueprintsDynamic(blueprints, .initial24)

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 1616)
    }

    // MARK: - part 1 - A*

    func testBestOutputAStarExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = await blueprint1.bestGeodeOutputAStar(.initial24)
        XCTAssertEqual(result?.cost, 9)
    }

    func testBestOutputAStarExample() async throws {
        let blueprints = try Self.inputParser.parse(Self.example)

        let results = await geodeOutputForBlueprintsAStar(blueprints, .initial24)
        XCTAssertEqual(results.sorted(by: \.id), [.init(id: 1, geodes: 9), .init(id: 2, geodes: 12)])

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 33)
    }

    func testBestOutputAStarInput() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let results = await geodeOutputForBlueprintsAStar(blueprints, .initial24)
        XCTAssertEqual(results.sorted(by: \.id), [
            .init(id: 1, geodes: 2),
            .init(id: 2, geodes: 0),
            .init(id: 3, geodes: 3),
            .init(id: 4, geodes: 3),
            .init(id: 5, geodes: 5),
            .init(id: 6, geodes: 4),
            .init(id: 7, geodes: 1),
            .init(id: 8, geodes: 4),
            .init(id: 9, geodes: 2),
            .init(id: 10, geodes: 0),
            .init(id: 11, geodes: 6),
            .init(id: 12, geodes: 5),
            .init(id: 13, geodes: 1),
            .init(id: 14, geodes: 3),
            .init(id: 15, geodes: 2),
            .init(id: 16, geodes: 9),
            .init(id: 17, geodes: 4),
            .init(id: 18, geodes: 7),
            .init(id: 19, geodes: 0),
            .init(id: 20, geodes: 2),
            .init(id: 21, geodes: 0),
            .init(id: 22, geodes: 1),
            .init(id: 23, geodes: 0),
            .init(id: 24, geodes: 8),
            .init(id: 25, geodes: 2),
            .init(id: 26, geodes: 16),
            .init(id: 27, geodes: 7),
            .init(id: 28, geodes: 0),
            .init(id: 29, geodes: 1),
            .init(id: 30, geodes: 0)
        ])

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 1616)
    }

    // MARK: - part 2 - dynamic

    func testBestOutput32DynamicExample() async throws {
        let blueprints = try Self.inputParser.parse(Self.example)
        let results = await geodeOutputForBlueprintsDynamic(blueprints, .initial32)
        XCTAssertEqual(results.map(\.geodes).sorted().suffix(3), [56, 62])

        let geodesProduct = results.map(\.geodes).reduce(1,*)
        XCTAssertEqual(geodesProduct, 3472)
    }

    func testBestOutput32DynamicInput() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let results = await geodeOutputForBlueprintsDynamic(blueprints, .initial32)

        let geodesProduct = results.map(\.geodes).reduce(1,*)
        XCTAssertEqual(geodesProduct, 0)
    }

    // MARK: - part 2 - A*

    func testBestOutput32AStarExample() async throws {
        let blueprints = try Self.inputParser.parse(Self.example)
        let results = await geodeOutputForBlueprintsAStar(blueprints, .initial32)

        XCTAssertEqual(results.map(\.geodes).sorted().suffix(3), [56, 62])

        let geodesProduct = results.map(\.geodes).reduce(1,*)
        XCTAssertEqual(geodesProduct, 3472)
    }

    func testBestOutput32AStarInput() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let firstThreeBlueprints = blueprints.prefix(3).asArray
        let results = await geodeOutputForBlueprintsAStar(firstThreeBlueprints, .initial32)

        XCTAssertEqual(results.map(\.geodes).sorted(), [10, 29, 31])

        let geodesProduct = results.map(\.geodes).reduce(1,*)
        XCTAssertEqual(geodesProduct, 8990)
    }

    func testBestOutputAStar32InputIndividuallly() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let checks: [Blueprint.ID: Int] = [
            1: 29, 2: 10, 3: 31, 4: 31, 5: 44, 6: 33, 7: 21, 8: 40, 9: 28,
            10: 15, 11: 46, 12: 39, 13: 22, 14: 29, 15: 30, 16: 63, 17: 39, 18: 46, 19: 12,
            20: 28, 21: 8, 22: 22, 23: 17, 24: 46, 25: 29, 26: 71, 27: 52, 28: 10, 29: 19,
            30: 7
        ]

        for blueprint in blueprints {
            await measureTime(name: "id: \(blueprint.id)") {
                let result = await blueprint.bestGeodeOutputAStar(.initial32)
                XCTAssertEqual(result?.cost, checks[blueprint.id])
            }
        }
    }
}

extension Day19Tests {
    func geodeOutputForBlueprintsAStar(
        _ blueprints: [Blueprint],
        _ initialState: State
    ) async -> [GeodeOutput] {
        await withTaskGroup(of: GeodeOutput.self) { group in
            var results: [GeodeOutput] = []

            let processorCount = 5 // ProcessInfo().activeProcessorCount
            var concurrentTaskCount = 0

            for blueprint in blueprints {
                if concurrentTaskCount > processorCount {
                    if let result = await group.next() {
                        concurrentTaskCount -= 1
                        results.append(result)
                    }
                }
                concurrentTaskCount += 1
                group.addTask {
                    let result = await blueprint.bestGeodeOutputAStar(initialState)
                    return GeodeOutput(id: blueprint.id, geodes: result!.cost)
                }
            }

            return await group.reduce(into: results) { results, result in results.append(result) }
        }
    }

    func geodeOutputForBlueprintsDynamic(
        _ blueprints: [Blueprint],
        _ initialState: State
    ) async -> [GeodeOutput] {
        await withTaskGroup(of: GeodeOutput.self) { group in
            for blueprint in blueprints {
                group.addTask {
                    blueprint.bestGeodeOutputDynamic(initialState)
                }
            }

            return await group.reduce(into: [GeodeOutput]()) { results, result in results.append(result) }
        }
    }

    struct GeodeOutput: Equatable {
        let id: Blueprint.ID
        let geodes: Int
        var qualityLevel: Int { id * geodes }
    }

    struct Blueprint: Identifiable, Equatable {
        let id: Int
        let robots: [Robot]
        let maxNeedByMaterial: [Material: Int]

        init(id: Int, robots: [Robot]) {
            self.id = id
            self.robots = robots
            self.maxNeedByMaterial = robots.map(\.requires).reduce([:]) {
                $0.merging($1, uniquingKeysWith: max)
            }
        }

        func neighborsOf(_ state: State) -> [State] {
            guard state.minutesRemaining > 0 else { return [] }
            guard state.minutesRemaining > 1 else {
                return [state.noBuildingTilEnd()!]
            }

            let neighbors = robots
                .filter { robot in
                    if robot.type == .geode {
                        return true
                    }
                    return state.minutesRemaining > 2 &&
                        state.robotsOfType[robot.type, default: 0] < maxNeedByMaterial[robot.type, default: 0]
                }
                .compactMap(state.afterBuilding)

            guard state.minutesRemaining < 20 else {
                return neighbors
            }

            return neighbors + [state.noBuildingTilEnd()!]
        }

        // MARK: - A*

        func bestGeodeOutputAStar(_ initialState: State) async -> (cost: Int, path: [State])? {
            let solver = AStarSolverAsync(
                hScore: hScore,
                neighborGenerator: neighborsOf,
                stepCoster: stepCost,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )

            let best = await solver.solve(start: initialState).values.first(where: { _ in true })
            guard let best else {
                print("id: \(id) - no solution found")
                return nil
            }

            print("id: \(id), geodes: \(best.cost)")
            return best
        }

        let materialDiscount: [Material: Int] = [
            .geode: 1,
            .obsidian: 10,
            .clay: 20,
            .ore: 20
        ]

        func hScore(_ state: State) -> Int {
            state.robotsOfType[.geode, default: 0] * state.minutesRemaining +
                (state.minutesRemaining * (state.minutesRemaining - 1)) / 2
        }

        func stepCost(from: State, to: State) -> Int {
            from.robotsOfType[.geode, default: 0] * (from.minutesRemaining - to.minutesRemaining)
        }

        // MARK: - dynamic

        func bestGeodeOutputDynamic(_ initalState: State) -> GeodeOutput {
            var bestSoFar = 0

            let bestForState: (State) -> Int = memoize { recurse, state in
                guard state.minutesRemaining > 0 else {
                    let result = state.resources[.geode, default: 0]
                    if result > bestSoFar {
                        bestSoFar = result
                        print("\(id) - bestSoFar:", result)
                    }
                    return result
                }

                let neighbors = neighborsOf(state)
                let bests = neighbors.map(recurse)
                let best = bests.max() ?? 0
                return best
            }
            return GeodeOutput(id: id, geodes: bestForState(initalState))
        }
    }

    struct State: Hashable, Updatable, CustomStringConvertible {
        var minutesRemaining: Int
        var robotsOfType: [Material: Int]
        var resources: [Material: Int]

        func afterBuilding(_ robot: Robot) -> State? {
            let needs = robot.requires
                .compactMap { material, requires -> (Material, Int)? in
                    let need = max(0, requires - resources[material, default: 0])
                    guard need > 0 else { return nil }
                    return (material, need)
                }

            var timeBeforeBuilding = 0
            for (material, count) in needs {
                guard let rate = robotsOfType[material], rate > 0 else { return nil }
                let time = (count + rate - 1) / rate
                if time > timeBeforeBuilding {
                    timeBeforeBuilding = time
                }
            }

            guard timeBeforeBuilding + 1 < minutesRemaining else { return nil }

            return updating {
                $0.minutesRemaining -= timeBeforeBuilding + 1
                $0.robotsOfType[robot.type, default: 0] += 1
                $0.resources = resources
                    .merging(robotsOfType.mapValues { $0 * (timeBeforeBuilding + 1) }, uniquingKeysWith: +)
                    .merging(robot.requires, uniquingKeysWith: -)
            }
        }

        func noBuildingTilEnd() -> State? {
            guard minutesRemaining > 0 else { return nil }
            return State(
                minutesRemaining: 0,
                robotsOfType: robotsOfType,
                resources: resources.merging(robotsOfType.mapValues { $0 * minutesRemaining }, uniquingKeysWith: +)
            )
        }

        var description: String {
            "mins: \(minutesRemaining) - robots: \(robotsOfType.description) resources: \(resources.description)"
        }

        static let initial24 = State(minutesRemaining: 24, robotsOfType: [.ore: 1], resources: [:])
        static let initial32 = State(minutesRemaining: 32, robotsOfType: [.ore: 1], resources: [:])
    }

    struct Robot: Hashable {
        let type: Material
        let requires: [Material: Int]
    }

    enum Material: Hashable, CustomStringConvertible {
        case ore, clay, obsidian, geode

        var description: String {
            switch self {
            case .ore: return "ore"
            case .clay: return "clay"
            case .obsidian: return "obsidian"
            case .geode: return "geode"
            }
        }
    }
}

extension Day19Tests {
    static let input = resourceURL(filename: "Day19Input.txt")!.readContents()!

    static let example: String =
        """
        Blueprint 1:
          Each ore robot costs 4 ore.
          Each clay robot costs 2 ore.
          Each obsidian robot costs 3 ore and 14 clay.
          Each geode robot costs 2 ore and 7 obsidian.

        Blueprint 2:
          Each ore robot costs 2 ore.
          Each clay robot costs 3 ore.
          Each obsidian robot costs 3 ore and 8 clay.
          Each geode robot costs 3 ore and 12 obsidian.
        """

    // MARK: - parser

    static let robotParser: some Parser<Substring.UTF8View, Robot> = Parse(input: Substring.UTF8View.self) {
        (type: Material, materialAmounts: [(Int, Material)]) -> Robot in
        Robot(type: type,
              requires: Dictionary(uniqueKeysWithValues: materialAmounts.map { ($0.1, $0.0) }))

    } with: {
        Whitespace(); "Each ".utf8; materialParser; " robot costs ".utf8
        Many { Int.parser(); " ".utf8; materialParser } separator: { " and ".utf8 }
        ".".utf8
    }

    static let blueprintParser: some Parser<Substring.UTF8View, Blueprint> = Parse(Blueprint.init) {
        "Blueprint ".utf8; Int.parser(); ":".utf8; Whitespace()
        Many { robotParser } separator: { Whitespace() }
    }

    static let materialParser = OneOf(input: Substring.UTF8View.self, output: Material.self) {
        "ore".utf8.map { Material.ore }
        "clay".utf8.map { Material.clay }
        "obsidian".utf8.map { Material.obsidian }
        "geode".utf8.map { Material.geode }
    }

    static let inputParser = Many { blueprintParser } separator: { Whitespace() }.skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertNotNil(input)
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertNotNil(input)
    }
}
