import AdventOfCode2022
import EulerTools
import Parsing
import XCTest

final class Day22Tests: XCTestCase {
    // MARK: - part 1
    
    func testPasswordExample() throws {
        let (grove, path) = try Self.inputParser.parse(Self.example)
        var walker = Walker(grove: grove, jumpType: .planar)
        walker.followPath(path)
        print(walker.dump.joinedByNewlines)
        XCTAssertEqual(walker.currentPassword, 6032)
    }
    
    func testPasswordInput() throws {
        let (grove, path) = try Self.inputParser.parse(Self.input)
        var walker = Walker(grove: grove, jumpType: .planar)
        walker.followPath(path)
        print(walker.dump.joinedByNewlines)
        XCTAssertEqual(walker.currentPassword, 11464)
    }
    
    // MARK: - part 2
    
    func testJumpMapExample() throws {
        let (grove, _) = try Self.inputParser.parse(Self.example)
        let indices = grove.tiles.keys.asArray
        let sideLength = 4
        let jumpMap = JumpType.exampleCube.jumpMap(indices)
        let sortedIndices = indices.sorted(by: areInIncreasingOrder(by: \.r, then: \.c))
        for index in sortedIndices.prefix(10) {
            for dir in Direction.allCases {
                let start = IndexAndDirection(index, dir)
                let walk = (0 ..< sideLength * 4).reductions(start) { current, _ in
                    if let jump = jumpMap[current] {
                        return jump
                    } else {
                        return .init(current.index + current.direction.delta, current.direction)
                    }
                }
                // print(walk.joinedByNewlines)
                XCTAssertEqual(walk.last, start)
            }
        }
    }

    func testPasswordCubeExample() throws {
        let (grove, path) = try Self.inputParser.parse(Self.example)
        var walker = Walker(grove: grove, jumpType: .exampleCube)
        walker.followPath(path)
        // print(walker.dump.joinedByNewlines)
        XCTAssertEqual(walker.currentPassword, 5031)
    }
    
    func testJumpMapInput() throws {
        let (grove, _) = try Self.inputParser.parse(Self.input)
        let indices = grove.tiles.keys.asArray
        let sideLength = 50
        let jumpMap = JumpType.inputCube.jumpMap(indices)
        let sortedIndices = indices.sorted(by: areInIncreasingOrder(by: \.r, then: \.c))
        for index in sortedIndices.prefix(1) {
            for dir in Direction.allCases.dropFirst(3).prefix(1) {
                let start = IndexAndDirection(index, dir)
                let walk = (0 ..< sideLength * 4).reductions(start) { current, _ in
                    if let jump = jumpMap[current] {
                        return jump
                    } else {
                        return .init(current.index + current.direction.delta, current.direction)
                    }
                }
                // print(walk.joinedByNewlines)
                XCTAssertEqual(walk.last, start)
            }
        }
    }

    func testPasswordCubeInput() throws {
        let (grove, path) = try Self.inputParser.parse(Self.input)
        var walker = Walker(grove: grove, jumpType: .inputCube)
        walker.followPath(path)
        print(walker.dump.joinedByNewlines)
        XCTAssertEqual(walker.currentPassword, 197122)
    }
}

extension Day22Tests {
    typealias JumpMap = [IndexAndDirection: IndexAndDirection]
    typealias FaceEdgeDirection = (face: CubeMath.Face, edge: CubeMath.Edge, direction: Direction)
    typealias EdgeMap = (from: FaceEdgeDirection, to: FaceEdgeDirection)

    enum JumpType {
        case planar, exampleCube, inputCube
        
        func jumpMap(_ indices: [IndexRC]) -> JumpMap {
            switch self {
            case .planar: return Self.planarJumps(indices)
            case .exampleCube: return Self.exampleCubeJumps(indices)
            case .inputCube: return Self.inputCubeJumps(indices)
            }
        }
        
        static func exampleCubeJumps(_ indices: [IndexRC]) -> JumpMap {
            let cube = CubeMath(
                sideLength: 4,
                squareForFace: [
                    .one: .init(0, 2),
                    .two: .init(1, 0),
                    .three: .init(1, 1),
                    .four: .init(1, 2),
                    .five: .init(2, 2),
                    .six: .init(2, 3),
                ]
            )
            
            let edgeMaps: [(from: FaceEdgeDirection, to: FaceEdgeDirection)] = [
                ((.one, .top, .up), (.two, .top, .down)), // .reversed,
                ((.two, .top, .up), (.one, .top, .down)),
                ((.three, .top, .up), (.one, .leading, .right)), // .clockwise,
                ((.six, .top, .up), (.four, .trailing, .left)), // .counterClockwise,
                ((.one, .trailing, .right), (.six, .trailing, .left)), // .counterClockwise,
                ((.four, .trailing, .right), (.six, .top, .down)), // .clockwise,
                ((.six, .trailing, .right), (.one, .trailing, .left)), // .reversed,
                ((.one, .leading, .left), (.four, .leading, .right)), // .counterClockwise,
                ((.two, .leading, .left), (.six, .bottom, .up)), // .clockwise,
                ((.five, .leading, .left), (.three, .bottom, .up)), // .clockwise,
                ((.two, .bottom, .down), (.five, .bottom, .up)), // .straight,
                ((.three, .bottom, .down), (.five, .leading, .right)), // .counterClockwise,
                ((.five, .bottom, .down), (.two, .bottom, .up)), // .reversed,
                ((.six, .bottom, .down), (.two, .leading, .right)), // .clockwise,
            ]
            
            return jumpMapFrom(cube, edgeMaps)
        }
        
