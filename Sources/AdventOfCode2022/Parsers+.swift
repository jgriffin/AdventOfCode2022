//
// Created by John Griffin on 12/2/22
//

import Parsing

public extension Parser where Input == Substring {
    /**
     convenence method to create a Many parser from a single parser
     */
    func many<Separator: Parser>(
        length: CountingRange = 1...,
        separator: Separator = "\n"
    ) -> AnyParser<Input, [Output]> where Separator.Input == Input {
        Many(length) {
            self
        } separator: {
            separator
        }
        .eraseToAnyParser()
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
