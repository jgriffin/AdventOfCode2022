//
// Created by John Griffin on 5/21/23
//

import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day24Tests: XCTestCase {
    // MARK: - part 1
    
    func testFastestWalkExample() throws {
        let valleyMap = try Self.valleyMapParser.parse(Self.example)
        let fastest = fastestWalk(valleyMap, andBackForSnacks: false, printSteps: true)
        XCTAssertEqual(fastest.last?.valleyMap.minute, 10)
    }
    
    func testFastestWalkMoreComplexExample() throws {
        let valleyMap = try Self.valleyMapParser.parse(Self.moreComplexExample)
        let fastest = fastestWalk(valleyMap, andBackForSnacks: false, printSteps: true)
        for step in fastest {
            print(step)
        }
        XCTAssertEqual(fastest.last?.valleyMap.minute, 18)
    }
    
    func testFastestWalkInput() throws {
        let valleyMap = try Self.valleyMapParser.parse(Self.input)
        let fastest = fastestWalk(valleyMap, andBackForSnacks: false)
        XCTAssertEqual(fastest.last?.valleyMap.minute, 247)
    }
    
    // MARK: - part 2

    func testFastestWalkAndBackForSnacksMoreComplexExample() throws {
        let valleyMap = try Self.valleyMapParser.parse(Self.moreComplexExample)
        let fastest = fastestWalk(valleyMap, andBackForSnacks: false)
        for step in fastest {
            print(step)
        }
        XCTAssertEqual(fastest.last?.valleyMap.minute, 54)
    }
    
    func testFastestWalkAndBackForSnacksInput() throws {
        let valleyMap = try Self.valleyMapParser.parse(Self.input)
        let fastest = fastestWalk(valleyMap, andBackForSnacks: true)
        XCTAssertEqual(fastest.last?.valleyMap.minute, 728)
    }
    
    // MARK: - afterOneStep
    
    func testValleyMapAfterOneStepExample() throws {
        var valleyMap = try Self.valleyMapParser.parse(Self.example)
        // print(valleyMap.dump)
        for _ in 1 ... 5 {
            valleyMap = valleyMap.afterOneMinute()
        }
        
        let minute5 =
            """
            5:
            #.#####
            #.....#
            #>....#
            #.....#
            #...v.#
            #.....#
            #####.#
            """
        
        XCTAssertEqual(valleyMap.description, minute5)
    }
    
    func testValleyMapAfterOneStepMoreComplexExample() throws {
        var valleyMap = try Self.valleyMapParser.parse(Self.moreComplexExample)
        // print(valleyMap.dump)
        for _ in 1 ... 18 {
            valleyMap = valleyMap.afterOneMinute()
        }
        
        let minute18 =
            """
            18:
            #.######
            #>2.<.<#
            #.2v^2<#
            #>..>2>#
            #<....>#
            ######.#
            """
        XCTAssertEqual(valleyMap.description, minute18)
    }
}

extension Day24Tests {
    struct Step: CustomStringConvertible {
        let valleyMap: ValleyMap
        let possible: Set<IndexXY>
        
        var description: String {
            valleyMap.dump(possible)
        }
    }
    
    func fastestWalk(_ valleyMap: ValleyMap, andBackForSnacks: Bool, printSteps: Bool = false) -> [Step] {
        let xyRanges = valleyMap.xyRanges
        let neighbors = IndexXY.neighborsFunc(
            offsets: IndexXY.squareNeighborHoodOffsets,
            isValidIndex: IndexXY.isValidIndexFunc(xyRanges)
        )
        let startIndex = IndexXY(1, 0)
        let goalIndex = IndexXY(xyRanges.x.upperBound - 2, xyRanges.y.upperBound - 1)

        let start = Step(valleyMap: valleyMap, possible: [startIndex])
        var steps: [Step] = [start]
        
        let walkToGoal = fastestWalk(start, goalIndex, neighbors, printSteps)
        steps.append(contentsOf: walkToGoal)
        
        if andBackForSnacks {
            let fromGoal = Step(valleyMap: steps.last!.valleyMap, possible: [goalIndex])
            let walkBackToStart = fastestWalk(fromGoal, startIndex, neighbors, printSteps)
            steps.append(contentsOf: walkBackToStart)
            
            let fromStart = Step(valleyMap: steps.last!.valleyMap, possible: [startIndex])
            let walkBackToGoal = fastestWalk(fromStart, goalIndex, neighbors, printSteps)
            steps.append(contentsOf: walkBackToGoal)
        }
        
        return steps
    }
    
    private func fastestWalk(_ start: Step, _ goalIndex: IndexXY, _ neighbors: (IndexXY) -> [IndexXY], _ printSteps: Bool) -> [Day24Tests.Step] {
        var current = start
        var steps: [Step] = []
        
        while !current.possible.contains(goalIndex) {
            let nextValleyMap = current.valleyMap.afterOneMinute()
            let nextPossible = current.possible.flatMap(neighbors).asSet.subtracting(nextValleyMap.occupied)
            current = .init(valleyMap: nextValleyMap, possible: nextPossible)
            steps.append(current)
            if printSteps {
                print(current)
            }
        }
        
        return steps
    }
    
    struct ValleyMap: CustomStringConvertible {
        let minute: Int
        let xyRanges: IndexXY.IndexRanges
        let wrapIndex: (IndexXY) -> IndexXY
        let walls: Set<IndexXY>
        let blizzards: [Blizzard]
        let occupied: Set<IndexXY>
        
