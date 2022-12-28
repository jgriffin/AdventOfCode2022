import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day19Tests: XCTestCase {
    // MARK: - part 1 - dynamic

    func testBestOutputDynamicExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = blueprint1.bestGeodeOutputDynamic()
        XCTAssertEqual(result.geodes, 9)
    }

    func testBestOutputDynamicExample() async throws {
        let blueprints = try Self.inputParser.parse(Self.example)
        let results = await Blueprint.geodeOutputForBlueprints(blueprints)

        let best = results.max(by: { lhs, rhs in lhs.geodes < rhs.geodes })
        XCTAssertEqual(best, .init(id: 2, geodes: 12))

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 33)
    }

    func testBestOutputDynamicInput() async throws {
        let blueprints = try Self.inputParser.parse(Self.input)
        let results = await Blueprint.geodeOutputForBlueprints(blueprints)

        let totalQuality = results.map(\.qualityLevel).reduce(0,+)
        XCTAssertEqual(totalQuality, 1616)
    }

    // MARK: - part 1 - A*

    func testBestOutputAStarExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = await blueprint1.bestGeodeOutputAStar()
        XCTAssertEqual(result?.cost, 9)
    }

    func testBestOutputAStarInput1() async throws {
        let input = try Self.inputParser.parse(Self.input)
        let blueprint1 = input.first!

        let result = await blueprint1.bestGeodeOutputAStar()
        XCTAssertEqual(result?.cost, 9)
    }
}

extension Day19Tests {
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
            self.maxNeedByMaterial = robots.map(\.requires)
                .reduce([:]) { result, requires in
                    result.merging(requires) { lhs, rhs in max(lhs, rhs) }
                }
        }

        func bestGeodeOutputAStar() async -> (cost: Int, path: [State])? {
            let solver = AStartSolverAsync(
                hScore: hScore,
                neighborGenerator: neighborsOf,
                stepCoster: stepCost,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 }
            )

            var best: AStartSolverAsync<State>.Solution?
            for await solution in await solver.solve(start: .initial) {
                print("bestSoFar:", solution.cost)
                best = solution
            }

            return best
        }

        func hScore(_ state: State) -> Int {
            guard state.minutesRemaining > 0 else { return 0 }

            let geodeScore = state.robotsOfType[.geode, default: 0] * state.minutesRemaining
            return geodeScore
        }

        func neighborsOf(_ state: State) -> [State] {
            guard state.minutesRemaining > 0 else { return [] }

            // don't produce more than we can ever need
            let usefulRobots = robots.filter { robot in
                robot.type == .geode ||
                    state.robotsOfType[robot.type, default: 0] < maxNeedByMaterial[robot.type, default: 0]
            }

            var result = usefulRobots.compactMap(state.afterBuilding)
            if let next = state.noBuildingTilEnd() {
                result.append(next)
            }
            return result
        }

        func stepCost(from: State, to: State) -> Int {
            from.robotsOfType[.geode, default: 0] * (from.minutesRemaining - to.minutesRemaining)
        }

        // MARK: - dynamic

        func bestGeodeOutputDynamic() -> GeodeOutput {
            let bestForState: (State) -> Int = memoize { recurse, state in
                guard state.minutesRemaining > 0 else {
                    return state.resources[.geode] ?? 0
                }

                let neighbors = neighborsOf(state)
                let bests = neighbors.map(recurse)
                let best = bests.max() ?? 0
                return best
            }
            return GeodeOutput(id: id, geodes: bestForState(.initial))
        }

        static func geodeOutputForBlueprints(_ blueprints: [Blueprint]) async -> [GeodeOutput] {
            await withTaskGroup(of: GeodeOutput.self) { group in
                for blueprint in blueprints {
                    group.addTask {
                        blueprint.bestGeodeOutputDynamic()
                    }
                }

                return await group.reduce(into: [GeodeOutput]()) { results, result in results.append(result) }
            }
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

        static let initial = State(minutesRemaining: 24, robotsOfType: [.ore: 1], resources: [:])
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

    static let blueprintParser = Parse(Blueprint.init) {
        "Blueprint "; Int.parser(); ":"; Whitespace()
        robotParser.many(separator: Whitespace())
    }

    static let robotParser = Parse { (type: Material, materialAmounts: [(Int, Material)]) -> Robot in
        Robot(type: type,
              requires: Dictionary(uniqueKeysWithValues: materialAmounts.map { ($0.1, $0.0) }))

    } with: {
        Whitespace(); "Each "; materialParser; " robot costs "
        Parse {
            Int.parser(); " "; materialParser
        }.many(separator: " and ")
        "."
    }

    static let materialParser = OneOf {
        "ore".map { Material.ore }
        "clay".map { Material.clay }
        "obsidian".map { Material.obsidian }
        "geode".map { Material.geode }
    }

    static let inputParser = blueprintParser.many(separator: Whitespace()).skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertNotNil(input)
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertNotNil(input)
    }
}
