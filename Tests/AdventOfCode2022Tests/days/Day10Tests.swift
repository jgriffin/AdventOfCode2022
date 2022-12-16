import AdventOfCode2022
import Charts
import Parsing
import SwiftUI
import XCTest

final class Day10Tests: XCTestCase {
    // MARK: - Part 1

    func testStatesSimpleExample() throws {
        let instructions = try Self.instructionsParser.parse(Self.simpleExample)
        let states = instructions.reductions(State()) { $0.applying($1) }
        XCTAssertEqual(states.count, 4)
        XCTAssertEqual(states.last, .init(cycle: 6, x: -1))
    }
    
    func testStatesLargerExample() async throws {
        let instructions = try Self.instructionsParser.parse(Self.largerExample)
        let states = instructions.reductions(State()) { $0.applying($1) }
        
        XCTAssertEqual(states.count, 147)
        XCTAssertEqual(states.last, .init(cycle: 241, x: 17))
    }
    
    func testStatesInput() throws {
        let instructions = try Self.instructionsParser.parse(Self.input)
        let states = instructions.reductions(State()) { $0.applying($1) }
        
        XCTAssertEqual(states.count, 138)
        XCTAssertEqual(states.last, .init(cycle: 241, x: 32))
    }
    
    func testSignalStrengthsLargerExample() throws {
        let instructions = try Self.instructionsParser.parse(Self.largerExample)
        let states = instructions.reductions(State()) { $0.applying($1) }
        let cycles = stride(from: 20, to: states.last!.cycle, by: 40).asArray
        let cyclesStates = cycles.map(states.stateForCycle)
        let strengths = cyclesStates.map(\.signalStrength)

        XCTAssertEqual(cyclesStates, [
            .init(cycle: 20, x: 21),
            .init(cycle: 60, x: 19),
            .init(cycle: 100, x: 18),
            .init(cycle: 140, x: 21),
            .init(cycle: 180, x: 16),
            .init(cycle: 220, x: 18),
        ])
        
        XCTAssertEqual(strengths, [420, 1140, 1800, 2940, 2880, 3960])
        XCTAssertEqual(strengths.reduce(0,+), 13140)
    }
    
    func testSignalStrengthsInput() throws {
        let instructions = try Self.instructionsParser.parse(Self.input)
        let states = instructions.reductions(State()) { $0.applying($1) }
        let cycles = stride(from: 20, to: states.last!.cycle, by: 40).asArray
        let cyclesStates = cycles.map(states.stateForCycle)
        let strengths = cyclesStates.map(\.signalStrength)

        XCTAssertEqual(strengths, [240, 240, 3900, 3080, 3060, 4620])
        XCTAssertEqual(strengths.reduce(0,+), 15140)
    }
    
    // MARK: - Part 2
    
    func testCRTOutputLargerExample() throws {
        let instructions = try Self.instructionsParser.parse(Self.largerExample)
        let states = instructions.reductions(State()) { $0.applying($1) }

        let output = crtOutput(states)
        XCTAssertEqual(
            output,
            """
            ##..##..##..##..##..##..##..##..##..##..
            ###...###...###...###...###...###...###.
            ####....####....####....####....####....
            #####.....#####.....#####.....#####.....
            ######......######......######......####
            #######.......#######.......#######.....
            """
        )
    }

    func testCRTOutputInput() throws {
        let instructions = try Self.instructionsParser.parse(Self.input)
        let states = instructions.reductions(State()) { $0.applying($1) }

        let output = crtOutput(states)
        XCTAssertEqual(
            output,
            """
            ###..###....##..##..####..##...##..###..
            #..#.#..#....#.#..#....#.#..#.#..#.#..#.
            ###..#..#....#.#..#...#..#....#..#.#..#.
            #..#.###.....#.####..#...#.##.####.###..
            #..#.#....#..#.#..#.#....#..#.#..#.#....
            ###..#.....##..#..#.####..###.#..#.#....
            """
        )
        // "BPJAZGAP"
    }

    func crtOutput(_ states: [State]) -> String {
        (0 ..< 240).chunks(ofCount: 40)
            .map { slice in
                slice.map { i in
                    let position = i % 40
                    let state = states.stateForCycle(i + 1)
                    return ((position - 1)...(position + 1)).contains(state.x) ? "#" : "."
                }
                .joined()
            }
            .joined(separator: "\n")
    }
    
    // MARK: - chart
    
    struct StateChart: View {
        let states: [Day10Tests.State]
        
