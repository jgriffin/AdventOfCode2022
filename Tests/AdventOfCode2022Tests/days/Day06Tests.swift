import AdventOfCode2022
import Algorithms
import Parsing
import XCTest

final class Day06Tests: XCTestCase {
    // MARK: - Part 1

    func testStartOfMessage4Examples() throws {
        let checks = [5, 6, 10, 11]
        let examples = try Self.examples.map { try Self.signalParser.parse($0) }
        let starts = examples.map { startOfPacket($0, count: 4) }

        XCTAssertEqual(starts, checks)
    }

    func testStartOfMessage4Input() throws {
        let input = try Self.signalParser.parse(Self.input)
        let startIndex = startOfPacket(input, count: 4)
        XCTAssertEqual(startIndex, 1598)
    }

    // MARK: - part 2

    func testStartOfMessage14Examples() throws {
        let checks = [19, 23, 23, 29, 26]
        let examples = try Self.examples14.map { try Self.signalParser.parse($0) }
        let starts = examples.map { startOfPacket($0, count: 14) }

        XCTAssertEqual(starts, checks)
    }

    func testStartOfMessage14Input() throws {
        let input = try Self.signalParser.parse(Self.input)
        let startIndex = startOfPacket(input, count: 14)
        XCTAssertEqual(startIndex, 2414)
    }

    // MARK: - helpers

    func startOfPacket(_ msg: Substring, count: Int) -> Int? {
        guard let first = msg.windows(ofCount: count).enumerated()
            .first(where: { Set($0.element).count == count })
        else {
            return nil
        }
        return first.offset + count
    }
}

extension Day06Tests {
    static let input = resourceURL(filename: "Day06Input.txt")!.readContents()!

    static let examples: [Substring] =
        """
        bvwbjplbgvbhsrlpgdmjqwftvncz
        nppdvjthqldpwncqszvftbrmjlhg
        nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg
        zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw
        """
        .lines()

    static let examples14: [Substring] =
        """
        mjqjpqmgbljsphdztnvjfqwrcgsmlb
        bvwbjplbgvbhsrlpgdmjqwftvncz
        nppdvjthqldpwncqszvftbrmjlhg
        nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg
        zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw
        """
        .lines()

    // MARK: - parser

    static let signalParser = Prefix(while: { $0.isLetter }).skipTrailingNewlines()
}
