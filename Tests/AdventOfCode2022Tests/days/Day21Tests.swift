import AdventOfCode2022
import Combine
import Parsing
import XCTest

final class Day21Tests: XCTestCase {
    // MARK: - part 1

    func testMonkeyYellsExample() async throws {
        let jungle = Jungle(monkeys: try Self.inputParser.parse(Self.example))
        print(jungle.walk())
        let root = await jungle.root.$value.compactMap { $0 }.values.first(where: { _ in true })
        XCTAssertEqual(root, 152)
    }
    
    func testMonkeyYellsInputs() async throws {
        let jungle = Jungle(monkeys: try Self.inputParser.parse(Self.input))
        let root = await jungle.root.$value.compactMap { $0 }.values.first(where: { _ in true })
        XCTAssertEqual(root, 80326079210554)
    }
    
    // MARK: - part 2
    
    func testHumanInputExample() async throws {
        let jungle = Jungle(monkeys: try Self.inputParser.parse(Self.example)).withHumanInput()
        print(jungle.walk())
        jungle.root.backPropagate(1)
        let humanInput = await jungle.humn.$value.compactMap { $0 }.values.first(where: { _ in true })
        XCTAssertEqual(humanInput, 301)
    }
    
    func testHumanInputInput() async throws {
        let jungle = Jungle(monkeys: try Self.inputParser.parse(Self.input)).withHumanInput()
        print(jungle.walk())
        jungle.root.backPropagate(1)
        let humanInput = await jungle.humn.$value.compactMap { $0 }.values.first(where: { _ in true })
        XCTAssertEqual(humanInput, 3617613952378)
    }
}

extension Day21Tests {
    class MonkeyNode {
        let monkey: Monkey
        var left, right: MonkeyNode?
        var cancellables = Set<AnyCancellable>()

        @Published var value: Int?
        @Published var isFixed: Bool?

        init(monkey: Day21Tests.Monkey) {
            self.monkey = monkey
        }
        
        func setInputs(left: MonkeyNode, right: MonkeyNode) {
            self.left = left
            self.right = right
        }
        
        func reset() {
            cancellables.removeAll()
            
            switch monkey.yell {
            case let .number(number):
                value = number
                isFixed = true

            case .human:
                value = nil
                isFixed = false

            case let .operation(_, op, _):
                guard let left, let right else { fatalError() }
                
                Publishers.CombineLatest(left.$value, right.$value)
                    .map(op.combine)
                    .sink { value in
                        self.value = value
                    }
                    .store(in: &cancellables)
                
                Publishers.CombineLatest(left.$isFixed, right.$isFixed)
                    .map { lhs, rhs in
                        guard let lhs, let rhs else { return nil }
                        return lhs && rhs
                    }
                    .sink { value in
                        self.isFixed = value
                    }
                    .store(in: &cancellables)
            }
        }
        
        func backPropagate(_ output: Int) {
            assert(isFixed == false)
            
            switch monkey.yell {
            case .human:
                value = output
            case .number:
                fatalError()
            case let .operation(_, op, _):
                guard let left, let right else { fatalError() }
                assert(left.isFixed != right.isFixed)
                if left.isFixed == false, let rhs = right.value {
                    left.backPropagate(op.reverseOutput(output, rhs: rhs))
                } else if right.isFixed == false, let lhs = left.value {
                    right.backPropagate(op.reverseOutput(output, lhs: lhs))
                } else {
                    fatalError()
                }
            }
        }
        
        func walk(_ indent: String = "") -> String {
            var result = "\(indent)(\(monkey.id) \(valueString)\(isFixedString)"
            if let left, let right {
                result += "\n\(left.walk(indent + indentation))" +
                    "\n\(right.walk(indent + indentation))" +
                    "\n\(indent)"
            }
            result += ")"
            return result
        }

        private let indentation = "   "
        private var valueString: String { value.flatMap { "\($0)" } ?? "-" }
        private var isFixedString: String { isFixed.flatMap { $0 ? "!" : "?" } ?? "" }
    }
    
