import AdventOfCode2022
import Charts
import EulerTools
import Parsing
import SwiftUI
import XCTest

final class Day09Tests: XCTestCase {
    // MARK: - Part 1
    
    func testApplyMovesExample() throws {
        let moves = try Self.movesParser.parse(Self.example)
        
        var bridge = Bridge(rope: .init(knotCount: 2))
        bridge.applyMovesAndFollows(moves)
        XCTAssertEqual(bridge.rope, .init([.init(2, 2), .init(1, 2)]))
        
        let tailPositions = bridge.history.map { $0.knots.last! }.uniqued().asArray
        XCTAssertEqual(tailPositions.count, 13)
    }
    
    func testApplyMovesInput() throws {
        let moves = try Self.movesParser.parse(Self.input)
        
        var bridge = Bridge(rope: .init(knotCount: 2))
        bridge.applyMovesAndFollows(moves)
        
        let tailPositions = bridge.history.map(\.tail).uniqued().asArray
        XCTAssertEqual(tailPositions.count, 6271)
    }
    
    // MARK: - Part 2

    func testApplyMoves10Example() throws {
        let moves = try Self.movesParser.parse(Self.example)
        
        var bridge = Bridge(rope: .init(knotCount: 10))
        bridge.applyMovesAndFollows(moves)
        XCTAssertEqual(bridge.rope.description, "rope: (2,2)_(1,2)_(2,2)_(3,2)_(2,2)_(1,1)_(0,0)_(0,0)_(0,0)_(0,0)")
        
        let tailPositions = bridge.history.map { $0.knots.last! }.uniqued().asArray
        XCTAssertEqual(tailPositions.count, 1)
    }
    
    func testApplyMoves10LargerExample() throws {
        let moves = try Self.movesParser.parse(Self.largerExample)
        
        var bridge = Bridge(rope: .init(knotCount: 10))
        bridge.applyMovesAndFollows(moves)
        
        let tailPositions = bridge.history.map { $0.knots.last! }.uniqued().asArray
        XCTAssertEqual(tailPositions.count, 36)
    }
    
    func testApplyMoves10Input() throws {
        let moves = try Self.movesParser.parse(Self.input)
        
        var bridge = Bridge(rope: .init(knotCount: 10))
        bridge.applyMovesAndFollows(moves)
        
        let tailPositions = bridge.history.map { $0.knots.last! }.uniqued().asArray
        XCTAssertEqual(tailPositions.count, 2458)
    }
    
    // MARK: - Charts
    
    func testChartsExample() async throws {
        let moves = try Self.movesParser.parse(Self.example)
        var bridge = Bridge(rope: .init(knotCount: 2))
        bridge.applyMovesAndFollows(moves)
        let tailPositions = bridge.history.map { $0.knots.last! }.uniqued().asArray
        
        let chart = await render(chartPositions(tailPositions))
        XCTAssertNotNil(chart)
    }
}

extension Day09Tests {
    @MainActor
    func render(_ chart: some View) -> CGImage? {
        let renderer = ImageRenderer(content: chart)
        return renderer.cgImage
    }
    
    func chartPositions(_ positions: [IndexXY]) -> some View {
        Chart {
            ForEach(positions.enumerated().asArray, id: \.offset) { offset, position in
                PointMark(x: .value("x", position.x), y: .value("y", position.y))
                    .foregroundStyle(by: .value("offset", offset))
            }
        }
        .chartXAxis {
            AxisMarks(preset: .extended, position: .bottom)
        }
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading)
        }
        .frame(height: 200)
        .padding()
    }
}

extension Day09Tests {
    struct Bridge {
        var rope: Rope
        var history: [Rope]
        
        init(rope: Rope) {
            self.rope = rope
            history = [rope]
        }
        
        mutating func applyMovesAndFollows(_ moves: [Move]) {
            for move in moves {
                //  print(move)
                applyMoveAndFollow(move)
            }
        }

        mutating func applyMoveAndFollow(_ move: Move) {
            for _ in 0 ..< move.steps {
                rope.moveHead(move.direction)
                rope.followHead()

                history.append(rope)
                // print(rope)
            }
        }
    }
    
    struct Rope: Equatable, CustomStringConvertible {
        var knots: [IndexXY]

        init(_ knots: [IndexXY]) {
            self.knots = knots
        }

        init(knotCount: Int) {
            knots = Array(repeating: .zero, count: knotCount)
        }
        
        var tail: IndexXY { knots.last! }
        
        mutating func moveHead(_ direction: Direction) {
            knots[0] += direction.step
        }
        
        mutating func followHead() {
            for k in 1 ..< knots.count {
                let delta = knots[k - 1] - knots[k]
                guard abs(delta.x) > 1 || abs(delta.y) > 1 else { return }
                knots[k] += IndexXY(x: delta.x.unitBias, y: delta.y.unitBias)
            }
        }
        
        var description: String {
            "rope: \(knots.map(\.description).joined(separator: "_"))"
        }
    }
    
    enum Direction: Equatable, CustomStringConvertible {
        case u, d, l, r
        
        var step: IndexXY {
            switch self {
            case .u: return .init(x: 0, y: +1)
            case .d: return .init(x: 0, y: -1)
            case .l: return .init(x: -1, y: 0)
            case .r: return .init(x: +1, y: 0)
            }
        }
        
        var description: String {
            switch self {
            case .u: return "U"
            case .d: return "D"
            case .l: return "L"
            case .r: return "R"
            }
        }
    }
    
    struct Move: Equatable, CustomStringConvertible {
        let direction: Direction
        let steps: Int
        
        var description: String {
            "move \(direction) \(steps)"
        }
    }
}

extension Day09Tests {
    static let input = resourceURL(filename: "Day09Input.txt")!.readContents()!
    
    static let example: String =
        """
        R 4
        U 4
        L 3
        D 1
        R 4
        D 1
        L 5
        R 2
        """
    
    static let largerExample: String =
        """
        R 5
        U 8
        L 8
        D 3
        R 17
        D 10
        L 25
        U 20
        """

    // MARK: - parser
    
    static let directionParser = OneOf {
        "U".map { Direction.u }
        "D".map { Direction.d }
        "L".map { Direction.l }
        "R".map { Direction.r }
    }
    
    static let moveParser = Parse(Move.init) {
        directionParser
        " "
        Int.parser()
    }
    
    static let movesParser = moveParser.manyByNewline().skipTrailingNewlines()
    
    func testParseExample() throws {
        let moves = try Self.movesParser.parse(Self.example)
        XCTAssertEqual(moves.count, 8)
        XCTAssertEqual(moves.last, Move(direction: .r, steps: 2))
    }
    
    func testParseInput() throws {
        let moves = try Self.movesParser.parse(Self.input)
        XCTAssertEqual(moves.count, 2000)
        XCTAssertEqual(moves.last, Move(direction: .l, steps: 12))
    }
}

private extension Int {
    var unitBias: Int {
        guard self != 0 else { return 0 }
        return self < 0 ? -1 : 1
    }
}
