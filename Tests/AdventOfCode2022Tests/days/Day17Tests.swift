import AdventOfCode2022
import Algorithms
import EulerTools
import Parsing
import XCTest

final class Day17Tests: XCTestCase {
    // MARK: - part 1

    func testDropNextExample() throws {
        let jets = try Self.jetsParser.parse(Self.example)
        var cave = Cave(jets: jets)
        10.times {
            _ = cave.dropNext()
        }
        print(cave)
    }

    func testTowerHeightExample() throws {
        let jets = try Self.jetsParser.parse(Self.example)

        let towerHeight = towerHeightAfterRockWithRepetitions(2022, jets)
        XCTAssertEqual(towerHeight, 3068)

        // DEBUG

        // let towerHeights = afterRockHeightsUntilAfterRock(2022, jets)
        // XCTAssertEqual(towerHeights.last?.height, 3068)

        // let repetition = findRepetition(towerHeights)
        // XCTAssertEqual(repetition?.interval, 35)
        // XCTAssertEqual(repetition?.repetitions, 57)
    }

    func testTowerHeightInput() throws {
        let jets = try Self.jetsParser.parse(Self.input)

        let towerHeight = towerHeightAfterRockWithRepetitions(2022, jets)
        XCTAssertEqual(towerHeight, 3083)

        // debugging

        // let towerHeights = afterRockHeightsUntilAfterRock(2022, jets)
        // XCTAssertEqual(towerHeights.last?.height, 3083)

        // let repetition = findRepetition(towerHeights)
        // XCTAssertEqual(repetition?.interval, 345)
        // XCTAssertEqual(repetition?.repetitions, 5)
    }

    // MARK: - part 2

    let trillion = 1000000000000

    func testTowerHeightTrillionExample() throws {
        let jets = try Self.jetsParser.parse(Self.example)

        let towerHeight = towerHeightAfterRockWithRepetitions(trillion, jets)
        XCTAssertEqual(towerHeight, 1514285714288)
    }

    func testTowerHeightTrillionInput() throws {
        let jets = try Self.jetsParser.parse(Self.input)

        let towerHeight = towerHeightAfterRockWithRepetitions(trillion, jets)
        XCTAssertEqual(towerHeight, 1532183908048)
    }
}

extension Day17Tests {
    func afterRockHeightsUntilAfterRock(_ afterRock: Int, _ jets: [Jet]) -> [AfterRockHeight] {
        var cave = Cave(jets: jets)

        return (1 ... afterRock).map { i in
            _ = cave.dropNext()
            return AfterRockHeight(afterRock: i, height: cave.towerHeight)
        }
    }

    private func towerHeightAfterRock(_ afterRock: Int, _ jets: [Jet]) -> Int {
        afterRockHeightsUntilAfterRock(afterRock, jets).last!.height
    }

    func towerHeightAfterRockWithRepetitions(_ afterRock: Int, _ jets: [Jet]) -> Int {
        let maxIntervalLength = 5000
        let towerHeights = afterRockHeightsUntilAfterRock(min(afterRock, maxIntervalLength), jets)
        guard afterRock > maxIntervalLength,
              let repetition = findRepetition(towerHeights)
        else {
            return towerHeights.last!.height
        }

        let startsAfterRock = towerHeights.last!.afterRock
        let lastHeight = towerHeights.last!.height

        let wholeRepetitions = (afterRock - startsAfterRock) / repetition.interval
        let remainingRocks = (afterRock - startsAfterRock) % repetition.interval

        let repetitionDelta = repetition.heightDeltasByOffset.reduce(0,+)
        let remainingDelta = repetition.heightDeltasByOffset.prefix(remainingRocks).reduce(0,+)

        return lastHeight + wholeRepetitions * repetitionDelta + remainingDelta
    }

    struct Repetition: Equatable, CustomStringConvertible {
        let interval: Int
        let repetitions: Int
        let heightDeltasByOffset: [Int]

        var span: Int { interval * repetitions }

        var description: String { "interval: \(interval) repetitions: \(repetitions)" }
    }

    struct AfterRockHeight: Equatable, CustomStringConvertible {
        let afterRock: Int
        let height: Int

        var description: String { "(after: \(afterRock) height: \(height))" }
    }

    func findRepetition(
        _ towerHeights: some Sequence<AfterRockHeight>
    ) -> Repetition? {
        let heightDeltas = zip(towerHeights.dropFirst(), towerHeights).map { next, prev in
            AfterRockHeight(afterRock: next.afterRock, height: next.height - prev.height)
        }
        let afterRocksByDelta = Dictionary(grouping: heightDeltas, by: \.height).mapValues { $0.map(\.afterRock) }
        let offsetsFromEndByDelta = heightDeltas
            .map { afterRocksByDelta[$0.height]!.asArray }
            .map { indices in (indices, indices.max()!) }
            .map { indices, lastRock in indices.map { lastRock - $0 } }

        let commonOffsetsFromEnd = offsetsFromEndByDelta
            .reduce(into: Set(offsetsFromEndByDelta.first!)) { result, deltas in
                result.formIntersection(deltas)
            }
            .subtracting([0])
            .sorted()

        guard let interval = commonOffsetsFromEnd.first(where: { interval in
            heightDeltas.suffix(interval).map(\.height) == heightDeltas.dropLast(interval).suffix(interval).map(\.height)
        }) else {
            return nil
        }

        guard let repetitions = commonOffsetsFromEnd.reversed().first(where: { interval in
            heightDeltas.suffix(interval).map(\.height) == heightDeltas.dropLast(interval).suffix(interval).map(\.height)
        }) else {
            return nil
        }

        let heightDeltasByOffset = heightDeltas.suffix(interval).map(\.height)

        return Repetition(
            interval: interval,
            repetitions: repetitions,
            heightDeltasByOffset: heightDeltasByOffset
        )
    }

