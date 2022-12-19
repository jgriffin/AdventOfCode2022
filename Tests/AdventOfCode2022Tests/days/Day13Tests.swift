import AdventOfCode2022
import Algorithms
import Parsing
import XCTest

final class Day13Tests: XCTestCase {
    // MARK: - Part 1

    func testOrderedPairsExample() throws {
        let pairs = try Self.inputParser.parse(Self.example)
        let result = zip(pairs.indices.map { $0 + 1 },
                         pairs.map { $0.left.isOrderedBefore($0.right) ?? true })
        let trueResults = result.filter { $0.1 == true }
        XCTAssertEqual(trueResults.map(\.0).reduce(0,+), 13)
    }

    func testOrderedPairsInput() throws {
        let pairs = try Self.inputParser.parse(Self.input)
        let result = zip(pairs.indices.map { $0 + 1 },
                         pairs.map { $0.left.isOrderedBefore($0.right) ?? true })
        let trueResults = result.filter { $0.1 == true }
        XCTAssertEqual(trueResults.map(\.0).reduce(0,+), 5003)
    }

    // MARK: - Part 2

    func testSortedPairsExample() throws {
        let pairs = try Self.inputParser.parse(Self.example)
        let allPackets = (pairs.flatMap { [$0.left, $0.right] } + [.divider1, .divider2]).sorted()
        let divider1 = allPackets.firstIndex(of: .divider1).map { $0 + 1 }
        let divider2 = allPackets.firstIndex(of: .divider2).map { $0 + 1 }

        XCTAssertEqual(divider1, 10)
        XCTAssertEqual(divider2, 14)
        XCTAssertEqual(divider1! * divider2!, 140)
    }

    func testSortedPairsInput() throws {
        let pairs = try Self.inputParser.parse(Self.input)
        let allPackets = (pairs.flatMap { [$0.left, $0.right] } + [.divider1, .divider2]).sorted()
        let divider1 = allPackets.firstIndex(of: .divider1).map { $0 + 1 }
        let divider2 = allPackets.firstIndex(of: .divider2).map { $0 + 1 }

        XCTAssertEqual(divider1, 104)
        XCTAssertEqual(divider2, 195)
        XCTAssertEqual(divider1! * divider2!, 20280)
    }
}

extension Day13Tests {
    struct Pair: Equatable {
        let left, right: Value
    }

    indirect enum Value: Equatable, Comparable, CustomStringConvertible {
        case integer(Int)
        case list([Value])

        var description: String {
            switch self {
            case let .integer(value): return "\(value)"
            case let .list(list): return "[\(list.map(\.description).joined(separator: ","))]"
            }
        }

        static func < (lhs: Day13Tests.Value, rhs: Day13Tests.Value) -> Bool {
            lhs.isOrderedBefore(rhs) ?? true
        }

        func isOrderedBefore(_ other: Value) -> Bool? {
            switch (self, other) {
            case let (.integer(lhs), .integer(rhs)):
                guard lhs != rhs else { return nil }
                return lhs < rhs
            case let (.integer, .list(rhs)):
                return Self.areOrdered([self], before: rhs[...])
            case let (.list(lhs), .integer):
                return Self.areOrdered(lhs[...], before: [other])
            case let (.list(lhs), .list(rhs)):
                return Self.areOrdered(lhs[...], before: rhs[...])
            }
        }

        static func areOrdered(_ left: ArraySlice<Value>, before: ArraySlice<Value>) -> Bool? {
            switch (left.first, before.first) {
            case (nil, nil):
                return nil
            case (nil, .some):
                return true
            case (.some, nil):
                return false
            case let (lhs?, rhs?):
                return lhs.isOrderedBefore(rhs) ??
                    areOrdered(left.dropFirst(), before: before.dropFirst())
            }
        }

        static let divider1 = try! valueParser.parse("[[2]]")
        static let divider2 = try! valueParser.parse("[[6]]")
    }
}

extension Day13Tests {
    static let input = resourceURL(filename: "Day13Input.txt")!.readContents()!

    static let example: String =
        """
        [1,1,3,1,1]
        [1,1,5,1,1]

        [[1],[2,3,4]]
        [[1],4]

        [9]
        [[8,7,6]]

        [[4,4],4,4]
        [[4,4],4,4,4]

        [7,7,7,7]
        [7,7,7]

        []
        [3]

        [[[]]]
        [[]]

        [1,[2,[3,[4,[5,6,7]]]],8,9]
        [1,[2,[3,[4,[5,6,0]]]],8,9]
        """

    // MARK: - parser

    static var valueParser: AnyParser<Substring, Value> = {
        OneOf {
            Int.parser().map { Value.integer($0) }
            Parse {
                "["
                Lazy { valueParser.many(length: 0..., separator: ",") }
                "]"
            }.map { Value.list($0) }
        }
        .eraseToAnyParser()
    }()

    static let pairParser = Parse(Pair.init) {
        valueParser
        "\n"
        valueParser
    }

    static let inputParser = Parse { pairParser.many(separator: "\n\n").skipTrailingNewlines() }

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.count, 8)
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.count, 150)
    }
}
