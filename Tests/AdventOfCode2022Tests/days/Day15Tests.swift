import AdventOfCode2022
import Charts
import EulerTools
import Parsing
import SwiftUI
import XCTest

final class Day15Tests: XCTestCase {
    // MARK: - Part 1

    func testCannotBeBeaconExample() throws {
        let scan = try Self.scanParser.parse(Self.example)
        let cannots = scan.cannotBeBeaconsInRow(10)
        XCTAssertEqual(cannots.count, 26)
    }

    func testCannotBeBeaconInput() throws {
        let scan = try Self.scanParser.parse(Self.input)
        let cannots = scan.cannotBeBeaconsInRow(2_000_000)
        XCTAssertEqual(cannots.count, 5_144_286)
    }

    // MARK: - Part 2

    func testDistressBeaconPerimeterExample() async throws {
        let scan = try Self.scanParser.parse(Self.example)
        let xyRanges = (x: 0 ..< 21, y: 0 ..< 21)
        func isInRange(_ xy: IndexXY) -> Bool {
            xyRanges.x.contains(xy.x) && xyRanges.y.contains(xy.y)
        }

        let intersectionPoints = await scan.beaconPerimeterInteresectionPoints(isInRange: isInRange)
        let result = intersectionPoints.filter { !scan.isInRangeOfSensor($0) }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, .init(14, 11))
        XCTAssertEqual(result.first.flatMap { $0.x * 4_000_000 + $0.y }, 56_000_011)
    }

    func testDistressBeaconPerimeterInput() async throws {
        let scan = try Self.scanParser.parse(Self.input)
        let xyRanges = (x: 0 ..< 4_000_001, y: 0 ..< 4_000_001)
        func isInRange(_ xy: IndexXY) -> Bool {
            xyRanges.x.contains(xy.x) && xyRanges.y.contains(xy.y)
        }

        let intersectionPoints = await scan.beaconPerimeterInteresectionPoints(isInRange: isInRange)
        let result = intersectionPoints.filter { !scan.isInRangeOfSensor($0) }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, .init(2_557_297, 3_267_339))
        XCTAssertEqual(result.first.flatMap { $0.x * 4_000_000 + $0.y }, 10_229_191_267_339)
    }
}

extension Day15Tests {
    struct Scan {
        typealias XYRanges = (x: Range<Int>, y: Range<Int>)

        let measurements: [SensorAndBeacon]
        let xyRanges: XYRanges

        init(measurements: [SensorAndBeacon]) {
            self.measurements = measurements
            xyRanges = Self.xyRangesFor(measurements)
        }

        func cannotBeBeacon(_ index: IndexXY) -> Bool {
            measurements.contains {
                $0.beacon != index && $0.isInRangeOfSensor(index)
            }
        }

        func cannotBeBeaconsInRow(_ y: Int) -> Set<IndexXY> {
            xyRanges.x.map { IndexXY($0, y) }
                .filter(cannotBeBeacon)
                .asSet
        }

        func isInRangeOfSensor(_ index: IndexXY) -> Bool {
            measurements.contains(where: { $0.isInRangeOfSensor(index) })
        }

        func beaconPerimeterInteresectionPoints(isInRange: @escaping (IndexXY) -> Bool) async -> Set<IndexXY> {
            let measurementCombinations = measurements.combinations(ofCount: 2)
                .map { (first: $0.first!, second: $0.last!) }

            return await withTaskGroup(of: Set<IndexXY>.self) { group in
                for (first, second) in measurementCombinations {
                    guard IndexXY.manhattanDistance(first.sensor, second.sensor) <=
                        (first.manhattanDistance + second.manhattanDistance + 1) else { continue }

                    group.addTask {
                        async let firstPerimeter = first.manhattanPerimeter(isInRange: isInRange)
                        async let secondPerimeter = second.manhattanPerimeter(isInRange: isInRange)

                        return await firstPerimeter.intersection(secondPerimeter)
                    }
                }

                return await group.reduce(Set<IndexXY>()) { result, next in result.union(next) }
            }
        }

        // MARK: helpers

        static func xyRangesFor(_ measurements: [SensorAndBeacon]) -> XYRanges {
            measurements.map(\.xyRanges).reduce(measurements.first!.xyRanges) { partialResult, xyRange in
                (x: min(partialResult.x.lowerBound, xyRange.x.lowerBound) ..< max(partialResult.x.upperBound, xyRange.x.upperBound),
                 y: min(partialResult.y.lowerBound, xyRange.y.lowerBound) ..< max(partialResult.y.upperBound, xyRange.y.upperBound))
            }
        }

