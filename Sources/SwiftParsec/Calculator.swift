/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

import Foundation

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence

struct Calculator: Parser {
    // Skip over whitespace
    static let skip = regex("\\s*")

    // The operator precendence parser at the heart of our calculator
    static let opFormat = regex("[+*-/%\\^]") ~> skip
    static let primary = LateBound<Double>()
    static let opp = OperatorPrecedence(opFormat: opFormat, primary: primary)

    // Useful character constants
    static let oparen = const("(") ~> skip
    static let cparen = const(")") ~> skip

    // Floating-point number literals
    static let flt = FloatParser(strict: false) ~> skip

    // Functions
    static let arg1 = oparen >~ opp ~> cparen
    static let sinfunc = const("sin") >~ arg1 |> sin
    static let cosfunc = const("cos") >~ arg1 |> cos
    static let tanfunc = const("tan") >~ arg1 |> tan
    static let expfunc = const("exp") >~ arg1 |> exp
    static let logfunc = const("log") >~ arg1 |> log
    static let sqrtfunc = const("sqrt") >~ arg1 |> sqrt
    static let funcs = sinfunc | cosfunc | tanfunc | expfunc | logfunc | sqrtfunc

    // A term in brackets
    static let brackets = oparen >~ opp ~> cparen

    // Parsing primaries within an infix expression
    static let primaryImpl = funcs | brackets | flt

    fileprivate static func initialize() {
        if primary.inner == nil {
            // Add infix operators
            opp.addOperator("+", .leftInfix({ $0 + $1 }, 50))
            opp.addOperator("-", .leftInfix({ $0 - $1 }, 50))
            opp.addOperator("*", .leftInfix({ $0 * $1 }, 70))
            opp.addOperator("/", .leftInfix({ $0 / $1 }, 70))
            opp.addOperator("%", .leftInfix({ $0.truncatingRemainder(dividingBy: $1) }, 70))
            opp.addOperator("^", .leftInfix({ pow($0, $1) }, 80))

            // Add prefix operators
            opp.addOperator("+", .prefix({ +$0 }, 60))
            opp.addOperator("-", .prefix({ -$0 }, 60))

            // Close the loop
            primary.inner = primaryImpl.parse
        }
    }

    static func parse(_ stream: CharStream) -> Double? {
        initialize()
        return opp.parse(stream)
    }

    // Parser implementation
    typealias Target = Double
    func parse(_ stream: CharStream) -> Target? {
        return Calculator.parse(stream)
    }
}
