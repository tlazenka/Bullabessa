/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public class Pipe<T: Parser, V>: Parser {
    public typealias Target = V
    typealias R = T.Target

    let parser: T
    let fn: (R) -> V

    init(inner: T, fn: @escaping (R) -> V) {
        parser = inner
        self.fn = fn
    }

    public func parse(_ stream: CharStream) -> Target? {
        if let value = parser.parse(stream) {
            return fn(value)
        }
        return nil
    }
}

public func pipe<T: Parser, V>(_ inner: T, fn: @escaping (T.Target) -> V) -> Pipe<T, V> {
    return Pipe(inner: inner, fn: fn)
}

precedencegroup PipePrecedence {
    associativity: left
}

infix operator |>: PipePrecedence
public func |> <T: Parser, V>(inner: T, fn: @escaping (T.Target) -> V) -> Pipe<T, V> {
    return pipe(inner, fn: fn)
}

public class Pipe2<T1: Parser, T2: Parser, V>: Parser {
    public typealias Target = V
    typealias R1 = T1.Target
    typealias R2 = T2.Target

    let first: T1
    let second: T2
    let fn: (R1, R2) -> V

    init(first: T1, second: T2, fn: @escaping (R1, R2) -> V) {
        self.first = first
        self.second = second
        self.fn = fn
    }

    public func parse(_ stream: CharStream) -> Target? {
        let old = stream.position
        if let a = first.parse(stream) {
            if let b = second.parse(stream) {
                return fn(a, b)
            }
        }
        stream.position = old
        return nil
    }
}

public func pipe2<T1: Parser, T2: Parser, V>(
    _ first: T1,
    _ second: T2,
    _ fn: @escaping (T1.Target, T2.Target) -> V
) -> Pipe2<T1, T2, V> {
    return Pipe2(first: first, second: second, fn: fn)
}
