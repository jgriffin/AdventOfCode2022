import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day22Tests: XCTestCase {
    func testPasswordExample() throws {
        let (grove, path) = try Self.inputParser.parse(Self.example)
        var walker = Walker(grove: grove)
        walker.followPath(path)
        print(walker.dump.joined(separator: "\n"))
        XCTAssertEqual(walker.currentPassword, 6032)
    }
    
    func testPasswordInput() throws {
        let (grove, path) = try Self.inputParser.parse(Self.input)
        var walker = Walker(grove: grove)
        walker.followPath(path)
        print(walker.dump.joined(separator: "\n"))
        XCTAssertEqual(walker.currentPassword, 11464)
    }
}

extension Day22Tests {
    struct Walker {
        let grove: Grove
        var current: IndexAndDirection {
            didSet { steps.append(current) }
        }

        var steps: [IndexAndDirection] = []
        
        init(grove: Grove) {
            self.grove = grove
            self.current = .init(index: grove.startIndex(), direction: .right)
            steps.append(current)
        }
        
        var currentPassword: Int {
            1000 * (current.index.r) + 4 * (current.index.c) + current.direction.value
        }
        
        mutating func followPath(_ path: [Step]) {
            for step in path {
                move(step)
            }
        }
        
        mutating func move(_ step: Step) {
            switch step {
            case .turnLeft:
                current.direction = current.direction.counterClockwise
            case .turnRight:
                current.direction = current.direction.clockwise
            case let .forward(steps):
                moveForward(steps)
            }
        }
        
        private mutating func moveForward(_ steps: Int) {
            let indexedTiles = grove.indexedTilesInDirection(current.direction, from: current.index)
            var iterator = indexedTiles.cycled().makeIterator()
            
            for _ in 0 ..< steps {
                let next = iterator.next()!
                switch next.tile {
                case .open:
                    current.index = next.index
                case .wall:
                    return
                }
            }
        }
        
        var dump: [String] {
            let steps = Dictionary(steps.map { ($0.index, $0.direction.description) }) { _, rhs in
                rhs
            }
            let maxR = grove.tiles.keys.lazy.map(\.r).max()!
            let maxC = grove.tiles.keys.lazy.map(\.c).max()!
            return (0...maxR).map { r in
                (0...maxC).map { c in
                    let index = IndexRC(r, c)
                    return steps[index] ?? grove.tiles[index]?.description ?? " "
                }.joined()
            }
        }
    }
    
    struct IndexAndDirection: Hashable, CustomStringConvertible {
        var index: IndexRC
        var direction: Direction
        var description: String { "(\(index.r),\(index.c),\(direction))" }
    }

    struct Grove: Equatable {
        let tiles: [IndexRC: Tile]
        let indexedTilesByR: [Int: [IndexedTile]]
        let indexedTilesByC: [Int: [IndexedTile]]

        // MARK: - init
        
        init(_ tiles: [[Tile?]]) {
            self.tiles = Dictionary(uniqueKeysWithValues:
                tiles.enumerated().flatMap { r, row in
                    row.enumerated().compactMap { c, tile -> (IndexRC, Tile)? in
                        guard let tile else { return nil }
                        return (IndexRC(r + 1, c + 1), tile)
                    }
                })
            (self.indexedTilesByR, self.indexedTilesByC) = Self.indexedTilesByRC(self.tiles)
        }
        
        static func indexedTilesByRC(_ tiles: [IndexRC: Tile]) -> (byR: [Int: [IndexedTile]], byC: [Int: [IndexedTile]]) {
            let indexedTiles = tiles.map { index, tile in IndexedTile(index: index, tile: tile) }
            
            return (byR: Dictionary(grouping: indexedTiles, by: \.index.r).mapValues { $0.sorted(by: \.index.c) },
                    byC: Dictionary(grouping: indexedTiles, by: \.index.c).mapValues { $0.sorted(by: \.index.r) })
        }

        func startIndex() -> IndexRC {
            tiles.lazy.filter { $0.value == .open }
                .min(by: areInIncreasingOrder(by: \.key.r, then: \.key.c))!
                .key
        }
        
