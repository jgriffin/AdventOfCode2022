import AdventOfCode2022
import Foundation
import Parsing
import XCTest

final class Day03Tests: XCTestCase {
    func testBadgeExample() throws {
        let groups = try Self.groupsParser.parse(Self.example)
        let badges = groups.map { group -> Character in
            group.dropFirst().reduce(Set(group.first!.items)) { $0.intersection($1.items) }.only!
        }
        let sumOfPriories = badges.map(Rucksack.priorityOf).reduce(0, +)

        XCTAssertEqual(badges, ["r", "Z"])
        XCTAssertEqual(sumOfPriories, 70)
    }

    func testBadgesInput() throws {
        let groups = try Self.groupsParser.parse(Self.input)
        let badges = groups.map { group -> Character in
            group.dropFirst().reduce(Set(group.first!.items)) { $0.intersection($1.items) }.only!
        }
        let sumOfPriories = badges.map(Rucksack.priorityOf).reduce(0, +)

        XCTAssertEqual(sumOfPriories, 2518)
    }

    func testInBothExample() throws {
        let rucksacks = try Self.rucksacksParser.parse(Self.example)
        let inBoths = rucksacks.map(\.itemInBoth)
        let priorities = inBoths.map(Rucksack.priorityOf)
        let sumOfPriorities = priorities.reduce(0, +)

        XCTAssertEqual(sumOfPriorities, 157)
    }

    func testInBothInput() throws {
        let rucksacks = try Self.rucksacksParser.parse(Self.input)
        let inBoths = rucksacks.map(\.itemInBoth)
        let priorities = inBoths.map(Rucksack.priorityOf)
        let sumOfPriorities = priorities.reduce(0, +)

        XCTAssertEqual(sumOfPriorities, 8018)
    }
}

extension Day03Tests {
    static var example: String {
        """
        vJrwpWtwJgWrhcsFMMfFFhFp
        jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        PmmdzqPrVvPwwTWBwg
        wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        ttgJtRGJQctTZtZT
        CrZsJsPPZsGzwwsLwLmpwMDw
        """
    }

    static let input = resourceURL(filename: "Day03Input.txt")!.readContents()!

    // MARK: - parser

    struct Rucksack: Equatable {
        let items: [Character]

        init(_ string: Substring) {
            items = Array(string)
        }

        var itemInBoth: Character {
            let middle = items.count / 2
            let result = Set(items[0 ..< middle]).intersection(Set(items[middle...]))
            return result.only!
        }

        static func priorityOf(_ item: Character) -> Int {
            switch item {
            case "a" ... "z":
                return Int(item.asciiValue! - Character("a").asciiValue! + 1)
            case "A" ... "Z":
                return Int(item.asciiValue! - Character("A").asciiValue! + 27)
            default:
                fatalError("\(item) not a valid character")
            }
        }
    }

    static let rucksackParser = Prefix(1..., while: { $0.isLetter })
        .map(Rucksack.init)

    static let rucksacksParser = rucksackParser.manyByNewline().skipTrailingNewlines()

    static let groupsParser = rucksackParser.manyByNewline(length: 3).manyByNewline().skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.rucksacksParser.parse(Self.example)
        XCTAssertEqual(input.count, 6)
        XCTAssertEqual(input.last, Rucksack("CrZsJsPPZsGzwwsLwLmpwMDw"))
    }

    func testParseInput() throws {
        let input = try Self.rucksacksParser.parse(Self.input)
        XCTAssertEqual(input.count, 300)
        XCTAssertEqual(input.last, Rucksack("gptBBdgzpsBbpQvvPQPRqrdcCC"))
    }

    func testParseGroupsExample() throws {
        let input = try Self.groupsParser.parse(Self.example)
        XCTAssertEqual(input.count, 2)
    }

    func testParseGroupsInput() throws {
        let input = try Self.groupsParser.parse(Self.input)
        XCTAssertEqual(input.count, 100)
    }
}
