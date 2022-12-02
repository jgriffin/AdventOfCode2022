import AdventOfCode2022
import Parsing
import XCTest

final class Day02Tests: XCTestCase {
    // MARK: - part 1

    func testRoundScoreExample() throws {
        let rounds = try Self.roundsShapeParser.parse(Self.example)
        XCTAssertEqual(rounds[0].score, 8)
        XCTAssertEqual(rounds[1].score, 1)
        XCTAssertEqual(rounds[2].score, 6)

        let total = rounds.map(\.score).reduce(0, +)
        XCTAssertEqual(total, 15)
    }

    func testTotalScoreInput() throws {
        let rounds = try Self.roundsShapeParser.parse(Self.input)
        let total = rounds.map(\.score).reduce(0, +)
        XCTAssertEqual(total, 12276)
    }

    // MARK: - part 2

    func testRoundScoreResultExample() throws {
        let rounds = try Self.roundsResultParser.parse(Self.example)
        XCTAssertEqual(rounds[0].score, 4)
        XCTAssertEqual(rounds[1].score, 1)
        XCTAssertEqual(rounds[2].score, 7)

        let total = rounds.map(\.score).reduce(0, +)
        XCTAssertEqual(total, 12)
    }

    func testTotalScoreResultInput() throws {
        let rounds = try Self.roundsResultParser.parse(Self.input)
        let total = rounds.map(\.score).reduce(0, +)
        XCTAssertEqual(total, 9975)
    }
}

extension Day02Tests {
    enum Shape: CustomStringConvertible {
        case rock, paper, scissors

        var value: Int {
            switch self {
            case .rock: return 1
            case .paper: return 2
            case .scissors: return 3
            }
        }

        var description: String {
            switch self {
            case .rock: return "rock"
            case .paper: return "paper"
            case .scissors: return "scissors"
            }
        }

        func beats(_ other: Shape) -> RoundResult {
            switch (self, other) {
            case (.rock, .rock), (.scissors, .scissors), (.paper, .paper):
                return .draw
            case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
                return .win
            case (.paper, .scissors), (.scissors, .rock), (.rock, .paper):
                return .lose
            }
        }

        func shapeToGetResult(_ result: RoundResult) -> Shape {
            switch (self, result) {
            case (.rock, .win): return .paper
            case (.rock, .draw): return .rock
            case (.rock, .lose): return .scissors
            case (.paper, .win): return .scissors
            case (.paper, .draw): return .paper
            case (.paper, .lose): return .rock
            case (.scissors, .win): return .rock
            case (.scissors, .draw): return .scissors
            case (.scissors, .lose): return .paper
            }
        }
    }

    struct Round: Equatable {
        let opponent, you: Shape
        let result: RoundResult

        init(opponent: Day02Tests.Shape, you: Day02Tests.Shape) {
            self.opponent = opponent
            self.you = you
            result = you.beats(opponent)
        }

        init(opponent: Day02Tests.Shape, result: RoundResult) {
            self.opponent = opponent
            self.result = result
            you = opponent.shapeToGetResult(result)
        }

        var score: Int { you.value + result.value }
    }

    enum RoundResult: Equatable {
        case win, lose, draw

        var value: Int {
            switch self {
            case .lose: return 0
            case .draw: return 3
            case .win: return 6
            }
        }
    }
}

extension Day02Tests {
    static let input = resourceURL(filename: "Day02Input.txt")!.readContents()!

    static var example: String {
        """
        A Y
        B X
        C Z
        """
    }

    // MARK: - parser

    static let shapeParser = OneOf {
        "A".map { Shape.rock }
        "B".map { Shape.paper }
        "C".map { Shape.scissors }
        "X".map { Shape.rock }
        "Y".map { Shape.paper }
        "Z".map { Shape.scissors }
    }

    static let resultParser = OneOf {
        "X".map { RoundResult.lose }
        "Y".map { RoundResult.draw }
        "Z".map { RoundResult.win }
    }

    static let roundShapeParser = Parse(Round.init) {
        shapeParser
        " "
        shapeParser
    }

    static let roundResultParser = Parse(Round.init) {
        shapeParser
        " "
        resultParser
    }

    static let roundsShapeParser = roundShapeParser.many().skipTrailingNewlines()
    static let roundsResultParser = roundResultParser.many().skipTrailingNewlines()

    func testParseShapeExample() throws {
        let result = try Self.roundsShapeParser.parse(Self.example)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.last, Round(opponent: .scissors, you: .scissors))
    }

    func testParseShapeInput() throws {
        let result = try Self.roundsShapeParser.parse(Self.input)
        XCTAssertEqual(result.count, 2500)
        XCTAssertEqual(result.last, Round(opponent: .rock, you: .rock))
    }
}
