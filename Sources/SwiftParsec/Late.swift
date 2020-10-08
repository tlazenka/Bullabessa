/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public class LateBound<T>: Parser {
    public typealias Target = T
    public typealias ParseFunc = (CharStream) -> T?

    public var inner: ParseFunc?

    public init() {}

    public func parse(_ stream: CharStream) -> T? {
        if let impl = inner {
            return impl(stream)
        }
        fatalError("No inner implementation was provided for late-bound parser.")
    }
}
