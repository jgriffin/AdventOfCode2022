//
// Created by John Griffin on 5/26/23
//

import Foundation

import AdventOfCode2022
import Parsing
import XCTest

final class Day25Tests: XCTestCase {
    func testSnafuExample() throws {
        let decimals = try Self.inputParser.parse(Self.example)

        let check = [1747, 906, 198, 11, 201, 31, 1257, 32, 353, 107, 7, 3, 37]
        XCTAssertEqual(decimals, check)
        XCTAssertEqual(decimals.reduce(0,+), 4890)
        XCTAssertEqual(Snafu.toSnafu(decimals.reduce(0,+)), "2=-1=0")
    }

    func testSnafuInput() throws {
        let decimals = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(decimals.reduce(0,+), 35023647158862)
        XCTAssertEqual(Snafu.toSnafu(decimals.reduce(0,+)), "2-10==12-122-=1-1-22")
    }

    func testToSnafu() {
        let tests: [(decimal: Int, snafu: String)] = [
            (1, "1"),
            (2, "2"),
            (3, "1="),
            (4, "1-"),
            (5, "10"),
            (6, "11"),
            (7, "12"),
            (8, "2="),
            (9, "2-"),
            (10, "20"),
            (15, "1=0"),
            (20, "1-0"),
            (2022, "1=11-2"),
            (12345, "1-0---0"),
            (314159265, "1121-1110-1=0"),
        ]

        for test in tests {
            XCTAssertEqual(Snafu.toSnafu(test.decimal), test.snafu)
        }
    }
}

extension Day25Tests {
    static let input = resourceURL(filename: "Day25Input.txt")!.readContents()!

    static let example: String =
        """
        1=-0-2
        12111
        2=0=
        21
        2=01
        111
        20012
        112
        1=-1=
        1-12
        12
        1=
        122
        """

    // MARK: - parser

    enum Snafu {
        static func fromSnafuDigits(_ digits: [Int]) -> Int {
            zip(digits.reversed(), powersOfFive())
                .map { $0 * $1 }
                .reduce(0,+)
        }

        static func toSnafu(_ decimal: Int) -> String {
            let placeValues = powersOfFive().prefix(while: { $0 <= decimal }).reversed()
            let baseFiveDigitsReversed = placeValues.map { placeValue in (decimal % (placeValue * 5)) / placeValue }.reversed().asArray
            var carry = 0
            var snafuDigits = baseFiveDigitsReversed.map { digit in
                let digitAndCarry = digit + carry
                defer {
                    carry = digitAndCarry > 2 ? 1 : 0
                }
                return toSnafuDigit(digitAndCarry % 5)
            }
            if carry > 0 {
                snafuDigits.append("\(carry)")
            }
            return snafuDigits.reversed().joined(separator: "")
        }

        static func powersOfFive() -> AnyIterator<Int> {
            var value = 1
            return AnyIterator {
                defer { value = value * 5 }
                return value
            }
        }

        static let digitParser = OneOf(input: Substring.UTF8View.self, output: Int.self) {
            "2".utf8.map { 2 }
            "1".utf8.map { 1 }
            "0".utf8.map { 0 }
            "=".utf8.map { -2 }
            "-".utf8.map { -1 }
        }

        static func toSnafuDigit(_ digit: Int) -> String {
            switch digit {
            case 0: return "0"
            case 1: return "1"
            case 2: return "2"
            case 3: return "="
            case 4: return "-"
            default: fatalError()
            }
        }

        static let parser = digitParser.many().map(fromSnafuDigits)
    }

    static let inputParser = Snafu.parser.manyByNewline().skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.count, 13)
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.count, 120)
    }
}
