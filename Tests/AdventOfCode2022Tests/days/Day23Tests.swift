import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day23Tests: XCTestCase {
    func testDoRoundSmallExample() throws {
        let grove = try Self.inputParser.parse(Self.smallExample)

        let rounds = (1 ... 3).reductions(grove) { result, _ in
            result.afterRound()
        }

        XCTAssertEqual(rounds.count, 4)
    }

    func testDoRoundExample() throws {
        let grove = try Self.inputParser.parse(Self.example)

        let rounds = (1 ... 10).reductions(grove) { result, _ in
            result.afterRound()
        }

        XCTAssertEqual(rounds.last?.emptyGroundTiles, 110)
    }

    func testDoRoundInput() throws {
        let grove = try Self.inputParser.parse(Self.input)

        let rounds = (1 ... 10).reductions(grove) { result, _ in
            result.afterRound()
        }

        XCTAssertEqual(rounds.last?.emptyGroundTiles, 3800)
    }

    // MARK: - part 2

    func testUntilNoMoveExample() throws {
        var grove = try Self.inputParser.parse(Self.example)

        var prev: Grove
        repeat {
            prev = grove
            grove = grove.afterRound()
        } while grove.elves != prev.elves

        XCTAssertEqual(grove.round, 20)
    }

    func testUntilNoMoveInput() throws {
        var grove = try Self.inputParser.parse(Self.input)

        var prev: Grove
        repeat {
            prev = grove
            grove = grove.afterRound()
        } while grove.elves != prev.elves

        XCTAssertEqual(grove.round, 916)
    }
}

extension Day23Tests {
    struct Grove: CustomStringConvertible {
        let elves: Set<IndexRC>
        let considering: [Direction]
        let round: Int

        func afterRound() -> Grove {
            let proposed = proposedMoves()
            let toCount = proposed.reduce(into: [IndexRC: Int]()) { partialResult, move in
                partialResult[move.to, default: 0] += 1
            }

            let decided = proposed.map { move in
                toCount[move.to]! == 1 ? move.to : move.from
            }

            var newConsidering = considering
            newConsidering.rotate(toStartAt: 1)

            return Grove(elves: decided.asSet, considering: newConsidering, round: round + 1)
        }

        func proposedMoves() -> [(from: IndexRC, to: IndexRC)] {
            elves.map { elf in
                (from: elf, to: proposedMove(elf: elf)?.of(elf) ?? elf)
            }
        }

        func proposedMove(elf: IndexRC) -> Direction? {
            guard !areAllOpen(Direction.allCases, from: elf) else {
                return nil
            }

            guard let move = considering.first(where: { dir in
                areAllOpen(dir.considers, from: elf)
            }) else {
                return nil
            }

            return move
        }

        func areAllOpen(_ dirs: [Direction], from elf: IndexRC) -> Bool {
            !dirs.contains { dir in elves.contains(dir.of(elf)) }
        }

        var emptyGroundTiles: Int {
            let rRange = elves.map(\.r).minAndMax()!
            let cRange = elves.map(\.c).minAndMax()!

            return productOfRanges(rRange, cRange)
                .filter { !elves.contains(.init($0, $1)) }
                .count
        }

        // MARK: - description and dump

        var description: String {
            considering.description + " " + elves.sorted(by: \.c).sorted(by: \.r).description
        }

        var dump: NSString {
            let ranges = elves.reduce(into: Ranger()) { partialResult, elf in
                partialResult.expand(toInclude: elf)
            }.ranges

            let output = ranges.x.map { r in
                ranges.y.map { c in
                    elves.contains(.init(r: r, c: c)) ? "#" : "."
                }
                .joined()
            }.joined(separator: "\n")

            return "\nafter round \(round)\n\(output)\n" as NSString
        }
    }

    enum Direction: CaseIterable, CustomStringConvertible {
        case NW, N, NE, W, E, SW, S, SE

        var description: String {
            switch self {
            case .NW: return "NW"
            case .N: return "N"
            case .NE: return "NE"
            case .W: return "W"
            case .E: return "E"
            case .SW: return "SW"
            case .S: return "S"
            case .SE: return "SE"
            }
        }

        static let initialConsidering: [Direction] = [.N, .S, .W, .E]

        var considers: [Direction] {
            switch self {
            case .N: return [.NW, .N, .NE]
            case .S: return [.SW, .S, .SE]
            case .W: return [.NW, .W, .SW]
            case .E: return [.NE, .E, .SE]
            case .NW, .NE, .SW, .SE:
                fatalError()
            }
        }

        func of(_ index: IndexRC) -> IndexRC { index + offset }

        var offset: IndexRC {
            switch self {
            case .NW: return .init(-1, -1)
            case .N: return .init(-1, 0)
            case .NE: return .init(-1, 1)
            case .W: return .init(0, -1)
            case .E: return .init(0, 1)
            case .SW: return .init(1, -1)
            case .S: return .init(1, 0)
            case .SE: return .init(1, 1)
            }
        }
    }
}

extension Day23Tests {
    static let input = resourceURL(filename: "Day23Input.txt")!.readContents()!

    static let example: String =
        """
        ....#..
        ..###.#
        #...#.#
        .#...##
        #.###..
        ##.#.##
        .#..#..
        """

    static let smallExample: String =
        """
        .....
        ..##.
        ..#..
        .....
        ..##.
        .....
        """
    static func elvesFrom(_ isElf: [[Bool]]) -> Set<IndexRC> {
        IndexRC.allIndexRC(isElf.indexRCRanges())
            .filter { isElf[$0] }
            .reduce(into: Set<IndexRC>()) { partialResult, index in
                partialResult.insert(index)
            }
    }

    // MARK: - parser

    static let inputParser = Parse {
        Grove(elves: elvesFrom($0), considering: Direction.initialConsidering, round: 0)
    } with: {
        OneOf {
            ".".map { false }
            "#".map { true }
        }.many()
            .manyByNewline()
            .skipTrailingNewlines()
    }

    func testParseExample() throws {
        let grove = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(grove.elves.count, 22)
    }

    func testParseInput() throws {
        let grove = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(grove.elves.count, 2520)
    }
}
