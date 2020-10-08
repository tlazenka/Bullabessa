/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence

public class Many<T: Parser>: Parser {
    public typealias Target = [T.Target]

    let body: T
    let emptyOk: Bool

    init(body: T, emptyOk: Bool) {
        self.body = body
        self.emptyOk = emptyOk
    }

    public func parse(_ stream: CharStream) -> Target? {
        var result = Target()
        while let r = body.parse(stream) {
            result.append(r)
        }
        if !emptyOk, result.isEmpty {
            return nil
        }
        return result
    }
}

public func many<T: Parser>(_ body: T) -> Many<T> {
    return Many(body: body, emptyOk: true)
}

public func many1<T: Parser>(_ body: T) -> Many<T> {
    return Many(body: body, emptyOk: false)
}

public class SepBy<T: Parser, S: Parser>: Parser {
    public typealias Target = [T.Target]

    let item: T
    let sep: S
    let pair: FollowedBySecond<S, T>

    init(item: T, sep: S) {
        self.item = item
        self.sep = sep
        pair = sep >~ item
    }

    public func parse(_ stream: CharStream) -> Target? {
        var result = Target()
        if let x = item.parse(stream) {
            result.append(x)
            while let next = pair.parse(stream) {
                result.append(next)
            }
        }
        return result
    }
}

public func sepby<T: Parser, S: Parser>(_ item: T, _ sep: S) -> SepBy<T, S> {
    return SepBy(item: item, sep: sep)
}