    struct Cave: CustomStringConvertible {
        let chamberWidth = 0 ..< 7
        let floor = 0

        init(jets: [Jet]) {
            self.shapes = Shape.allShapes.cycled().makeIterator()
            self.jets = jets.cycled().makeIterator()
        }

        var shapes: CycledSequence<[Shape]>.Iterator
        var jets: CycledSequence<[Jet]>.Iterator
        var chamber = Set<IndexXY>()

        var towerHeight: Int { abs(chamber.lazy.map(\.y).min() ?? 0) }

        mutating func dropNext() -> Bool {
            let shape = shapes.next()!
            guard let position = positionWhenDropped(shape) else {
                return false
            }
            chamber.formUnion(shape.rocks.map { $0 + position })
            return true
        }

        mutating func positionWhenDropped(_ shape: Shape) -> IndexXY? {
            let canBeAt = makeShapeCanBeAt(shape)

            let dropPoint = IndexXY(chamberWidth.lowerBound + 2, (chamber.map(\.y).min() ?? floor) - 4)

            var current = dropPoint
            while let jet = jets.next() {
//                print(dump(shape.rocksAt(current)))

                switch jet {
                case .left:
                    if canBeAt(current + .init(-1, 0)) {
                        current += .init(-1, 0)
                    }
                case .right:
                    if canBeAt(current + .init(1, 0)) {
                        current += .init(1, 0)
                    }
                }

                // drop
                guard canBeAt(current + .init(0, 1)) else {
                    break
                }

                current += .init(0, 1)
            }

            return current
        }

        func makeShapeCanBeAt(_ shape: Shape) -> (IndexXY) -> Bool {
            { position in
                canBeAt(position, shape)
            }
        }

        func canBeAt(_ position: IndexXY, _ shape: Shape) -> Bool {
            guard position.y < floor,
                  chamberWidth.contains(position.x),
                  chamberWidth.contains(position.x + shape.width) else { return false }

            return shape.rocksAt(position).allSatisfy { !chamber.contains($0) }
        }

        var description: String { dump(nil) }

        func dump(_ falling: Set<IndexXY>?) -> String {
            let minY = min(
                chamber.lazy.map(\.y).min() ?? floor,
                falling?.lazy.map(\.y).min() ?? .max
            )

            return (minY ..< floor).map { y in
                chamberWidth.map { x in
                    let index = IndexXY(x, y)
                    if chamber.contains(index) {
                        return "#"
                    } else if falling?.contains(index) == true {
                        return "@"
                    } else {
                        return "."
                    }
                }.joined()
            }
            .joined(separator: "\n")
            .appending("\n-------\n")
        }
    }

    struct Shape: Equatable, CustomStringConvertible {
        let name: String
        let rocks: Set<IndexXY>
        let width: Int

        var description: String { "\(name)" }

        init(name: String,
             input: [[Bool]])
        {
            let inputIndices = input.enumerated().flatMap { y, row -> [IndexXY] in
                row.enumerated().compactMap { x, isRock in isRock ? IndexXY(x, y) : nil }
            }
            let maxY = inputIndices.lazy.map(\.y).max()!

            self.name = name
            self.width = inputIndices.lazy.map(\.x).max()!
            self.rocks = inputIndices.map { IndexXY($0.x, $0.y - maxY) }.asSet // negate y
        }

        func rocksAt(_ position: IndexXY) -> Set<IndexXY> {
            rocks.map { $0 + position }.asSet
        }

        static let allShapes: [Shape] =
            zip(["dash", "plus", "corner", "vertical", "square"],
                try! Day17Tests.shapesParser.parse(Day17Tests.shapesString))
            .map {
                Shape(name: $0, input: $1)
            }
    }

    enum Jet: Equatable, CustomStringConvertible {
        case left
        case right

        var description: String {
            switch self {
            case .left: return "<"
            case .right: return ">"
            }
        }
    }
}

extension Day17Tests {
    static let input = resourceURL(filename: "Day17Input.txt")!.readContents()!

    static let example: String =
        """
        >>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>
        """

    static let shapesString =
        """
        ####

        .#.
        ###
        .#.

        ..#
        ..#
        ###

        #
        #
        #
        #

        ##
        ##
        """

    // MARK: - parser

    static let shapesParser = shapeParser.many(separator: "\n\n").skipTrailingNewlines()

    static let shapeParser =
        OneOf {
            "#".map { true }
            ".".map { false }
        }.many().manyByNewline()

    func testParseShapes() throws {
        let shapes = try Self.shapesParser.parse(Self.shapesString)
        XCTAssertEqual(shapes.count, 5)
    }

    static let jetDirection = OneOf {
        "<".map { Jet.left }
        ">".map { Jet.right }
    }

    static let jetsParser = jetDirection.many().skipTrailingNewlines()

    func testParseExample() throws {
        let jets = try Self.jetsParser.parse(Self.example)
        XCTAssertEqual(jets.count, 40)
    }

    func testParseInput() throws {
        let jets = try Self.jetsParser.parse(Self.input)
        XCTAssertEqual(jets.count, 10091)
    }
}
