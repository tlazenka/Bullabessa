import Foundation

struct SyntaxError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

indirect enum Expression: Equatable {
    case stringValue(string: String)
    case numberValue(number: Int)
    case word(name: String)
    case apply(operator: Expression, args: [Expression])

    enum Regex: String, CaseIterable {
        case stringValue = #"^"([^"]*)""#
        case numberValue = #"^[+-]?\d+\b"#
        case word = #"^[^\d(),"][^(),"]*"#

        func parse(text: String) throws -> (Expression, Substring)? {
            let regex = try NSRegularExpression(pattern: rawValue, options: .caseInsensitive)
            guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf8.count)) else {
                return nil
            }

            switch self {
            case .stringValue:
                guard let range = Range(match.range(at: 1), in: text) else { return nil }
                guard let rangeAll = Range(match.range(at: 0), in: text) else { return nil }
                return (.stringValue(string: String(text[range])), text[rangeAll.upperBound...])
            case .numberValue:
                guard let range = Range(match.range(at: 0), in: text) else { return nil }
                guard let val = Int(String(text[range])) else { return nil }
                return (.numberValue(number: val), text[range.upperBound...])
            case .word:
                guard let range = Range(match.range(at: 0), in: text) else { return nil }
                return (.word(name: String(text[range])), text[range.upperBound...])
            }
        }
    }
}

struct ParseResult {
    let expr: Expression
    let rest: String
}

func parse(program: String) throws -> Expression {
    let program = skipSpace(program)

    let result = try parseExpression(program: program)

    if !result.rest.isEmpty {
        throw SyntaxError("Unexpected text after program")
    }

    return result.expr
}

func parseExpression(program: String) throws -> ParseResult {
    for regex in Expression.Regex.allCases {
        guard let result = try regex.parse(text: program) else { continue }
        let expr = result.0
        let rest = result.1

        return try parseApply(expr: expr, program: String(rest))
    }

    throw SyntaxError("Unexpected syntax: " + program)
}

func skipSpace(_ string: String) -> String {
    string.replacingOccurrences(of: #"(\s|#.*)*"#, with: "", options: [.regularExpression])
}

func parseApply(expr: Expression, program: String) throws -> ParseResult {
    guard program[intIndex: 0] == "(" else {
        return ParseResult(expr: expr, rest: program)
    }

    var program = program.slice(1)

    var args: [Expression] = []

    while program[intIndex: 0] != ")" {
        let arg = try parseExpression(program: program)
        args.append(arg.expr)
        program = arg.rest

        if program[intIndex: 0] == "," {
            program = program.slice(1)
        } else if program[intIndex: 0] != ")" {
            throw SyntaxError("Expected ',' or ')'")
        }
    }

    let expr = Expression.apply(operator: expr, args: args)

    return try parseApply(expr: expr, program: program.slice(1))
}

import SwiftParsec

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence
infix operator |>: PipePrecedence

extension Expression {
    static func MakeFn(_ operator: Expression, children: [Expression]) -> Expression {
        return Expression.apply(operator: `operator`, args: children)
    }

    static func MakeLeaf(_ symbol: String) -> Expression {
        if let intValue = Int(symbol) {
            return Expression.numberValue(number: intValue)
        } else {
            return Expression.word(name: symbol)
        }
    }
}

func parsec(program: String) throws -> Expression {
    let program = program.replacingOccurrences(of: "\n", with: "")
    let charStrean = CharStream(str: program)

    let skip = manychars(const(" ") | const("\n") | const("\t"))

    func idChar(c: Character) -> Bool {
        switch c {
        case "(", ")", " ":
            return false
        default:
            return true
        }
    }
    let identifier = many1chars(satisfy(idChar)) ~> skip

    func valueChar(c: Character) -> Bool {
        c.isNumber
    }

    let value = many1chars(satisfy(valueChar)) ~> skip

    let leaf = (identifier | value) |> Expression.MakeLeaf

    let expr = LateBound<Expression>()
    let oparen = const("(") ~> skip
    let cparen = const(")") ~> skip
    let fnCall = oparen >~ pipe2(expr, many(expr), Expression.MakeFn) ~> cparen
    let choice = fnCall | leaf
    expr.inner = choice.parse

    guard let result = expr.parse(charStrean) else {
        throw SyntaxError("Invalid syntax")
    }

    return result
}