        struct Blizzard {
            let index: IndexXY
            let direction: Direction
        }

        // MARK: - initialization

        init(
            minute: Int,
            xyRanges: IndexXY.IndexRanges,
            wrapIndex: @escaping (IndexXY) -> IndexXY,
            walls: Set<IndexXY>,
            blizzards: [Day24Tests.ValleyMap.Blizzard]
        ) {
            self.minute = minute
            self.xyRanges = xyRanges
            self.wrapIndex = wrapIndex
            self.walls = walls
            self.blizzards = blizzards
            self.occupied = walls.union(blizzards.map(\.index))
        }

        init(input: [[Space]]) {
            let xyRanges = input.indexXYRanges()
            self.init(
                minute: 0,
                xyRanges: xyRanges,
                wrapIndex: Self.makeWrapIndex(xyRanges),
                walls: IndexXY.allIndexXY(xyRanges).filter { input[$0].isWall }.asSet,
                blizzards: IndexXY.allIndexXY(xyRanges).compactMap { xy -> Blizzard? in
                    guard case let .direction(direction) = input[xy] else { return nil }
                    return Blizzard(index: xy, direction: direction)
                }
            )
        }

        // MARK: - helpers

        func groupBlizzardsByIndex() -> [IndexXY: [Blizzard]] {
            Dictionary(grouping: blizzards, by: \.index)
        }
        
        static func makeWrapIndex(_ xyRanges: IndexXY.IndexRanges) -> (IndexXY) -> IndexXY {
            let minX = xyRanges.x.lowerBound + 1
            let maxX = xyRanges.x.upperBound - 2
            let minY = xyRanges.y.lowerBound + 1
            let maxY = xyRanges.y.upperBound - 2

            return { (xy: IndexXY) -> IndexXY in
                if xy.x < minX { return .init(maxX, xy.y) }
                else if xy.x > maxX { return .init(minX, xy.y) }
                else if xy.y < minY { return .init(xy.x, maxY) }
                else if xy.y > maxY { return .init(xy.x, minY) }
                else { return xy }
            }
        }
        
        func afterOneMinute() -> ValleyMap {
            .init(
                minute: minute + 1,
                xyRanges: xyRanges,
                wrapIndex: wrapIndex,
                walls: walls,
                blizzards: blizzards.map { blizzard in
                    Blizzard(
                        index: wrapIndex(blizzard.index + blizzard.direction.step),
                        direction: blizzard.direction
                    )
                }
            )
        }

        // MARK: - CustomStringConvertable

        var description: String { dump() as String }
        
        func dump(_ possible: Set<IndexXY> = []) -> String {
            let blizzardsByIndex = groupBlizzardsByIndex()
            
            return "\(minute):\n" +
                xyRanges.y.map { y in
                    xyRanges.x.map { x in
                        let index = IndexXY(x, y)
                        return possible.contains(index) ? "o" : descriptionForIndex(index, blizzardsByIndex: blizzardsByIndex)
                    }
                    .joined(by: "")
                }
                .joined(by: "\n")
                .asString
        }
        
        func descriptionForIndex(_ xy: IndexXY, blizzardsByIndex: [IndexXY: [Blizzard]]) -> String {
            if walls.contains(xy) {
                return "#"
            } else if let blizs = blizzardsByIndex[xy] {
                if blizs.count == 1 {
                    return blizs.first!.direction.description
                } else {
                    return "\(blizs.count)"
                }
            } else {
                return "."
            }
        }
    }
    
    struct State: Hashable {
        let index: IndexXY
        let minute: Int
    }
}

extension Day24Tests {
    static let input = resourceURL(filename: "Day24Input.txt")!.readContents()!
    
    static let example: String =
        """
        #.#####
        #.....#
        #>....#
        #.....#
        #...v.#
        #.....#
        #####.#
        """
    
    static let moreComplexExample: String =
        """
        #.######
        #>>.<^<#
        #.<..<<#
        #>v.><>#
        #<^v^^>#
        ######.#
        """
    
    // MARK: - parser
   
    enum Direction: CustomStringConvertible {
        case up, down, left, right
        
        var step: IndexXY {
            switch self {
            case .up: return .init(0, -1)
            case .down: return .init(0, 1)
            case .left: return .init(-1, 0)
            case .right: return .init(1, 0)
            }
        }
        
        var description: String {
            switch self {
            case .left: return "<"
            case .right: return ">"
            case .up: return "^"
            case .down: return "v"
            }
        }
    }
    
    enum Space {
        case wall, space, direction(Direction)
        
        var isWall: Bool {
            if case .wall = self { return true }
            else { return false }
        }
    }
    
    static let spaceParser = OneOf(input: Substring.UTF8View.self, output: Space.self) {
        "#".utf8.map { .wall }
        ".".utf8.map { .space }
        "<".utf8.map { .direction(.left) }
        ">".utf8.map { .direction(.right) }
        "^".utf8.map { .direction(.up) }
        "v".utf8.map { .direction(.down) }
    }
    
    static let valleyMapParser = Parse(input: Substring.UTF8View.self) {
        ValleyMap(input: $0)
    } with: {
        spaceParser.many().manyByNewline().skipTrailingNewlines()
    }
    
    func testParseExample() throws {
        let input = try Self.valleyMapParser.parse(Self.example)
        print(input.dump)
        XCTAssertNotNil(input)
    }
    
    func testParseInput() throws {
        let input = try Self.valleyMapParser.parse(Self.input)
        print(input.dump)
        XCTAssertNotNil(input)
    }
}
