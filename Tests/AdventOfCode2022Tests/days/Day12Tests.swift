import AdventOfCode2022
import Charts
import EulerTools
import Parsing
import XCTest

final class Day12Tests: XCTestCase {
    func testBestPathExample() throws {
        let heightMap = try Self.heightMapParser.parse(Self.example)
        let bestPath = heightMap.findBestPath()
        XCTAssertEqual(bestPath?.dropFirst().count, 31)
    }
    
    func testBestPathInput() throws {
        let heightMap = try Self.heightMapParser.parse(Self.input)
        let bestPath = heightMap.findBestPath()
        XCTAssertEqual(bestPath?.dropFirst().count, 484)
    }
    
    func testBestStartExample() throws {
        let heightMap = try Self.heightMapParser.parse(Self.example)
        let bestStart = heightMap.findBestStart()
        XCTAssertEqual(bestStart?.path.dropFirst().count, 29)
    }
    
    func testBestStartInput() throws {
        let heightMap = try Self.heightMapParser.parse(Self.input)
        let bestStart = heightMap.findBestStart()
        XCTAssertEqual(bestStart?.path.dropFirst().count, 478)
    }
}

extension Day12Tests {
    struct HeightMap {
        let squares: [[Square]]
        let allIndices: [IndexXY]
        let reachableNeighbors: (_ index: IndexXY) -> [IndexXY]
        let start: IndexXY
        let goal: IndexXY

        init(_ squares: [[Square]]) {
            self.squares = squares
            self.allIndices = IndexXY.allIndexXY(squares.indexXYRanges())
            self.start = allIndices.first(where: { squares[$0] == .start })!
            self.goal = allIndices.first(where: { squares[$0] == .end })!

            let neighbors = IndexXY.neighborsFunc(
                offsets: IndexXY.squareNeighborOffsets,
                isValidIndex: IndexXY.isValidIndexFunc(squares.indexXYRanges())
            )
            func isReachable(_ index: IndexXY, from: IndexXY) -> Bool {
                squares[index].height - squares[from].height <= 1
            }
            
            self.reachableNeighbors = { (index: IndexXY) in
                neighbors(index).filter { isReachable($0, from: index) }
            }
        }
        
        // MARK: - best path
        
        func findBestPath(start: IndexXY? = nil) -> [IndexXY]? {
            let solver = AStarSolver(
                hScorer: hScore,
                neighborGenerator: reachableNeighbors
            )
            
            return solver.solve(
                from: start ?? self.start,
                goal: goal
            )
        }
        
        func findBestStart() -> (start: IndexXY, path: [IndexXY])? {
            let possibleStarts = allIndices.filter { squares[$0] == .letter("a") }
            let paths = possibleStarts
                .compactMap { start -> (start: IndexXY, path: [IndexXY])? in
                    guard let path = findBestPath(start: start) else { return nil }
                    return (start: start, path: path)
                }
            
            let shortest = paths.min { lhs, rhs in lhs.1.count < rhs.1.count }
            return shortest
        }
        
        // MARK: - helpers
        
        func heightDifference(_ indexXY: IndexXY, from: IndexXY) -> Int {
            squares[goal].height - squares[indexXY].height
        }
        
        func hScore(_ indexXY: IndexXY) -> Int {
            let heightDifference = heightDifference(goal, from: indexXY)
            guard heightDifference >= 0 else {
                fatalError()
            }

            let manhattenDistance = abs(indexXY.x - goal.x) + abs(indexXY.y - goal.y)
            return max(heightDifference, manhattenDistance)
        }
    }
    
    enum Square: Equatable {
        case start, end
        case letter(Character)
        
        init(_ ch: Character) {
            self = {
                switch ch {
                case "S": return Square.start
                case "E": return Square.end
                case "a" ... "z": return Square.letter(ch)
                default: fatalError()
                }
            }()
        }
        
        var height: Int {
            switch self {
            case .start: return 0
            case .end: return 25
            case let .letter(letter):
                return Int(letter.asciiValue! - Character("a").asciiValue!)
            }
        }
    }
    
    static let input = resourceURL(filename: "Day12Input.txt")!.readContents()!
    
    static let example: String =
        """
        Sabqponm
        abcryxxl
        accszExk
        acctuvwj
        abdefghi
        """
    
    // MARK: - parser
    
    static let rowParser = Prefix(1..., while: { $0.isLetter })
        .map { $0.map(Square.init) }
    
    static let heightMapParser = rowParser.manyByNewline().skipTrailingNewlines().map(HeightMap.init)
    
    func testParseExample() throws {
        let heightMap = try Self.heightMapParser.parse(Self.example)
        XCTAssertEqual(heightMap.squares.count, 5)
        XCTAssertEqual(heightMap.squares.last?.last, .letter("i"))
    }
    
    func testParseInput() throws {
        let heightMap = try Self.heightMapParser.parse(Self.input)
        XCTAssertEqual(heightMap.squares.count, 41)
        XCTAssertEqual(heightMap.squares.last?.last, .letter("a"))
    }
}