        // MARK: - indexedTilesInDirection
        
        func indexedTilesInDirection(_ direction: Direction, from: IndexRC) -> [IndexedTile] {
            var ray: [IndexedTile] = {
                switch direction {
                case .up:
                    return indexedTilesByC[from.c]!.reversed().asArray
                case .down:
                    return indexedTilesByC[from.c]!.asArray
                case .left:
                    return indexedTilesByR[from.r]!.reversed().asArray
                case .right:
                    return indexedTilesByR[from.r]!.asArray
                }
            }()
            
            let fromIndex = ray.firstIndex(where: { $0.index == from })!
            ray.rotate(toStartAt: fromIndex + 1 % ray.count)
            return ray
        }
        
        private func indexedTilesWithStep(_ step: IndexRC, from: IndexRC) -> [IndexedTile] {
            indexedTilesForwardWithStep(step, from: from + step) +
                indexedTilesForwardWithStep(.init(-step.r, -step.c), from: from).reversed()
        }
        
        private func indexedTilesForwardWithStep(_ step: IndexRC, from: IndexRC) -> [IndexedTile] {
            var ray: [IndexedTile] = []
            
            var current = from
            while let tile = tiles[current] {
                ray.append(.init(index: current, tile: tile))
                current += step
            }
            
            return ray
        }
    }
                                                                            
    struct IndexedTile: Equatable, CustomStringConvertible {
        let index: IndexRC
        let tile: Tile
        
        var description: String { "(\(index.r),\(index.c),\(tile))" }
    }
    
    enum Tile: Equatable, CustomStringConvertible {
        case open, wall
        
        var description: String {
            switch self {
            case .open: return "."
            case .wall: return "#"
            }
        }
    }

    enum Step: Equatable {
        case forward(Int)
        case turnRight
        case turnLeft
    }
    
    enum Direction: Equatable, CustomStringConvertible {
        case up, down, left, right
        
        var value: Int {
            switch self {
            case .up: return 3
            case .down: return 1
            case .left: return 2
            case .right: return 0
            }
        }
        
        var delta: IndexRC {
            switch self {
            case .up: return .init(r: -1, c: 0)
            case .down: return .init(r: -1, c: 0)
            case .left: return .init(r: 0, c: -1)
            case .right: return .init(r: 0, c: 1)
            }
        }
        
        var description: String {
            switch self {
            case .up: return "^"
            case .down: return "v"
            case .left: return "<"
            case .right: return ">"
            }
        }
        
        var clockwise: Direction {
            switch self {
            case .up: return .right
            case .down: return .left
            case .left: return .up
            case .right: return .down
            }
        }
        
        var counterClockwise: Direction {
            switch self {
            case .up: return .left
            case .down: return .right
            case .left: return .down
            case .right: return .up
            }
        }
    }
}

extension Day22Tests {
    static let input = resourceURL(filename: "Day22Input.txt")!.readContents()!
    
    static let example: String =
        """
                ...#
                .#..
                #...
                ....
        ...#.......#
        ........#...
        ..#....#....
        ..........#.
                ...#....
                .....#..
                .#......
                ......#.

        10R5L5R10L4R5L5
        """
    
    // MARK: - parser
    
    static let tileParser = OneOf {
        " ".map { nil as Tile? }
        ".".map { Tile.open as Tile? }
        "#".map { Tile.wall as Tile? }
    }
    
    static let groveParser = tileParser.many().manyByNewline().map(Grove.init)
    
    static let stepParser = OneOf(input: Substring.self, output: Step.self) {
        Int.parser().map { Step.forward($0) }
        "L".map { Step.turnLeft }
        "R".map { Step.turnRight }
    }
    
    static let inputParser = Parse {
        groveParser
        "\n\n"
        stepParser.many()
    }.skipTrailingNewlines()
    
    func testParseExample() throws {
        let (grove, path) = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(grove.tiles.count, 96)
        XCTAssertEqual(path.count, 13)
    }
    
    func testParseInput() throws {
        let (grove, path) = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(grove.tiles.count, 15000)
        XCTAssertEqual(path.count, 4001)
    }
}
