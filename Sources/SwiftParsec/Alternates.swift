/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public class Alternates<T1: Parser, T2: Parser>: Parser where T1.Target == T2.Target {
    public typealias Target = T1.Target

    let first: T1
    let second: T2

    init(first: T1, second: T2) {
        self.first = first
        self.second = second
    }

    public func parse(_ stream: CharStream) -> Target? {
        if let fst = first.parse(stream) {
            return fst
        }
        if let snd = second.parse(stream) {
            return snd
        }
        return nil
    }
}

public func | <T1: Parser, T2: Parser>(
    first: T1,
    second: T2
) ->
    Alternates<T1, T2> where T1.Target == T2.Target
{
    return Alternates(first: first, second: second)
}
