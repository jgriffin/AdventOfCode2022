import AdventOfCode2022
import Algorithms
import Parsing
import XCTest

final class Day08Tests: XCTestCase {
    // MARK: - Part 1

    func testVisibleTreesExample() throws {
        let grid = try Self.gridParser.parse(Self.example)
        let visibleIndices = visibleIndices(grid)
        XCTAssertEqual(visibleIndices.count, 21)
    }

    func testVisibleTreesInput() throws {
        let grid = try Self.gridParser.parse(Self.input)
        let visibleIndices = visibleIndices(grid)
        XCTAssertEqual(visibleIndices.count, 1776)
    }

    // MARK: - Part 2

    func testScenicScoreExample() throws {
        let grid = try Self.gridParser.parse(Self.example)
        let visibleIndices = visibleIndices(grid)

        let score5 = scenicScore(grid, (3, 2))
        XCTAssertEqual(score5, 8)

        let scenicScores = visibleIndices.map { index in scenicScore(grid, index) }

        let best = scenicScores.max()
        XCTAssertEqual(best, 8)
    }

    func testScenicScoreInput() throws {
        let grid = try Self.gridParser.parse(Self.input)
        let visibleIndices = visibleIndices(grid)
        let scenicScores = visibleIndices.map { index in scenicScore(grid, index) }
        let best = scenicScores.max()
        XCTAssertEqual(best, 234_416)
    }
}

extension Day08Tests {
    typealias Grid = [[Int]]

    func scenicScore(_ grid: Grid, _ index: Grid.Index2D) -> Int {
        let scorer = sightLineScorer(grid, treeHeight: grid[index])

        let up = (0 ..< index.row).reversed().map { ($0, index.col) }
        let left = (0 ..< index.col).reversed().map { (index.row, $0) }
        let down = ((index.row + 1) ..< grid.count).map { ($0, index.col) }
        let right = ((index.col + 1) ..< grid[0].count).map { (index.row, $0) }

        let scores = [up, left, down, right].map(scorer)
        return scores.reduce(1,*)
    }

    func sightLineScorer(_ grid: Grid, treeHeight: Int) -> ([Grid.Index2D]) -> Int {
        { (sightLine: [Grid.Index2D]) in
            self.scenicScore(grid, treeHeight: treeHeight, sightLine: sightLine)
        }
    }

    func scenicScore(_ grid: Grid, treeHeight: Int, sightLine: [Grid.Index2D]) -> Int {
        var score = 0
        for index in sightLine {
            score += 1
            if grid[index] >= treeHeight {
                break
            }
        }
        return score
    }

    func visibleIndices(_ grid: Grid) -> [(row: Int, col: Int)] {
        var visibleTrees = Array(repeating: Array(repeating: false, count: grid[0].count), count: grid.count)

        func updateVisble(row: Int, col: Int, tallest: inout Int) {
            if grid[row][col] > tallest {
                visibleTrees[row][col] = true
            }
            tallest = max(tallest, grid[row][col])
        }

        // from left
        for row in grid.indices {
            var tallest: Int = -1
            for col in grid[row].indices {
                updateVisble(row: row, col: col, tallest: &tallest)
            }
        }

        // from right
        for row in grid.indices {
            var tallest: Int = -1
            for col in grid[row].indices.reversed() {
                updateVisble(row: row, col: col, tallest: &tallest)
            }
        }

        // from top
        for col in grid[0].indices {
            var tallest: Int = -1
            for row in grid.indices {
                updateVisble(row: row, col: col, tallest: &tallest)
            }
        }

        // from bottom
        for col in grid[0].indices {
            var tallest: Int = -1
            for row in grid.indices.reversed() {
                updateVisble(row: row, col: col, tallest: &tallest)
            }
        }

        return product(grid.indices, grid[0].indices).filter { visibleTrees[$0.0][$0.1] }
    }
}

extension Day08Tests {
    static let input = resourceURL(filename: "Day08Input.txt")!.readContents()!

    static let example: String =
        """
        30373
        25512
        65332
        33549
        35390
        """

    // MARK: - parser

    static let rowParser: some Parser<Substring, [Int]> = Prefix(1..., while: { $0.isNumber })
        .map { $0.map { Int(String($0))! }}
    static let gridParser = rowParser.manyByNewline().skipTrailingNewlines()

    func testParseExample() throws {
        let grid = try Self.gridParser.parse(Self.example)
        XCTAssertEqual(grid.count, 5)
        XCTAssertEqual(grid.first!.count, 5)
    }

    func testParseInput() throws {
        let grid = try Self.gridParser.parse(Self.input)
        XCTAssertEqual(grid.count, 99)
        XCTAssertEqual(grid.first!.count, 99)
    }
}
