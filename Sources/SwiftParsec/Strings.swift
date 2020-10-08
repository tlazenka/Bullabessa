/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence

public class Constant<T>: Parser {
    let value: T
    let str: String

    init(value: T) {
        self.value = value
        str = "\(value)"
    }

    public typealias Target = T

    public func parse(_ stream: CharStream) -> Target? {
        if stream.startsWith(str) {
            stream.advance(str.count)
            return value
        }
        stream.error("Expected \(str)")
        return nil
    }
}

public func const<T>(_ value: T) -> Constant<T> {
    return Constant(value: value)
}

public class Regex: Parser {
    public typealias Target = String

    let pattern: String

    init(pattern: String) {
        self.pattern = pattern
    }

    public func parse(_ stream: CharStream) -> Target? {
        if let match = stream.startsWithRegex(pattern) {
            stream.advance(match.count)
            return match
        }
        return nil
    }
}

public func regex(_ pattern: String) -> Regex {
    return Regex(pattern: pattern)
}

public class Satisfy: Parser {
    let condition: (Character) -> Bool

    public typealias Target = Character

    init(condition: @escaping (Character) -> Bool) {
        self.condition = condition
    }

    public func parse(_ stream: CharStream) -> Target? {
        if let ch = stream.head {
            if condition(ch) {
                stream.advance(1)
                return ch
            }
        }
        return nil
    }
}

public func satisfy(_ condition: @escaping (Character) -> Bool) -> Satisfy {
    return Satisfy(condition: condition)
}

public class EndOfFile: Parser {
    public typealias Target = Void

    public func parse(_ stream: CharStream) -> Target? {
        if stream.eof {
            return Target()
        } else {
            return nil
        }
    }
}

public func eof() -> EndOfFile {
    return EndOfFile()
}

// Helpful versions which turn arrays of Characters into Strings
public func arrayToString<T: Parser>
(_ parser: T) -> Pipe<T, String> where T.Target == [Character] {
    return pipe(parser, fn: { String($0) })
}

public func manychars<T: Parser>
(_ item: T) -> Pipe<Many<T>, String> where T.Target == Character {
    return arrayToString(many(item))
}

public func many1chars<T: Parser>
(_ item: T) -> Pipe<Many<T>, String> where T.Target == Character {
    return arrayToString(many1(item))
}

// Overloaded followed-by operators
public func >~ <T: Parser>(first: String, second: T) -> FollowedBySecond<Constant<String>, T> {
    return FollowedBySecond(first: const(first), second: second)
}

public func ~> <T: Parser>(first: T, second: String) -> FollowedByFirst<T, Constant<String>> {
    return FollowedByFirst(first: first, second: const(second))
}