    struct Jungle {
        let monkeys: [Monkey]
        let monkeyNodes: [Monkey.ID: MonkeyNode]
        
        init(monkeys: [Monkey]) {
            self.monkeys = monkeys
            self.monkeyNodes = Dictionary(uniqueKeysWithValues: monkeys.map { ($0.id, MonkeyNode(monkey: $0)) })
            
            for monkey in monkeys {
                guard case let .operation(lhs, _, rhs) = monkey.yell else { continue }
                monkeyNodes[monkey.id]!.setInputs(left: monkeyNodes[lhs]!, right: monkeyNodes[rhs]!)
            }
            
            for monkey in monkeyNodes.values {
                monkey.reset()
            }
        }
        
        func withHumanInput() -> Jungle {
            let updated = monkeys.map { monkey in
                switch monkey.id {
                case "root":
                    guard case let .operation(lhs, _, rhs) = monkey.yell else { fatalError() }
                    return Monkey(id: monkey.id, yell: .operation(lhs, .equals, rhs))
                case "humn":
                    return Monkey(id: monkey.id, yell: .human)
                default:
                    return monkey
                }
            }
            return Jungle(monkeys: updated)
        }
        
        var root: MonkeyNode { monkeyNodes["root"]! }
        var humn: MonkeyNode { monkeyNodes["humn"]! }
        
        func walk() -> String { root.walk() }
    }
    
    struct Monkey: Identifiable, Equatable {
        let id: String
        let yell: Yell
    }
    
    enum Yell: Equatable {
        case number(Int)
        case operation(Monkey.ID, Operator, Monkey.ID)
        case human
    }
    
    enum Operator: Equatable {
        case add, subtract, multiply, divide, equals
        
        func combine(_ lhs: Int?, rhs: Int?) -> Int? {
            guard let lhs, let rhs else { return nil }
            
            switch self {
            case .add: return lhs + rhs
            case .subtract: return lhs - rhs
            case .multiply: return lhs * rhs
            case .divide: return lhs / rhs
            case .equals: return lhs == rhs ? 1 : 0
            }
        }
        
        func reverseOutput(_ output: Int, rhs: Int) -> Int {
            switch self {
            case .add:
                return output - rhs
            case .subtract:
                return output + rhs
            case .multiply:
                return output / rhs
            case .divide:
                return output * rhs
            case .equals:
                assert(output == 1)
                return rhs
            }
        }

        func reverseOutput(_ output: Int, lhs: Int) -> Int {
            switch self {
            case .add:
                return output - lhs
            case .subtract:
                return lhs - output
            case .multiply:
                return output / lhs
            case .divide:
                return lhs / output
            case .equals:
                assert(output == 1)
                return lhs
            }
        }
    }
}

extension Day21Tests {
    static let input = resourceURL(filename: "Day21Input.txt")!.readContents()!
    
    static let monkeyParser = Parse(Monkey.init) {
        monkeyIdParser; ": "
        OneOf {
            Int.parser().map { Yell.number($0) }
            operationParser
        }
    }
            
    static let monkeyIdParser = Parse { CharacterSet.alphanumerics.map(String.init) }
    static let operationParser = Parse { Yell.operation($0, $1, $2) } with: {
        monkeyIdParser; " "
        operatorParser
        " "; monkeyIdParser
    }

    static let operatorParser = OneOf {
        "+".map { Operator.add }
        "-".map { Operator.subtract }
        "*".map { Operator.multiply }
        "/".map { Operator.divide }
    }

    static let example: String =
        """
        root: pppw + sjmn
        dbpl: 5
        cczh: sllz + lgvd
        zczc: 2
        ptdq: humn - dvpt
        dvpt: 3
        lfqf: 4
        humn: 5
        ljgn: 2
        sjmn: drzm * dbpl
        sllz: 4
        pppw: cczh / lfqf
        lgvd: ljgn * ptdq
        drzm: hmdt - zczc
        hmdt: 32
        """
    
    // MARK: - parser
    
    static let inputParser = monkeyParser.manyByNewline().skipTrailingNewlines()
    
    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.count, 15)
    }
    
    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.count, 2871)
    }
}
