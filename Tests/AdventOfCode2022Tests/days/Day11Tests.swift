import AdventOfCode2022
import Parsing
import XCTest

final class Day11Tests: XCTestCase {
    // MARK: - Part 1

    func testDoRoundExample() throws {
        var barrel = Barrel(monkeys: try Self.inputParser.parse(Self.example))
        try barrel.doRound(worryDecay: 3, worryLimit: barrel.lcmMonkeyDivisor)

        XCTAssertEqual(barrel.monkeys.map(\.items), [
            [20, 23, 27, 26],
            [2080, 25, 167, 207, 401, 1046],
            [],
            [],
        ])
    }

    func test20RoundsExample() throws {
        var barrel = Barrel(monkeys: try Self.inputParser.parse(Self.example))
        try barrel.doRounds(worryDecay: 3, worryLimit: barrel.lcmMonkeyDivisor, until: 20)

        XCTAssertEqual(barrel.monkeys.map(\.items), [
            [10, 12, 14, 26, 34],
            [245, 93, 53, 199, 115],
            [],
            [],
        ])
        XCTAssertEqual(barrel.inspections, [101, 95, 7, 105])
        XCTAssertEqual(barrel.monkeyBusiness, 10605)
    }

    func test20RoundsInput() throws {
        var barrel = Barrel(monkeys: try Self.inputParser.parse(Self.input))
        try barrel.doRounds(worryDecay: 3, worryLimit: barrel.lcmMonkeyDivisor, until: 20)

        XCTAssertEqual(barrel.monkeyBusiness, 182_293)
    }

    // MARK: - Part 2

    func testNoDecayExample() throws {
        let checks: [(afterRound: Int, inspections: [Int])] = [
            (1, [2, 4, 3, 6]),
            (20, [99, 97, 8, 103]),
            (1000, [5204, 4792, 199, 5192]),
            (2000, [10419, 9577, 392, 10391]),
            (3000, [15638, 14358, 587, 15593]),
            (4000, [20858, 19138, 780, 20797]),
            (5000, [26075, 23921, 974, 26000]),
            (6000, [31294, 28702, 1165, 31204]),
            (7000, [36508, 33488, 1360, 36400]),
            (8000, [41728, 38268, 1553, 41606]),
            (9000, [46945, 43051, 1746, 46807]),
            (10000, [52166, 47830, 1938, 52013]),
        ]

        var barrel = Barrel(monkeys: try Self.inputParser.parse(Self.example))
        XCTAssertEqual(barrel.lcmMonkeyDivisor, 96577)

        for check in checks {
            try barrel.doRounds(worryDecay: nil, worryLimit: barrel.lcmMonkeyDivisor, until: check.afterRound)
            XCTAssertEqual(barrel.inspections, check.inspections)
        }
        XCTAssertEqual(barrel.monkeyBusiness, 2_713_310_158)
    }

    func testNoDecayInput() throws {
        var barrel = Barrel(monkeys: try Self.inputParser.parse(Self.input))
        XCTAssertEqual(barrel.lcmMonkeyDivisor, 9_699_690)

        try barrel.doRounds(worryDecay: nil, worryLimit: barrel.lcmMonkeyDivisor, until: 10000)
        XCTAssertEqual(barrel.monkeyBusiness, 54_832_778_815)
    }
}

extension Day11Tests {
    struct Barrel {
        var monkeys: [Monkey]

        var round: Int = 0
        var inspections: [Int] { monkeys.map(\.inspections) }

        var lcmMonkeyDivisor: Int { monkeys.map(\.divisibleBy).reduce(1,*) }

        var monkeyBusiness: Int {
            inspections.sorted().suffix(2).reduce(1, *)
        }

        mutating func doRounds(worryDecay: Int?, worryLimit: Int? = nil, until: Int) throws {
            while round < until {
                try doRound(worryDecay: worryDecay, worryLimit: worryLimit)
            }
        }