        var body: some View {
            Chart {
                ForEach(states.indices, id: \.self) { index in
                    PointMark(x: .value("cycle", states[index].cycle),
                              y: .value("x", states[index].x))
                }
                ForEach(0...240, id: \.self) { cycle in
                    LineMark(x: .value("cycle", cycle),
                             y: .value("p", cycle % 40))
                }
            }
            .chartXScale(domain: 0...240, range: .plotDimension(padding: 10))
            .chartYScale(domain: 0...40, range: .plotDimension(padding: 10))
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) {
                    AxisTick()
                }
                AxisMarks(values: .stride(by: 5)) {
                    AxisGridLine()
                }
                AxisMarks(values: .stride(by: 10)) {
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1)) {
                    AxisTick()
                }
                AxisMarks(values: .stride(by: 5)) {
                    AxisGridLine()
                }
                AxisMarks(values: .stride(by: 10)) {
                    AxisValueLabel()
                }
            }

            .frame(width: 2000, height: 400)
        }
    }
    
    func testChartLargerExample() async throws {
        let instructions = try Self.instructionsParser.parse(Self.largerExample)
        let states = instructions.reductions(State()) { $0.applying($1) }.fillCycles()
        
        let chart = await StateChart(states: states).renderCGImage(scale: 2)
        XCTAssertNotNil(chart)
    }
}

extension Day10Tests {
    struct State: Equatable, CustomStringConvertible {
        var cycle: Int = 1
        var x: Int = 1
        
        var signalStrength: Int { cycle * x }
        
        func applying(_ instruction: Instruction) -> State {
            switch instruction {
            case .noop:
                return .init(cycle: cycle + 1, x: x)
            case let .addX(value):
                return .init(cycle: cycle + 2, x: x + value)
            }
        }
        
        var description: String { "(cycle: \(cycle), x: \(x))" }
    }
    
    enum Instruction: Equatable {
        case noop
        case addX(Int)
    }
}

extension Array where Element == Day10Tests.State {
    func stateForCycle(_ cycle: Int) -> Element {
        guard let best = last(where: { $0.cycle <= cycle }) else { fatalError() }
        return .init(cycle: cycle, x: best.x)
    }
    
    func fillCycles() -> [Day10Tests.State] {
        (0 ..< count).map { stateForCycle($0 + 1) }
    }
}

extension Day10Tests {
    static let input = resourceURL(filename: "Day10Input.txt")!.readContents()!
    
    static let simpleExample: String =
        """
        noop
        addx 3
        addx -5
        """
    
    // MARK: - parser
    
    static let instructionParser = OneOf {
        "noop".map { Instruction.noop }
        Parse {
            "addx "
            Int.parser()
        }.map { Instruction.addX($0) }
    }
    
    static let instructionsParser = instructionParser.manyByNewline().skipTrailingNewlines()
    
    func testParseSimpleExample() throws {
        let instructions = try Self.instructionsParser.parse(Self.simpleExample)
        XCTAssertEqual(instructions.count, 3)
        XCTAssertEqual(instructions.last, .addX(-5))
    }
    
    func testParseLargerExample() throws {
        let instructions = try Self.instructionsParser.parse(Self.largerExample)
        XCTAssertEqual(instructions.count, 146)
        XCTAssertEqual(instructions.suffix(3), [.noop, .noop, .noop])
    }

    func testParseInput() throws {
        let instructions = try Self.instructionsParser.parse(Self.input)
        XCTAssertEqual(instructions.count, 137)
        XCTAssertEqual(instructions.suffix(3), [.noop, .noop, .noop])
    }
    
    static var largerExample: String {
        """
        addx 15
        addx -11
        addx 6
        addx -3
        addx 5
        addx -1
        addx -8
        addx 13
        addx 4
        noop
        addx -1
        addx 5
        addx -1
        addx 5
        addx -1
        addx 5
        addx -1
        addx 5
        addx -1
        addx -35
        addx 1
        addx 24
        addx -19
        addx 1
        addx 16
        addx -11
        noop
        noop
        addx 21
        addx -15
        noop
        noop
        addx -3
        addx 9
        addx 1
        addx -3
        addx 8
        addx 1
        addx 5
        noop
        noop
        noop
        noop
        noop
        addx -36
        noop
        addx 1
        addx 7
        noop
        noop
        noop
        addx 2
        addx 6
        noop
        noop
        noop
        noop
        noop
        addx 1
        noop
        noop
        addx 7
        addx 1
        noop
        addx -13
        addx 13
        addx 7
        noop
        addx 1
        addx -33
        noop
        noop
        noop
        addx 2
        noop
        noop
        noop
        addx 8
        noop
        addx -1
        addx 2
        addx 1
        noop
        addx 17
        addx -9
        addx 1
        addx 1
        addx -3
        addx 11
        noop
        noop
        addx 1
        noop
        addx 1
        noop
        noop
        addx -13
        addx -19
        addx 1
        addx 3
        addx 26
        addx -30
        addx 12
        addx -1
        addx 3
        addx 1
        noop
        noop
        noop
        addx -9
        addx 18
        addx 1
        addx 2
        noop
        noop
        addx 9
        noop
        noop
        noop
        addx -1
        addx 2
        addx -37
        addx 1
        addx 3
        noop
        addx 15
        addx -21
        addx 22
        addx -6
        addx 1
        noop
        addx 2
        addx 1
        noop
        addx -10
        noop
        noop
        addx 20
        addx 1
        addx 2
        addx 2
        addx -6
        addx -11
        noop
        noop
        noop
        """
    }
}