        var chart: some View {
            Chart {
                ForEach(measurements.enumerated().asArray, id: \.offset) { _, measurement in
                    RectangleMark(xStart: .value("x", measurement.sensor.x - measurement.manhattanDistance),
                                  xEnd: .value("x", measurement.sensor.x + measurement.manhattanDistance),
                                  yStart: .value("y", measurement.sensor.y - measurement.manhattanDistance),
                                  yEnd: .value("y", measurement.sensor.y + measurement.manhattanDistance))
                        .opacity(0.1)
                        .annotation(position: .overlay, alignment: .center, spacing: 0) {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.blue.opacity(0.5))

                                Rectangle()
                                    .strokeBorder()
                                    .foregroundColor(.blue)
                            }
                            .rotationEffect(.degrees(45))
                        }

                    PointMark(x: .value("x", measurement.sensor.x),
                              y: .value("y", measurement.sensor.y))
                        .symbol(.diamond)
                        .foregroundStyle(.green)

                    PointMark(x: .value("x", measurement.beacon.x),
                              y: .value("y", measurement.beacon.y))
                        .symbol(.circle)
                        .foregroundStyle(.red)
                }
            }
            .frame(width: 1000, height: 1000)
        }
    }

    struct SensorAndBeacon: Equatable {
        let sensor, beacon: IndexXY
        let manhattanDistance: Int

        init(sensor: IndexXY, beacon: IndexXY) {
            self.sensor = sensor
            self.beacon = beacon
            manhattanDistance = IndexXY.manhattanDistance(sensor, beacon)
        }

        var xyRanges: (x: Range<Int>, y: Range<Int>) {
            let distance = manhattanDistance
            return ((sensor.x - distance - 1) ..< (sensor.x + distance + 1),
                    (sensor.y - distance - 1) ..< (sensor.y + distance + 1))
        }

        func isInRangeOfSensor(_ index: IndexXY) -> Bool {
            IndexXY.manhattanDistance(sensor, index) <= manhattanDistance
        }

        func indicesInRange() -> Set<IndexXY> {
            product(xyRanges.x, xyRanges.y).lazy.map { IndexXY(x: $0.first!, y: $0.last!) }
                .filter(isInRangeOfSensor).asSet
        }

        /**
         walk of the perimeter
         */
        func manhattanPerimeter(isInRange: (IndexXY) -> Bool) async -> Set<IndexXY> {
            let top = IndexXY(sensor.x, sensor.y + manhattanDistance + 1)
            let right = IndexXY(sensor.x + manhattanDistance + 1, sensor.y)
            let bottom = IndexXY(sensor.x, sensor.y - manhattanDistance - 1)
            let left = IndexXY(sensor.x - manhattanDistance - 1, sensor.y)

            // Walk clockwise from top
            var current = top
            var path: [IndexXY] = []

            if isInRange(current) {
                path.append(current)
            }

            // downRight
            repeat {
                current += .init(1, -1)
                if isInRange(current) {
                    path.append(current)
                }
            } while current != right

            // downLeft
            repeat {
                current += .init(-1, -1)
                if isInRange(current) {
                    path.append(current)
                }
            } while current != bottom

            // upLeft
            repeat {
                current += .init(-1, 1)
                if isInRange(current) {
                    path.append(current)
                }
            } while current != left

            // upRight
            repeat {
                current += .init(1, 1)
                if isInRange(current) {
                    path.append(current)
                }
            } while current != top

            return path.asSet
        }
    }
}

extension Day15Tests {
    static let input = resourceURL(filename: "Day15Input.txt")!.readContents()!

    static var example: String =
        """
        Sensor at x=2, y=18: closest beacon is at x=-2, y=15
        Sensor at x=9, y=16: closest beacon is at x=10, y=16
        Sensor at x=13, y=2: closest beacon is at x=15, y=3
        Sensor at x=12, y=14: closest beacon is at x=10, y=16
        Sensor at x=10, y=20: closest beacon is at x=10, y=16
        Sensor at x=14, y=17: closest beacon is at x=10, y=16
        Sensor at x=8, y=7: closest beacon is at x=2, y=10
        Sensor at x=2, y=0: closest beacon is at x=2, y=10
        Sensor at x=0, y=11: closest beacon is at x=2, y=10
        Sensor at x=20, y=14: closest beacon is at x=25, y=17
        Sensor at x=17, y=20: closest beacon is at x=21, y=22
        Sensor at x=16, y=7: closest beacon is at x=15, y=3
        Sensor at x=14, y=3: closest beacon is at x=15, y=3
        Sensor at x=20, y=1: closest beacon is at x=15, y=3
        """

    // MARK: - parser

    static let indexParser = Parse(IndexXY.init) {
        "x="
        Int.parser()
        ", y="
        Int.parser()
    }

    static let sensonAndBeaconParser = Parse(SensorAndBeacon.init) {
        "Sensor at "
        indexParser
        ": closest beacon is at "
        indexParser
    }

    static let scanParser = sensonAndBeaconParser.manyByNewline().skipTrailingNewlines().map(Scan.init)

    func testParseExample() throws {
        let scan = try Self.scanParser.parse(Self.example)
        XCTAssertEqual(scan.measurements.count, 14)
        XCTAssertEqual(scan.measurements.last?.sensor.x, 20)
    }

    func testParseInput() throws {
        let scan = try Self.scanParser.parse(Self.input)
        XCTAssertEqual(scan.measurements.count, 34)
        XCTAssertEqual(scan.measurements.last?.beacon.y, 3_583_067)
    }
}
