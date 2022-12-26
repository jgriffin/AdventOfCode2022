import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day19Tests: XCTestCase {
    func testBestOutputDynamicExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = blueprint1.bestGeodeOutputDynamic()
        XCTAssertEqual(result, 9)
    }

    func testBestOutputAStarExample1() async throws {
        let input = try Self.inputParser.parse(Self.example)
        let blueprint1 = input.first!

        let result = await blueprint1.bestGeodeOutputAStar()
        XCTAssertEqual(result?.cost, 9)
    }

    struct State: Hashable, Updatable, CustomStringConvertible {
        var minutesRemaining: Int
        var robotsOfType: [Material: Int]
        var resources: [Material: Int]

        func nextNoBuilding() -> State? {
            updating {
                $0.minutesRemaining -= 1
                $0.resources.merge(robotsOfType) { lhs, rhs in lhs + rhs }
            }
        }

        func afterBuilding(_ robot: Robot) -> State? {
            guard hasResourcesFor(robot) else { return nil }

            return updating {
                $0.minutesRemaining -= 1
                $0.resources.merge(robotsOfType) { lhs, rhs in lhs + rhs }
                
                $0.robotsOfType[robot.type, default: 0] += 1
                $0.resources.merge(robot.requires) { lhs, rhs in lhs - rhs }
            }
        }

        func hasResourcesFor(_ robot: Robot) -> Bool {
            robot.requires.allSatisfy { material, amount in
                amount <= resources[material, default: 0]
            }
        }

        var description: String {
            "mins: \(minutesRemaining) - robots: \(robotsOfType.description) resources: \(resources.description)"
        }

        static let initial = State(minutesRemaining: 24, robotsOfType: [.ore: 1], resources: [:])
    }

    struct Blueprint: Identifiable, Equatable {
        let id: Int
        let robots: [Robot]

        func bestGeodeOutputDynamic() -> Int {
            let bestForState: (State) -> Int = memoize { recurse, state in
                guard state.minutesRemaining > 0 else {
                    return state.resources[.geode] ?? 0
                }

                let neighbors = neighborsOf(state)
                let bests = neighbors.map(recurse)
                let best = bests.max() ?? 0
                return best
            }
            return bestForState(.initial)
        }

        func bestGeodeOutputAStar() async -> (cost: Int, path: [State])? {
            let solver = AStartSolverAsync(
                hScore: hScore,
                neighborGenerator: neighborsOf,
                stepCoster: stepCost,
                minimizeScore: false,
                isAtGoal: { $0.minutesRemaining == 0 })

            var best: AStartSolverAsync<State>.Solution?
            for await solution in await solver.solve(start: .initial) {
                print("bestSoFar:", solution.cost)
                best = solution
            }

            return best
        }

        func hScore(_ state: State) -> Int {
            guard state.minutesRemaining > 0 else { return 0 }

            // initial boost
            let initial = State.initial.minutesRemaining - state.minutesRemaining
            if initial < 5 {
                return 1
            }

            let typeAndFactor: [(type: Material, factor: Int)] = [
                (.geode, 1),
                (.obsidian, 10),
//                (.clay, 20),
//                (.ore, 40),
            ]

            return typeAndFactor.reduce(0) { result, typeAndFactor in
                let quotRemain = state.robotsOfType[typeAndFactor.type, default: 0].quotientAndRemainder(dividingBy: typeAndFactor.factor)
                let factor = quotRemain.quotient + (quotRemain.remainder > 0 ? 1 : 0)
                return result + factor * (state.minutesRemaining - 1)
            }
        }

        func neighborsOf(_ state: State) -> [State] {
            guard state.minutesRemaining > 0 else { return [] }

            var result = robots.compactMap(state.afterBuilding)
            if let next = state.nextNoBuilding() {
                result.append(next)
            }
            return result
        }

        func stepCost(from: State, to: State) -> Int {
            from.robotsOfType[.geode, default: 0]
        }
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
