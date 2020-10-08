/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

import XCTest
@testable import SwiftParsec

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence
infix operator |>: PipePrecedence

func parse<T: Parser>(_ parser: T, _ string: String) -> T.Target? {
    let stream = CharStream(str: string)
    return parser.parse(stream)
}

class Expr {
    let symbol: String
    let children: [Expr]

    init(symbol: String, children: [Expr]) {
        self.symbol = symbol
        self.children = children
    }

    class func MakeFn(_ symbol: String, children: [Expr]) -> Expr {
        return Expr(symbol: symbol, children: children)
    }

    class func MakeLeaf(_ symbol: String) -> Expr {
        return Expr(symbol: symbol, children: [])
    }
}

func cStyle(_ expr: Expr) -> String {
    if expr.children.isEmpty {
        return expr.symbol
    }
    var args = cStyle(expr.children[0])
    for i in 1 ..< expr.children.count {
        args = args + ", " + cStyle(expr.children[i])
    }
    return "\(expr.symbol)(\(args))"
}

let skip = manychars(const(" "))
func idChar(c: Character) -> Bool {
    switch c {
    case "(", ")", " ", "!", "?", "+", "*", ",":
        return false
    default:
        return true
    }
}

let identifier = many1chars(satisfy(idChar)) ~> skip
let leaf = identifier |> Expr.MakeLeaf

class ExprOp {
    let symb: String

    init(_ symb: String) {
        self.symb = symb
    }

    func binary(left: Expr, _ right: Expr) -> Expr {
        return Expr.MakeFn(symb, children: [left, right])
    }

    func unary(arg: Expr) -> Expr {
        return Expr.MakeFn(symb, children: [arg])
    }
}

final class SwiftParsecTests: XCTestCase {
    func testCStyle() {
        let opFormat = regex("[+*!?-]") ~> skip
        let primary = LateBound<Expr>()
        let opp = OperatorPrecedence(opFormat: opFormat, primary: primary)

        opp.addOperator("+", .leftInfix(ExprOp("+").binary, 60))
        opp.addOperator("-", .leftInfix(ExprOp("-").binary, 60))
        opp.addOperator("*", .rightInfix(ExprOp("*").binary, 70))
        opp.addOperator("!", .prefix(ExprOp("!").unary, 200))
        opp.addOperator("?", .prefix(ExprOp("?").unary, 50))
        opp.addOperator("-", .prefix(ExprOp("-").unary, 200))
        opp.addOperator("+", .prefix(ExprOp("+").unary, 200))

        let oparen = const("(") ~> skip
        let cparen = const(")") ~> skip
        let comma = const(",") ~> skip

        let brackets = oparen >~ opp ~> cparen
        let fncall = identifier ~>~ (oparen >~ sepby(opp, comma) ~> cparen) |> Expr.MakeFn

        let flt = FloatParser(strict: false) ~> skip
        print(parse(flt, "-123") ?? "")
        print(parse(flt, "12.3") ?? "")
        print(parse(flt, "0.123") ?? "")
        print(parse(flt, "-.123") ?? "")
        print(parse(flt, "-12.3e39") ?? "")

        let number = flt |> { (x: Double) -> Expr in Expr.MakeLeaf("\(x)") }

        let termParser = fncall | brackets | number | leaf

        primary.inner = termParser.parse

        print(cStyle(parse(opp, "foo")!))
        print(cStyle(parse(opp, "foo + bar")!))
        print(cStyle(parse(opp, "foo + bar + abc")!))
        print(cStyle(parse(opp, "foo * bar + abc")!))
        print(cStyle(parse(opp, "22.3 + foo * abc")!))
        print(cStyle(parse(opp, "foo * abc + 43.79e3")!))
        print(cStyle(parse(opp, "foo + !43.79e3 * abc")!))
        print(cStyle(parse(opp, "22.3 + foo * abc")!))
        print(cStyle(parse(opp, "foo * (bar + abc)")!))
        print(cStyle(parse(opp, "foo * bar * abc")!))
        print(cStyle(parse(opp, "!foo")!))
        print(cStyle(parse(opp, "!?foo")!))
        print(cStyle(parse(opp, "!foo + bar")!))
        print(cStyle(parse(opp, "!(foo + bar)")!))
        print(cStyle(parse(opp, "?foo + bar")!))
        print(cStyle(parse(opp, "sqrt(a + b)")!))
        print(cStyle(parse(opp, "goo(a + b, c * sqrt(d))")!))
        print(cStyle(parse(opp, "foo - -bar")!))
        print(cStyle(parse(opp, "foo - -22.9")!))

        let m: Expr = parse(opp, "goo((a + b) * c, c * sqrt(d))")!

        XCTAssertNotNil(m)
    }

    func testSExpressions() {
        let skip = manychars(const(" "))

        func idChar(c: Character) -> Bool {
            switch c {
            case "(", ")", " ":
                return false
            default:
                return true
            }
        }
        let identifier = many1chars(satisfy(idChar)) ~> skip

        let leaf = identifier |> Expr.MakeLeaf

        let expr = LateBound<Expr>()
        let oparen = const("(") ~> skip
        let cparen = const(")") ~> skip
        let fnCall = oparen >~ pipe2(identifier, many(expr), Expr.MakeFn) ~> cparen
        let choice = fnCall | leaf
        expr.inner = choice.parse

        let sexpr = "(f (add a (g b)) a (g c))"
        let result: Expr? = parse(expr, sexpr)
        let cStyleResult = cStyle(result!)
        print("\(sexpr) = \(cStyleResult)")

        XCTAssertEqual(cStyleResult, "f(add(a, g(b)), a, g(c))")
    }

    func testJson() {
        let z = """
        {
            "a": 555
        }
        """

        let foo = JSParser.parse(z)
        XCTAssertNotNil(foo)
    }

    func testEgg() {
        indirect enum Expression: Equatable {
            case numberValue(number: Int)
            case word(name: String)
            case apply(operator: Expression, args: [Expression])

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

        let sexpr = """
        (do
          (define adder
            (fun a
                (fun b
                    (+ a b))))
          (define add_5 (adder 5))
          (print (add_5 3)))
        """.replacingOccurrences(of: "\n", with: "")
        let result: Expression = parse(expr, sexpr)!

        print(result)

        let expectedParse = Expression.apply(operator: .word(name: "do"), args: [
            .apply(operator: .word(name: "define"), args: [
                .word(name: "adder"),
                .apply(operator: .word(name: "fun"), args: [
                    .word(name: "a"),
                    .apply(operator: .word(name: "fun"), args: [
                        .word(name: "b"),
                        .apply(operator: .word(name: "+"), args: [
                            .word(name: "a"),
                            .word(name: "b"),
                        ]),
                    ]),
                ]),
            ]),
            .apply(operator: .word(name: "define"), args: [
                .word(name: "add_5"),
                .apply(operator: .word(name: "adder"), args: [
                    .numberValue(number: 5),
                ]),
            ]),
            .apply(operator: .word(name: "print"), args: [
                .apply(operator: .word(name: "add_5"), args: [
                    .numberValue(number: 3),
                ]),
            ]),
        ])

        XCTAssertEqual(expectedParse, result)

        XCTAssertNotNil(result)
    }
}
