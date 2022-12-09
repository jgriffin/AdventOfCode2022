import AdventOfCode2022
import Parsing
import XCTest

final class Day07Tests: XCTestCase {
    // MARK: - Part 1

    func testFileSystemExample() throws {
        let commands = try Self.inputParser.parse(Self.example)
        var fileSystem = FileSystem(commands: commands)
        let totalSize = fileSystem.calculateDirectorySize(["/"])
        XCTAssertEqual(totalSize, 48381165)
        
        let smallDirs = fileSystem.directorySizes.filter { $1 <= 100000 }
        let smallDirsSize = smallDirs.map(\.value).reduce(0, +)
        XCTAssertEqual(smallDirsSize, 95437)
    }
    
    func testFileSystemInput() throws {
        let commands = try Self.inputParser.parse(Self.input)
        var fileSystem = FileSystem(commands: commands)
        let totalSize = fileSystem.calculateDirectorySize(["/"])
        XCTAssertEqual(totalSize, 48044502)
        
        let smallDirs = fileSystem.directorySizes.filter { $1 <= 100000 }
        let smallDirsSize = smallDirs.map(\.value).reduce(0, +)
        XCTAssertEqual(smallDirsSize, 1449447)
    }
    
    // MARK: - Part 2
    
    let totalFileSystemSize = 70000000
    let sizeNeeded = 30000000

    func testDirectoryToDeleteExample() throws {
        let commands = try Self.inputParser.parse(Self.example)
        var fileSystem = FileSystem(commands: commands)
        let totalSize = fileSystem.calculateDirectorySize(["/"])
        XCTAssertEqual(totalSize, 48381165)
       
        let minSizeToDelete = totalSize + sizeNeeded - totalFileSystemSize
        XCTAssertEqual(minSizeToDelete, 8381165)
        
        let dirsBigEnough = fileSystem.directorySizes
            .filter { $0.value >= minSizeToDelete }
            .sorted(by: { $0.value < $1.value })
        
        XCTAssertEqual(dirsBigEnough.first?.key.joined(separator: "/"), "//d")
        XCTAssertEqual(dirsBigEnough.first?.value, 24933642)
    }
    
    func testDirectoryToDeleteInput() throws {
        let commands = try Self.inputParser.parse(Self.input)
        var fileSystem = FileSystem(commands: commands)
        let totalSize = fileSystem.calculateDirectorySize(["/"])
        XCTAssertEqual(totalSize, 48044502)
       
        let minSizeToDelete = totalSize + sizeNeeded - totalFileSystemSize
        XCTAssertEqual(minSizeToDelete, 8044502)
        
        let dirsBigEnough = fileSystem.directorySizes
            .filter { $0.value >= minSizeToDelete }
            .sorted(by: { $0.value < $1.value })
        
        XCTAssertEqual(dirsBigEnough.first?.key.joined(separator: "/"), "//jbt/bbm/tvqh/vjdjl")
        XCTAssertEqual(dirsBigEnough.first?.value, 8679207)
    }
}

extension Day07Tests {
    struct FileSystem {
        typealias PathSegment = Substring
        typealias Path = [PathSegment]

        var currentDir: Path = []
        var directories: [Path: [Content]] = [:]
        var directorySizes: [Path: Int] = [:]

        init(commands: [Command]) {
            commands.forEach { command in
                switch command {
                case .cdRoot:
                    currentDir = ["/"[...]]
                case .cdPop:
                    currentDir.removeLast()
                case let .cd(dir):
                    currentDir.append(dir)
                case let .ls(contents):
                    assert(directories[currentDir] == nil)
                    directories[currentDir] = contents
                }
            }
        }
        
        mutating func calculateDirectorySize(_ path: Path) -> Int {
            guard let contents = directories[path] else { fatalError() }
            
            let dirSize = contents.reduce(into: 0) { size, item in
                switch item {
                case let .file(_, fileSize):
                    size += fileSize
                case let .dir(dirName):
                    size += calculateDirectorySize(path + [dirName])
                }
            }
            
            directorySizes[path] = dirSize
            return dirSize
        }
    }
    
    enum Command: Equatable {
        case cdRoot
        case cdPop
        case cd(Substring)
        case ls([Content])
    }
    
    enum Content: Equatable {
        case dir(Substring)
        case file(Substring, Int)
    }
}

extension Day07Tests {
    static let input = resourceURL(filename: "Day07Input.txt")!.readContents()!
    
    static let example: String =
        """
        $ cd /
        $ ls
        dir a
        14848514 b.txt
        8504156 c.dat
        dir d
        $ cd a
        $ ls
        dir e
        29116 f
        2557 g
        62596 h.lst
        $ cd e
        $ ls
        584 i
        $ cd ..
        $ cd ..
        $ cd d
        $ ls
        4060174 j
        8033020 d.log
        5626152 d.ext
        7214296 k
        """
    
    // MARK: - parser
    
    static let commandParser = Parse {
        "$ "
        OneOf {
            "cd /".map { Command.cdRoot }
            "cd ..".map { Command.cdPop }
            Parse {
                "cd "
                CharacterSet.letters
            }.map { Command.cd($0) }
            
            Parse {
                "ls\n"
                contentParser.manyByNewline()
            }.map { Command.ls($0) }
        }
    }
    
    static let contentParser = OneOf {
        Parse {
            "dir "
            CharacterSet.letters
        }.map { Content.dir($0) }
        
        Parse {
            Int.parser()
            " "
            CharacterSet.letters.union(.init(charactersIn: "."))
        }.map { Content.file("\($1)", $0) }
    }
    
    static let inputParser = commandParser.manyByNewline().skipTrailingNewlines()
    
    func testParseExample() throws {
        let input = try Self.inputParser.parse(Self.example)
        XCTAssertEqual(input.count, 10)
    }
    
    func testParseInput() throws {
        let input = try Self.inputParser.parse(Self.input)
        XCTAssertEqual(input.count, 554)
    }
}
