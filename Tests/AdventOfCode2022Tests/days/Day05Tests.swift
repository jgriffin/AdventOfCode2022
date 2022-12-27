import AdventOfCode2022
import Parsing
import XCTest

final class Day05Tests: XCTestCase {
    func testMoveManyCratesExample() throws {
        var (stacks, moves) = try Self.inputParser.parse(Self.example)
        moves.forEach { move in
            stacks.applyMoveMany(move)
        }

        let tops = stacks.stacks.map { $0.last! }.joined()
        XCTAssertEqual(tops, "MCD")
    }

    func testMoveManyCratesInput() throws {
        var (stacks, moves) = try Self.inputParser.parse(Self.input)
        moves.forEach { move in
            stacks.applyMoveMany(move)
        }

        let tops = stacks.stacks.map { $0.last! }.joined()
        XCTAssertEqual(tops, "ZFSJBPRFP")
    }

    func testMoveCratesExample() throws {
        var (stacks, moves) = try Self.inputParser.parse(Self.example)
        moves.forEach { move in
            stacks.applyMove(move)
        }

        let tops = stacks.stacks.map { $0.last! }.joined()
        XCTAssertEqual(tops, "CMZ")
    }

    func testMoveCratesInput() throws {
        var (stacks, moves) = try Self.inputParser.parse(Self.input)
        moves.forEach { move in
            stacks.applyMove(move)
        }

        let tops = stacks.stacks.map { $0.last! }.joined()
        XCTAssertEqual(tops, "SPFMVDTZT")
    }
}

extension Day05Tests {
    typealias Crate = Substring
    typealias Stack = [Crate]

    struct Stacks: Equatable {
        var stacks: [Stack]

        init(stacks: [Stack]) {
            self.stacks = stacks
        }

        init(stackRows: [[Crate?]]) {
            let stackCount = stackRows.map(\.count).max()!
            var stacks = Array(repeating: Stack(), count: stackCount)
            stackRows.forEach { stackRow in
                stackRow.enumerated().forEach { i, crate in
                    if let crate {
                        stacks[i].append(crate)
                    }
                }
            }

            self.stacks = stacks.map { $0.reversed() }
        }

        mutating func applyMove(_ move: MoveStep) {
            for _ in 0 ..< move.count {
                stacks[move.to - 1].append(stacks[move.from - 1].popLast()!)
            }
        }

        mutating func applyMoveMany(_ move: MoveStep) {
            stacks[move.to - 1].append(contentsOf: stacks[move.from - 1].suffix(move.count))
            stacks[move.from - 1].removeLast(move.count)
        }
    }

    struct MoveStep: Equatable {
        let count: Int
        let from: Int
        let to: Int
    }

    static let input = resourceURL(filename: "Day05Input.txt")!.readContents()!

    static var example: String {
        """
            [D]
        [N] [C]
        [Z] [M] [P]
         1   2   3

        move 1 from 2 to 1
        move 3 from 1 to 3
        move 2 from 2 to 1
        move 1 from 1 to 2
        """
    }

    // MARK: - parser

    static let crateParser = Parse {
        "["
        Prefix(1, while: { ("A" ... "Z").contains($0) })
        "]"
    }

    static let stackRowParser = OneOf {
        "   ".map { nil as Crate? }
        crateParser.map { $0 as Crate? }
    }.many(separator: " ")

    static let stacksParser = stackRowParser.manyByNewline()
        .map { Stacks(stackRows: $0) }

    static let moveStepParser = Parse {
        MoveStep(count: $0, from: $1, to: $2)
    } with: {
        "move "
        Int.parser()
        " from "
        Int.parser()
        " to "
        Int.parser()
    }

    static let inputParser = Parse {
        stacksParser

        "\n"

        Skip {
            " "
            Parse {
                Int.parser()
                " ".many(length: 0...)
            }.many()
            "\n"
        }

        "\n"

        moveStepParser.manyByNewline()
    }.skipTrailingNewlines()

    func testStackRowParser() throws {
        let input = try Self.stackRowParser.parse("[Z] [M] [P]")
        XCTAssertEqual(input, ["Z", "M", "P"])
    }

    func testStackRowParserExample() throws {
        let (stacks, steps) = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(stacks.stacks.count, 3)
        XCTAssertEqual(steps.count, 4)
    }

    func testStackRowParserInput() throws {
        let (stacks, steps) = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(stacks.stacks.count, 9)
        XCTAssertEqual(steps.count, 502)
        XCTAssertEqual(steps.last, MoveStep(count: 1, from: 2, to: 7))
    }
}
