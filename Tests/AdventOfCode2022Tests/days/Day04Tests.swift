import AdventOfCode2022
import Parsing
import XCTest

final class Day04Tests: XCTestCase {
    func testOverlapsExample() throws {
        let pairs = try Self.inputParser.parse(Self.example)
        let overlaps = pairs.map(\.overlaps)
        let countOfOverlaps = overlaps.filter { !$0.isEmpty }.count

        XCTAssertEqual(countOfOverlaps, 4)
    }
    
    func testOverlapsInput() throws {
        let pairs = try Self.inputParser.parse(Self.input)
        let overlaps = pairs.map(\.overlaps)
        let countOfOverlaps = overlaps.filter { !$0.isEmpty }.count

        XCTAssertEqual(countOfOverlaps, 888)
    }

    func testFullyContainsExample() throws {
        let pairs = try Self.inputParser.parse(Self.example)
        let fullyContains = pairs.filter(\.oneFullyContains)
        XCTAssertEqual(fullyContains.count, 2)
    }
    
    func testFullyContainsInput() throws {
        let pairs = try Self.inputParser.parse(Self.input)
        let fullyContains = pairs.filter(\.oneFullyContains)
        XCTAssertEqual(fullyContains.count, 471)
    }
}

extension Day04Tests {
    typealias SectionId = Int
    typealias Assignment = ClosedRange<SectionId>
    
    struct AssignmentPair: Equatable {
        let first, second: Assignment
        
        var oneFullyContains: Bool {
            (first.contains(second.first!) && first.contains(second.last!)) ||
                (second.contains(first.first!) && second.contains(first.last!))
        }
        
        var overlaps: Set<SectionId> {
            Set(first).intersection(Set(second))
        }
    }
    
    static let input = resourceURL(filename: "Day04Input.txt")!.readContents()!
    
    static var example: String {
        """
        2-4,6-8
        2-3,4-5
        5-7,7-9
        2-8,3-7
        6-6,4-6
        2-6,4-8
        """
    }
    
    // MARK: - parser
    
    static let assignmentParser = Parse { $0 ... $1 } with: {
        Int.parser()
        "-"
        Int.parser()
    }
    
    static let assignmentPairParser = Parse(AssignmentPair.init) {
        assignmentParser
        ","
        assignmentParser
    }
    
    static let inputParser = assignmentPairParser.manyByNewline().skipTrailingNewlines()

    func testAssignmentParser() throws {
        let result = try Self.assignmentParser.parse("2-4")
        XCTAssertEqual(result, 2 ... 4)
    }

    func testParseExample() throws {
        let result = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(result.count, 6)
    }
    
    func testParseInput() throws {
        let result = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(result.count, 1000)
    }
}