        static func inputCubeJumps(_ indices: [IndexRC]) -> JumpMap {
            let cube = CubeMath(
                sideLength: 50,
                squareForFace: [
                    .one: .init(0, 1),
                    .two: .init(0, 2),
                    .three: .init(1, 1),
                    .four: .init(2, 0),
                    .five: .init(2, 1),
                    .six: .init(3, 0),
                ]
            )
            
            let edgeMaps: [(from: FaceEdgeDirection, to: FaceEdgeDirection)] = [
                ((.one, .top, .up), (.six, .leading, .right)),
                ((.two, .top, .up), (.six, .bottom, .up)),
                ((.four, .top, .up), (.three, .leading, .right)),
                ((.two, .trailing, .right), (.five, .trailing, .left)),
                ((.three, .trailing, .right), (.two, .bottom, .up)),
                ((.five, .trailing, .right), (.two, .trailing, .left)),
                ((.six, .trailing, .right), (.five, .bottom, .up)),
                ((.one, .leading, .left), (.four, .leading, .right)),
                ((.three, .leading, .left), (.four, .top, .down)),
                ((.four, .leading, .left), (.one, .leading, .right)),
                ((.six, .leading, .left), (.one, .top, .down)),
                ((.two, .bottom, .down), (.three, .trailing, .left)),
                ((.five, .bottom, .down), (.six, .trailing, .left)),
                ((.six, .bottom, .down), (.two, .top, .down)),
            ]
            
            return jumpMapFrom(cube, edgeMaps)
        }

        static func planarJumps(_ indices: [IndexRC]) -> JumpMap {
            let byRow = Dictionary(grouping: indices, by: \.r)
            let byCol = Dictionary(grouping: indices, by: \.c)
            let colMinMax = byCol.map { col, value in (col, value.map(\.r).minAndMax()!) }.sorted(by: \.0)
            let rowMinMax = byRow.map { row, value in (row, value.map(\.c).minAndMax()!) }.sorted(by: \.0)
            
            let upJumps = colMinMax.map { col, rowMinMax -> (IndexAndDirection, IndexAndDirection) in
                (.init(.init(rowMinMax.min, col), .up), .init(.init(rowMinMax.max, col), .up))
            }
            let downJumps = colMinMax.map { col, rowMinMax -> (IndexAndDirection, IndexAndDirection) in
                (.init(.init(rowMinMax.max, col), .down), .init(.init(rowMinMax.min, col), .down))
            }
            let leftJumps = rowMinMax.map { row, colMinMax -> (IndexAndDirection, IndexAndDirection) in
                (.init(.init(row, colMinMax.min), .left), .init(.init(row, colMinMax.max), .left))
            }
            let rightJumps = rowMinMax.map { row, colMinMax -> (IndexAndDirection, IndexAndDirection) in
                (.init(.init(row, colMinMax.max), .right), .init(.init(row, colMinMax.min), .right))
            }
            let jumps = upJumps + downJumps + rightJumps + leftJumps
            return Dictionary(uniqueKeysWithValues: jumps)
        }
        
        static func jumpMapFrom(_ cube: CubeMath, _ edgeMaps: [EdgeMap]) -> JumpMap {
            let jumps = edgeMaps.map { pair in
                let fromEdges = cube.edgeIndices(pair.from.face, pair.from.edge)
                var toEdges = cube.edgeIndices(pair.to.face, pair.to.edge)
                if pair.from.direction.parity != pair.to.direction.parity {
                    toEdges.reverse()
                }
                
                let toJumps = zip(fromEdges, toEdges).map { from, to in
                    (IndexAndDirection(from, pair.from.direction), IndexAndDirection(to, pair.to.direction))
                }.asArray
                return toJumps
            }
            
            let jumpMap = jumps.reduce(into: JumpMap()) { result, jumps in
                let d = Dictionary(uniqueKeysWithValues: jumps)
                result.merge(d) { l, _ in
                    assertionFailure(jumps.description)
                    return l
                }
            }
            
            return jumpMap
        }
    }
    
