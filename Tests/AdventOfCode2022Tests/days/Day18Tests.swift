import AdventOfCode2022
import Algorithms
import EulerTools
import Parsing
import XCTest

final class Day18Tests: XCTestCase {
    // MARK: - Part 1

    func testSurfaceAreaExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        let scan = Scan(cubes: input.asSet)
        let surfaceArea = scan.surfaceArea()

        XCTAssertEqual(surfaceArea, 64)
    }

    func testSurfaceAreaInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        let scan = Scan(cubes: input.asSet)
        let surfaceArea = scan.surfaceArea()

        XCTAssertEqual(surfaceArea, 3346)
    }

    // MARK: - Part 2

    func testAirPocketsExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        let scan = Scan(cubes: input.asSet)
        let ranges = scan.rangesXYZ(scan.cubes)
        XCTAssertEqual(ranges.x, 1 ... 3)
        XCTAssertEqual(ranges.y, 1 ... 3)
        XCTAssertEqual(ranges.z, 1 ... 6)

        let trapped = scan.trappedCubes()
        XCTAssertEqual(trapped.count, 1)

        let trappedSurfaceArea = scan.trappedSurfaceArea(trapped)
        XCTAssertEqual(trappedSurfaceArea, 6)

        XCTAssertEqual(scan.exteriorSurfaceArea(), 58)
    }

    func testAirPocketsInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        let scan = Scan(cubes: input.asSet)
        let ranges = scan.rangesXYZ(scan.cubes)
        XCTAssertEqual(ranges.x, 0 ... 19)
        XCTAssertEqual(ranges.y, 1 ... 19)
        XCTAssertEqual(ranges.z, 1 ... 18)

        let surfaceArea = scan.surfaceArea()
        XCTAssertEqual(surfaceArea, 3346)

        let trapped = scan.trappedCubes()
        XCTAssertEqual(trapped.count, 1037)

        let trappedSurfaceArea = scan.trappedSurfaceArea(trapped)
        XCTAssertEqual(trappedSurfaceArea, 1366)

        XCTAssertEqual(scan.exteriorSurfaceArea(), 1980) // 1897 -- too low, 3159 -- too high
    }
}

extension Day18Tests {
    struct Scan {
        let cubes: Set<Index3>

        // MARK: surface area

        func surfaceArea() -> Int {
            product(cubes, neighborOffsets)
                .reduce(0) { result, pair in
                    result + (!cubes.contains(pair.0 + pair.1) ? 1 : 0)
                }
        }

        func exteriorSurfaceArea() -> Int {
            let surfaceArea = surfaceArea()
            let trapped = trappedCubes()
            let trappedSurfaceArea = trappedSurfaceArea(trapped)

            return surfaceArea - trappedSurfaceArea
        }

        func trappedSurfaceArea(_ trapped: Set<Index3>) -> Int {
            product(trapped, neighborOffsets)
                .reduce(0) { result, pair in
                    result + (cubes.contains(pair.0 + pair.1) ? 1 : 0)
                }
        }

        // MARK: trapped cubes

        func trappedCubes() -> Set<Index3> {
            let ranges = rangesXYZ(cubes)

            let maybeInside = product(ranges.x, ranges.y)
                .flatMap { x, y in
                    ranges.z.dropFirst().dropLast().map { z in Index3(x, y, z) }
                }.asSet
                .subtracting(cubes)

            // color maybleInside
            let indicesByColor = colorMaybeInside(maybeInside)

            return indicesByColor.values.flatMap { $0 }.asSet
        }

        private func colorMaybeInside(_ maybeInside: Set<Index3>) -> [Int: [Index3]] {
            let outsideColor = 0
            var nextColor = 1

            var indicesByColor: [Int: [Index3]] = [:]
            var colorByIndices: [Index3: Int] = [:]

            func setColor(_ color: Int, for index: Index3) {
                assert(colorByIndices[index] == nil)
                indicesByColor[color, default: []].append(index)
                colorByIndices[index] = color
            }

            func combineColors(_ oldColor: Int, into newColor: Int) {
                guard oldColor != newColor else { return }
                guard oldColor != outsideColor else {
                    return combineColors(newColor, into: outsideColor)
                }
                guard let oldColorIndices = indicesByColor[oldColor] else { fatalError() }

                indicesByColor[newColor, default: []].append(contentsOf: oldColorIndices)
                indicesByColor[oldColor] = nil

                oldColorIndices.forEach { index in
                    colorByIndices[index] = newColor
                }
            }

            maybeInside.forEach { index in
                if colorByIndices[index] == nil {
                    setColor(nextColor, for: index)
                    nextColor += 1
                }

                for neighbor in neighborOffsets.map({ index + $0 }) {
                    guard !cubes.contains(neighbor) else {
                        continue
                    }
                    guard maybeInside.contains(neighbor) else {
                        combineColors(colorByIndices[index]!, into: outsideColor)
                        continue
                    }
                    if let neighborColor = colorByIndices[neighbor] {
                        combineColors(colorByIndices[index]!, into: neighborColor)
                    } else {
                        setColor(colorByIndices[index]!, for: neighbor)
                    }
                }
            }

            indicesByColor[outsideColor] = nil

            return indicesByColor
        }

        func rangesXYZ(_ cubes: Set<Index3>) -> (x: ClosedRange<Int>, y: ClosedRange<Int>, z: ClosedRange<Int>) {
            return (x: range(cubes.map(\.x).minAndMax()!),
                    y: range(cubes.map(\.y).minAndMax()!),
                    z: range(cubes.map(\.z).minAndMax()!))
        }

        let neighborOffsets: [Index3] = [
            .init(1, 0, 0),
            .init(0, 1, 0),
            .init(0, 0, 1),
            .init(-1, 0, 0),
            .init(0, -1, 0),
            .init(0, 0, -1),
        ]
    }
}

extension Day18Tests {
    static let input = resourceURL(filename: "Day18Input.txt")!.readContents()!

    static var example: String =
        """
        2,2,2
        1,2,2
        3,2,2
        2,1,2
        2,3,2
        2,2,1
        2,2,3
        2,2,4
        2,2,6
        1,2,5
        3,2,5
        2,1,5
        2,3,5
        """

    // MARK: - parser

    static let index3Parser = From(.utf8) { Int.parser() }.many(length: 3, separator: ",").map { Index3($0[0], $0[1], $0[2]) }
    static let inputParser = index3Parser.manyByNewline().skipTrailingNewlines()

    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.count, 13)
        XCTAssertEqual(input.last, Index3(2, 3, 5))
    }

    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.count, 2170)
        XCTAssertEqual(input.last, Index3(6, 14, 3))
    }
}
