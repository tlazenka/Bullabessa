/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

public class Token<T: Parser, V>: Parser {
    public typealias Target = V

    let trigger: T
    let value: V

    init(trigger: T, value: V) {
        self.trigger = trigger
        self.value = value
    }

    public func parse(_ stream: CharStream) -> Target? {
        if let _ = trigger.parse(stream) {
            return value
        }
        return nil
    }
}

public func token<T: Parser, V>(_ trigger: T, value: V) -> Token<T, V> {
    return Token(trigger: trigger, value: value)
}
