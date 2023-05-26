//
// Created by John Griffin on 12/2/22
//

import Parsing

public extension Parser {
    func many(
        length: CountingRange = 1...
    ) -> AnyParser<Input, [Output]> {
        Many(length) { self }
            .eraseToAnyParser()
    }

    /**
     convenence method to create a Many parser from a single parser
     */
    func many<Separator: Parser>(
        length: CountingRange = 1...,
        separator: Separator
    ) -> AnyParser<Input, [Output]> where Separator.Input == Input {
        Many(length) { self } separator: { separator }
            .eraseToAnyParser()
    }
}

public extension Parser where Input == Substring {
    func manyByNewline(
        length: CountingRange = 1...
    ) -> AnyParser<Input, [Output]> {
        many(length: length, separator: "\n")
    }

    /**
     convenence method to create a parser which skips optional trailing newline
     */
    func skipTrailingNewlines() -> AnyParser<Input, Output> {
        Parse {
            self
            Skip { Optionally { "\n" } }
        }
        .eraseToAnyParser()
    }
}

public extension Parser where Input == Substring.UTF8View {
    func manyByNewline(
        length: CountingRange = 1...
    ) -> AnyParser<Input, [Output]> {
        many(length: length, separator: "\n".utf8)
    }

    /**
     convenence method to create a parser which skips optional trailing newline
     */
    func skipTrailingNewlines() -> AnyParser<Input, Output> {
        Parse {
            self
            Skip { Optionally { "\n".utf8 } }
        }
        .eraseToAnyParser()
    }
}
