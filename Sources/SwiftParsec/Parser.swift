/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public protocol Parser {
    associatedtype Target
    func parse(_: CharStream) -> Target?
}
