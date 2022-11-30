import Foundation
import XCTest

extension XCTestCase {
    static func resourceURL(filename: String) -> URL? {
        Bundle.module.url(forResource: filename, withExtension: nil)
    }

    static func stringFromURL(_ url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
}

extension URL {
    func readContents() -> String? {
        try? String(contentsOf: self, encoding: .utf8)
    }

    func readLines() -> [Substring]? {
        readContents()?.split(separator: "\n")
    }
}

extension String {
    func lines() -> [Substring] {
        split(separator: "\n")
    }
}
