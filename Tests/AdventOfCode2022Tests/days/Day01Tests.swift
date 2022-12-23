import AdventOfCode2022
import Parsing
import XCTest

class Day01Tests: XCTestCase {
    func testMostCaloriesExample() throws {
        let elves = try Self.inputParser.parse(Self.example)
        let elfCalories = elves.map { $0.reduce(0, +) }
        let most = elfCalories.max()

        XCTAssertEqual(most, 24000)
    }

    func testMostCaloriesInput() throws {
        let elves = try Self.inputParser.parse(Self.input)
        let elfCalories = elves.map { $0.reduce(0, +) }
        let most = elfCalories.max()

        XCTAssertEqual(most, 69693)
    }

    func testTopThreeCaloriesExample() throws {
        let elves = try Self.inputParser.parse(Self.example)
        let elfCalories = elves.map { $0.reduce(0, +) }.sorted()
        let topThree = elfCalories.suffix(3)
        let topThreeTotal = topThree.reduce(0,+)

        XCTAssertEqual(topThree, [10000, 11000, 24000])
        XCTAssertEqual(topThreeTotal, 45000)
    }

    func testTopThreeCaloriesInput() throws {
        let elves = try Self.inputParser.parse(Self.input)
        let elfCalories = elves.map { $0.reduce(0, +) }.sorted()
        let topThree = elfCalories.suffix(3)
        let topThreeTotal = topThree.reduce(0,+)

        XCTAssertEqual(topThree, [64495, 66757, 69693])
        XCTAssertEqual(topThreeTotal, 200_945)
    }
}

extension Day01Tests {
    static let example = """
    1000
    2000
    3000

    4000

    5000
    6000

    7000
    8000
    9000

    10000
    """

    static let input = resourceURL(filename: "Day01Input.txt")!.readContents()!

    static let calorieParser = Int.parser(of: Substring.self)
    static let elfParser = calorieParser.manyByNewline()
    static let inputParser = elfParser.many(separator: "\n\n").skipTrailingNewlines()

    func testParseExample() throws {
        let result = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result.last?.last, 10000)
    }

    func testParseInput() throws {
        let result = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(result.count, 250)
        XCTAssertEqual(result.last?.last, 6660)
    }
}