        mutating func doRound(worryDecay: Int?, worryLimit: Int?) throws {
            for i in monkeys.indices {
                let monkey = monkeys[i]
                for item in monkey.items {
                    var worryLevel = try monkey.operation.appliedTo(item)
                    if let worryDecay = worryDecay {
                        worryLevel /= worryDecay
                    }
                    if let worryLimit = worryLimit {
                        worryLevel = worryLevel % worryLimit
                    }

                    if worryLevel % monkey.divisibleBy == 0 {
                        monkeys[monkey.toMonkeyTrue].items.append(worryLevel)
                    } else {
                        monkeys[monkey.toMonkeyFalse].items.append(worryLevel)
                    }
                }
                monkeys[i].inspections += monkey.items.count
                monkeys[i].items = []
            }

            round += 1
        }
    }

    enum MonkeyError: Error {
        case multiplicationOverflow
        case failingCheck(String)
    }

    struct Monkey: Equatable {
        let id: Int

        let operation: Operation
        let divisibleBy: Int
        let toMonkeyTrue: Int
        let toMonkeyFalse: Int

        var items: [Int]
        var inspections = 0

        init(id: Int, items: [Int], operation: Day11Tests.Operation, divisibleBy: Int, toMonkeyTrue: Int, toMonkeyFalse: Int) {
            self.id = id
            self.operation = operation
            self.divisibleBy = divisibleBy
            self.toMonkeyTrue = toMonkeyTrue
            self.toMonkeyFalse = toMonkeyFalse

            self.items = items
            inspections = 0
        }
    }

    enum Operation: Equatable {
        case times(Int)
        case plus(Int)
        case squared

        func appliedTo(_ item: Int) throws -> Int {
            switch self {
            case let .times(value): return item * value
            case let .plus(value): return item + value
            case .squared:
                let result = item.multipliedReportingOverflow(by: item)
                guard !result.overflow else {
                    throw MonkeyError.multiplicationOverflow
                }
                return result.partialValue
            }
        }
    }
}

extension Day11Tests {
    static let input = resourceURL(filename: "Day11Input.txt")!.readContents()!

    static let example: String =
        """
        Monkey 0:
          Starting items: 79, 98
          Operation: new = old * 19
          Test: divisible by 23
            If true: throw to monkey 2
            If false: throw to monkey 3

        Monkey 1:
          Starting items: 54, 65, 75, 74
          Operation: new = old + 6
          Test: divisible by 19
            If true: throw to monkey 2
            If false: throw to monkey 0

        Monkey 2:
          Starting items: 79, 60, 97
          Operation: new = old * old
          Test: divisible by 13
            If true: throw to monkey 1
            If false: throw to monkey 3

        Monkey 3:
          Starting items: 74
          Operation: new = old + 3
          Test: divisible by 17
            If true: throw to monkey 0
            If false: throw to monkey 1
        """

    // MARK: - parser

    static let monkeyParser = Parse(Monkey.init) {
        Parse { "Monkey "; Int.parser(); ":\n" }
        Parse { "  Starting items: "; Int.parser().many(separator: ", "); "\n" }
        operationParser
        Parse { "  Test: divisible by "; Int.parser(); "\n" }
        Parse { "    If true: throw to monkey "; Int.parser(); "\n" }
        Parse { "    If false: throw to monkey "; Int.parser() }
    }

    static let operationParser = Parse {
        "  Operation: new = old "
        OneOf {
            Parse { "* "; Int.parser() }.map { Operation.times($0) }
            Parse { "+ "; Int.parser() }.map { Operation.plus($0) }
            Parse { "* old" }.map { Operation.squared }
        }
        "\n"
    }

    static let inputParser = monkeyParser.many(separator: "\n\n").skipTrailingNewlines()

    func testParseMonkey() throws {
        let test =
            """
            Monkey 0:
              Starting items: 79, 98
              Operation: new = old * 19
              Test: divisible by 23
                If true: throw to monkey 2
                If false: throw to monkey 3
            """

        let input = try Self.monkeyParser.parse(test)
        XCTAssertNotNil(input)
    }

    func testParseExample() throws {
        let monkeys = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(monkeys.count, 4)
    }

    func testParseInput() throws {
        let monkeys = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(monkeys.count, 8)
    }
}