    struct Walker {
        let grove: Grove
        let jumps: JumpMap

        var current: IndexAndDirection {
            didSet { steps.append(current) }
        }

        var steps: [IndexAndDirection] = []
        
        init(grove: Grove, jumpType: JumpType) {
            self.grove = grove
            self.jumps = jumpType.jumpMap(grove.tiles.keys.asArray)

            self.current = .init(grove.startIndex(), .right)
            steps.append(current)
        }
        
        var currentPassword: Int {
            1000 * (current.index.r + 1) + 4 * (current.index.c + 1) + current.direction.value
        }
        
        mutating func followPath(_ path: [Step]) {
            for step in path {
                move(step)
            }
        }
        
        mutating func move(_ step: Step) {
            switch step {
            case .turnLeft:
                current = .init(current.index, Turn.counterClockwise.apply(current.direction))
            case .turnRight:
                current = .init(current.index, Turn.clockwise.apply(current.direction))
            case let .forward(steps):
                moveForward(steps)
            }
        }
        
        private mutating func moveForward(_ steps: Int) {
            for _ in 0 ..< steps {
                let next: IndexAndDirection = jumps[current] ??
                    .init(current.index + current.direction.delta, current.direction)

                switch grove.tiles[next.index] {
                case .open:
                    current = next
                case .wall:
                    return
                case .none:
                    fatalError()
                }
            }
        }
       
        var dump: [String] {
            let steps = Dictionary(steps.map { ($0.index, $0.direction.description) }) { _, rhs in
                rhs
            }
            let maxR = grove.tiles.keys.lazy.map(\.r).max()!
            let maxC = grove.tiles.keys.lazy.map(\.c).max()!
            return (0 ... maxR).map { r in
                (0 ... maxC).map { c in
                    let index = IndexRC(r, c)
                    return steps[index] ?? grove.tiles[index]?.description ?? " "
                }.joined()
            }
        }
    }
    
    struct IndexAndDirection: Hashable, CustomStringConvertible {
        var index: IndexRC
        let direction: Direction

        init(_ index: IndexRC, _ direction: Day22Tests.Direction) {
            self.index = index
            self.direction = direction
        }
        
        var description: String { "\(index) \(direction)" }
    }

    struct Grove {
        let tiles: [IndexRC: Tile]

        // MARK: - init
        
        init(_ tiles: [[Tile?]]) {
            let indexedTiles = tiles.enumerated().flatMap { r, row in
                row.enumerated().map { c, tile -> (IndexRC, Tile?) in
                    (IndexRC(r, c), tile)
                }
            }
            let tiles = indexedTiles
                .filter { _, tile in tile != nil }
                .map { index, tile in (index, tile!) }
            
            self.tiles = Dictionary(uniqueKeysWithValues: tiles)
        }

        func startIndex() -> IndexRC {
            tiles.lazy.filter { $0.value == .open }
                .min(by: areInIncreasingOrder(by: \.key.r, then: \.key.c))!
                .key
        }
        
        // MARK: - jump
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
    
    enum Direction: Equatable, CaseIterable, CustomStringConvertible {
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
            case .down: return .init(r: 1, c: 0)
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
        
        var parity: Bool {
            switch self {
            case .right, .up: return true
            case .left, .down: return false
            }
        }
        
        var inverse: Direction {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }
        
    enum Turn: CustomStringConvertible {
        case clockwise, counterClockwise, straight, reversed
            
        func apply(_ direction: Direction) -> Direction {
            switch self {
            case .clockwise: return Self.applyClockwise(direction)
            case .counterClockwise: return Self.applyCounterClockwise(direction)
            case .straight: return direction
            case .reversed: return Self.applyReversed(direction)
            }
        }
        
        var inverse: Turn {
            switch self {
            case .clockwise: return .counterClockwise
            case .counterClockwise: return .clockwise
            case .straight: return .straight
            case .reversed: return .reversed
            }
        }
        
        var description: String {
            switch self {
            case .clockwise: return "clockwise"
            case .counterClockwise: return "counterClockwise"
            case .straight: return "straight"
            case .reversed: return "reversed"
            }
        }
            
        private static func applyClockwise(_ direction: Direction) -> Direction {
            switch direction {
            case .up: return .right
            case .down: return .left
            case .left: return .up
            case .right: return .down
            }
        }
            
        private static func applyCounterClockwise(_ direction: Direction) -> Direction {
            switch direction {
            case .up: return .left
            case .down: return .right
            case .left: return .down
            case .right: return .up
            }
        }
            
        private static func applyReversed(_ direction: Direction) -> Direction {
            switch direction {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
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
