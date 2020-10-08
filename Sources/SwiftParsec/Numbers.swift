/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public struct Integer: Parser {
    public typealias Target = Int

    static let impl = pipe(
        regex("[+-]?[0-9]+"),
        fn: { Int($0)! }
    )

    public func parse(_ stream: CharStream) -> Int? {
        return Integer.impl.parse(stream)
    }
}

public struct FloatParser: Parser {
    public typealias Target = Double

    fileprivate let strict: Bool

    static func stringToFloat(_ str: String) -> Double {
        if let d = Double(str) { return d }
        return Double.nan
    }

    static let impl = pipe(
        regex("[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?"),
        fn: FloatParser.stringToFloat
    )

    public init(strict: Bool) {
        self.strict = strict
    }

    public func parse(_ stream: CharStream) -> Target? {
        if !strict {
            return FloatParser.impl.parse(stream)
        }

        let start = stream.pos
        if let _ = Integer().parse(stream) {
            let intend = stream.pos
            stream.pos = start
            if let fp = FloatParser.impl.parse(stream) {
                if stream.pos == intend {
                    stream.pos = start
                    return nil
                }
                return fp
            }
        }
        return FloatParser.impl.parse(stream)
    }
}
