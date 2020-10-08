/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public class Prefix<T> {
    typealias Builder = (T) -> T?

    let prec: Int
    let build: Builder

    init(_ build: @escaping Builder, _ prec: Int) {
        self.build = build
        self.prec = prec
    }

    func parse<
        O: Parser, P: Parser
    >
    (_ opp: OperatorPrecedence<T, O, P>, _ stream: CharStream) -> T?
        where P.Target == T, O.Target == String
    {
        if let arg = opp.parse(stream, prec) {
            return build(arg)
        }
        return nil
    }
}

public enum OperatorHandler<T> {
    public typealias Binary = (T, T) -> T?
    public typealias Unary = (T) -> T?

    case prefix(Unary, Int)
    case leftInfix(Binary, Int)
    case rightInfix(Binary, Int)
    case postfix(Unary, Int)

    public func parse<
        O: Parser, P: Parser
    >
    (_ opp: OperatorPrecedence<T, O, P>, _ stream: CharStream, _ lft: T?) -> T?
        where P.Target == T, O.Target == String
    {
        switch self {
        case let .prefix(unary, prec):
            assert(lft == nil, "Prefix operators don't have left hand sides.")
            if let arg = opp.parse(stream, prec) {
                return unary(arg)
            }

        case let .leftInfix(binary, prec):
            if let rgt = opp.parse(stream, prec) {
                return binary(lft!, rgt)
            }

        case let .rightInfix(binary, prec):
            if let rgt = opp.parse(stream, prec - 1) {
                return binary(lft!, rgt)
            }

        case let .postfix(unary, _):
            return unary(lft!)
        }
        return nil
    }

    var precedence: Int {
        switch self {
        case let .prefix(_, prec): return prec
        case let .leftInfix(_, prec): return prec
        case let .rightInfix(_, prec): return prec
        case let .postfix(_, prec): return prec
        }
    }
}

private class OpSet<V, O: Parser> where O.Target == String {
    let pattern: O
    var dict: [String: V]
    fileprivate var next: V?

    init(pattern: O) {
        self.pattern = pattern
        dict = [:]
        next = nil
    }

    func get(_ stream: CharStream) -> V? {
        if let val = next {
            next = nil
            return val
        }
        let old = stream.pos
        if let str = pattern.parse(stream) {
            if let retval = dict[str] {
                return retval
            } else {
                // Put characters back if we don't know how to use them here:
                // either they'll be picked-up by another round of processing
                // or there's a syntax error
                stream.pos = old
            }
        }
        return nil
    }

    func putBack(_ val: V) {
        assert(next == nil, "Expected cache to be empty.")
        next = val
    }
}

public class OperatorPrecedence<
    T, O: Parser, P: Parser
>: Parser
    where P.Target == T, O.Target == String
{
    public typealias Target = T

    fileprivate let infixOps: OpSet<OperatorHandler<T>, O>
    fileprivate let prefixOps: OpSet<OperatorHandler<T>, O>
    fileprivate let primary: P

    public init(opFormat: O, primary: P) {
        infixOps = OpSet<OperatorHandler<T>, O>(pattern: opFormat)
        prefixOps = OpSet<OperatorHandler<T>, O>(pattern: opFormat)
        self.primary = primary
    }

    public func parse(_ stream: CharStream) -> T? {
        return parse(stream, 0)
    }

    func parseStart(_ stream: CharStream) -> T? {
        if let pfx = prefixOps.get(stream) {
            return pfx.parse(self, stream, nil)
        }
        if let p = primary.parse(stream) {
            return p
        }
        return nil
    }

    func parse(_ stream: CharStream, _ prec: Int) -> T? {
        var lft = parseStart(stream)

        while let ifx = infixOps.get(stream) {
            if lft == nil {
                return nil
            }

            if ifx.precedence > prec {
                lft = ifx.parse(self, stream, lft!)
            } else {
                infixOps.putBack(ifx)
                break
            }
        }
        return lft
    }

    public func addOperator(_ name: String, _ op: OperatorHandler<T>) {
        switch op {
        case .prefix:
            prefixOps.dict[name] = op
        default:
            infixOps.dict[name] = op
        }
    }
}
