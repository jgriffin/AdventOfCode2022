import AdventOfCode2022
import Charts
import EulerTools
import Parsing
import SwiftUI
import XCTest

final class Day14Tests: XCTestCase {
    // MARK: - Part 1

    func testCaveExample() async throws {
        let paths = try Self.inputParser.parse(Self.example)
        var cave = Cave(paths: paths)
        XCTAssertEqual(cave.rocks.count, 20)

        _ = cave.addSand()

        let chart = await cave.chart.renderCGImage(scale: 5)
        XCTAssertNotNil(chart)
    }

    func testCaveInput() async throws {
        let paths = try Self.inputParser.parse(Self.input)
        var cave = Cave(paths: paths)
        XCTAssertEqual(cave.rocks.count, 647)

        _ = cave.addSand()
        XCTAssertEqual(cave.sand.count, 843)

        let chart = await cave.chart.renderCGImage()
        XCTAssertNotNil(chart)
    }

    // MARK: - Part 2

    func testCaveWithFloorExample() async throws {
        let paths = try Self.inputParser.parse(Self.example)
        var cave = Cave(paths: paths, addFloor: true)

        while !cave.addSand(upToCount: 10) {
            let chart = await cave.chart.renderCGImage(scale: 5)
            XCTAssertNotNil(chart)
        }

        XCTAssertEqual(cave.sand.count, 93)

        let chart = await cave.chart.renderCGImage(scale: 5)
        XCTAssertNotNil(chart)
    }

    func testCaveWithFloorInput() async throws {
        let paths = try Self.inputParser.parse(Self.input)
        var cave = Cave(paths: paths, addFloor: true)

        _ = cave.addSand()
        XCTAssertEqual(cave.sand.count, 27625)

        let chart = await cave.chart.renderCGImage()
        XCTAssertNotNil(chart)
    }
}

extension Day14Tests {
    struct Cave {
        let rocks: Set<IndexXY>
        let addFloor: Bool
        let rockBottom: Int

        var sand: Set<IndexXY> = []

        init(paths: [[IndexXY]], addFloor: Bool = false) {
            let rocks = Self.digitizePaths(paths)
            self.rocks = rocks
            self.addFloor = addFloor
            rockBottom = rocks.map(\.y).max()! + (addFloor ? 2 : 0)
        }

        let start = IndexXY(500, 0)
        let down = IndexXY(0, 1)
        let downLeft = IndexXY(-1, 1)
        let downRight = IndexXY(1, 1)

        mutating func addSand(upToCount: Int? = nil) -> Bool {
            var count = 0
            while let next = addPebble() {
                sand.insert(next)
                count += 1

                if count == upToCount {
                    return false
                }

                if next == start {
                    break
                }
            }
            return true
        }

        mutating func addPebble() -> IndexXY? {
            var current = start
            while current.y < rockBottom {
                if !isOccupied(current + down) {
                    current += down
                } else if !isOccupied(current + downLeft) {
                    current += downLeft
                } else if !isOccupied(current + downRight) {
                    current += downRight
                } else {
                    break
                }
            }

            guard current.y < rockBottom else {
                return nil
            }
            return current
        }

        func isOccupied(_ index: IndexXY) -> Bool {
            rocks.contains(index) ||
                sand.contains(index) ||
                (addFloor && index.y == rockBottom)
        }

        var chart: some View {
            Chart {
                ForEach(Array(rocks.enumerated()), id: \.offset) { _, rock in
                    PointMark(x: .value("x", rock.x),
                              y: .value("y", rock.y))
                }
                .symbol(.asterisk)
                .foregroundStyle(.blue)

                if addFloor {
                    RuleMark(y: .value("y", rockBottom))
                        .foregroundStyle(.blue)
                }

                ForEach(Array(sand.enumerated()), id: \.offset) { _, sand in
                    PointMark(x: .value("x", sand.x),
                              y: .value("y", sand.y))
                }
                .symbol(.circle)
                .foregroundStyle(.yellow)

                PointMark(x: .value("x", 500),
                          y: .value("y", 0))
                    .symbol(.cross)
                    .foregroundStyle(.green)
            }
            .chartXScale(domain: .automatic(includesZero: false, reversed: false))
            .chartYScale(domain: .automatic(includesZero: true, reversed: true), range: .plotDimension(padding: 5))
            .chartXAxis {
                AxisMarks(values: .automatic(minimumStride: 5)) { _ in
                    AxisTick()
                    AxisValueLabel()
                }
                AxisMarks {
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisTick()
                    AxisValueLabel()
                }
                AxisMarks(values: .stride(by: 1)) {
                    AxisGridLine()
                }
            }
            .frame(width: 2000, height: 1000)
            .fixedSize()
            .colorScheme(.light)
        }

        static func digitizePaths(_ paths: [[IndexXY]]) -> Set<IndexXY> {
            paths.map(Self.digitizePath).reduce(Set<IndexXY>()) { result, next in result.union(next) }
        }

        static func digitizePath(_ path: [IndexXY]) -> Set<IndexXY> {
            guard path.count > 1 else { return path.asSet }

            return path.adjacentPairs()
                .reduce(into: Set<IndexXY>()) { result, pair in
                    var current = pair.0
                    while current != pair.1 {
                        result.insert(current)
                        current += (pair.1 - current).unitBias
                    }
                    result.insert(pair.1)
                }
                .asSet
        }
    }
}

extension Day14Tests {
    static let input = resourceURL(filename: "Day14Input.txt")!.readContents()!

    static let example: String =
        """
        498,4 -> 498,6 -> 496,6
        503,4 -> 502,4 -> 502,9 -> 494,9
        """

    // MARK: - parser

    static let locationParser = Parse(input: Substring.self, IndexXY.init) {
        Int.parser()
        ","
        Int.parser()
    }

    static let pathParser = locationParser.many(separator: " -> ")

    static let inputParser = pathParser.manyByNewline().skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertNotNil(input)
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertNotNil(input)
    }
}
