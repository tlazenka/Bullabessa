/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

import Foundation

public class CharStream {
    let str: String
    var pos: String.Index

    public init(str: String) {
        self.str = str
        pos = str.startIndex
    }

    var head: Character? {
        if pos < str.endIndex {
            return str[pos]
        }
        return nil
    }

    var position: String.Index {
        get {
            return pos
        }
        set {
            pos = newValue
        }
    }

    var eof: Bool {
        return pos == str.endIndex
    }

    func startsWith(_ query: String) -> Bool {
        // return str.substring(from: pos).hasPrefix(query)
        return str[pos...].hasPrefix(query)
    }

    func startsWithRegex(_ pattern: String) -> String? {
        if let range = str.range(
            of: pattern,
            options: [.regularExpression, .anchored],
            range: pos ..< str.endIndex,
            locale: nil
        ) {
            // return str.substring(with: range)
            return String(str[range])
        }
        return nil
    }

    func advance(_ count: Int) {
        // pos = pos.advancedBy(count)
        pos = str.index(pos, offsetBy: count)
    }

    func error(_: String) {}
}
