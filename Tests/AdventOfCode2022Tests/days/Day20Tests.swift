import AdventOfCode2022
import Parsing
import XCTest

final class Day20Tests: XCTestCase {
    // MARK: - part 1
    
    func testDecryptExample() throws {
        let ring = try Self.inputParser.parse(Self.example)
        ring.decryptPart1()
        XCTAssertEqual(ring.arrangement(), [0, 3, -2, 1, 2, -3, 4])
        XCTAssertEqual(ring.groveCoordinate(), 3)
    }
    
    func testDecryptInput() throws {
        let ring = try Self.inputParser.parse(Self.input)
        ring.decryptPart1()
        XCTAssertEqual(ring.groveCoordinate(), 4224)
    }
    
    // MARK: - part 2

    func testDecrypt2Example() throws {
        let ring = try Self.inputParser.parse(Self.example)
        ring.decryptPart2()
        XCTAssertEqual(ring.arrangement(), [0, -2434767459, 1623178306, 3246356612, -1623178306, 2434767459, 811589153])
        XCTAssertEqual(ring.groveCoordinate(), 1623178306)
    }
    
    func testDecrypt2Input() throws {
        let ring = try Self.inputParser.parse(Self.input)
        ring.decryptPart2()
        XCTAssertEqual(ring.groveCoordinate(), 861907680486)
    }
}

extension Day20Tests {
    struct Ring {
        let values: [Int]
        var nodes: [Node]
        var zeroNode: Node
        
        init(values: [Int]) {
            self.values = values
            self.nodes = values.map { Node(value: $0) }
            self.zeroNode = nodes.first(where: { $0.value == 0 })!
            
            for (l, r) in values.indices.adjacentPairs() {
                nodes[l].next = nodes[r]
                nodes[r].prev = nodes[l]
            }
            nodes.last!.next = nodes.first!
            nodes.first!.prev = nodes.last!
        }
        
        func decryptPart1() {
            nodes.indices.forEach { i in
                moveNodeAtIndex(i)
            }
        }
        
        func decryptPart2() {
            // apply the decryption key, 811589153
            let decryptionKey = 811589153
            for i in nodes.indices {
                nodes[i].value *= decryptionKey
            }
            
            // mix the list of numbers ten times
            10.times {
                decryptPart1()
            }
        }

        func groveCoordinate() -> Int {
            [1000, 2000, 3000]
                .map { offset in nthNode(offset, from: zeroNode).value }
                .reduce(0,+)
        }
        
        func arrangement() -> [Int] {
            var result = [Int]()
            var current = zeroNode
            repeat {
                result.append(current.value)
                current = current.next
            } while current !== zeroNode
            
            return result
        }
        
        func moveNodeAtIndex(_ index: Int) {
            let node = nodes[index]
            var after = nodeMovingPositions(node.value, from: node)
            if node.value < 0 {
                after = after.prev
            }
            moveNode(node, after: after)
        }

        /**
         https://www.reddit.com/r/adventofcode/comments/zrggym/2022_day_20_alice_in_wonderland_explains_the_two/
         */
        func nodeMovingPositions(_ positions: Int, from node: Node) -> Node {
            let modDistance = abs(positions) % (nodes.count - 1)
            return positions < 0 ?
                (0 ..< modDistance).reduce(node) { result, _ in result.prev } :
                (0 ..< modDistance).reduce(node) { result, _ in result.next }
        }

        func nthNode(_ n: Int, from node: Node) -> Node {
            assert(n > 0)
            return (0 ..< (n % nodes.count)).reduce(node) { result, _ in result.next }
        }
        
        func moveNode(_ node: Node, after: Node) {
            guard node !== after else { return }
            
            let (prev, next) = (node.prev!, node.next!)
            
            // remove node
            prev.next = next
            next.prev = prev

            // insert node
            after.next.prev = node
            node.next = after.next
            node.prev = after
            after.next = node
        }
    }
    
    class Node {
        var value: Int
        var next, prev: Node!
        
        init(value: Int, next: Node? = nil, prev: Node? = nil) {
            self.value = value
            self.next = next
            self.prev = prev
        }
    }
}

extension Day20Tests {
    static let input = resourceURL(filename: "Day20Input.txt")!.readContents()!
    
    static let example: String =
        """
        1
        2
        -3
        3
        -2
        0
        4
        """
    
    // MARK: - parser
    
    static let inputParser = From(.utf8) { Int.parser() }.manyByNewline().skipTrailingNewlines().map(Ring.init)
    
    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.nodes.count, 7)
    }
    
    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.nodes.count, 5000)
        XCTAssertEqual(input.nodes.last?.value, -938)
    }
}
