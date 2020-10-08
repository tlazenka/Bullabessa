import XCTest
@testable import Egg

final class RuntimeTests: XCTestCase {
    func testRuntime() throws {
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

        do {
            let program = """
            do(
            define(adder, fun(a,
              fun(b, # Anonymous function
                +(a, b)))), # a is stored inside this function

            define(add_5, adder(5)),

            print(add_5(3)))

            """

            let parsed = try parse(program: program)

            XCTAssertEqual(expectedParse, parsed)

            var scope: Scope = topScope

            let evaluated = try evaluate(expr: parsed, scope: &scope)

            guard case let .number(result) = evaluated else {
                throw TypeError("Expected number")
            }

            XCTAssertEqual(result, 8)
        }

        do {
            let program = """
            (do
                (define adder
                    (fun a
                        (fun b
                            (+ a b))))

                (define add_5 (adder 5))

                (print (add_5 3)))
            """

            let parsed = try parsec(program: program)

            XCTAssertEqual(expectedParse, parsed)

            var scope: Scope = topScope

            let evaluated = try evaluate(expr: parsed, scope: &scope)

            guard case let .number(result) = evaluated else {
                throw TypeError("Expected number")
            }

            XCTAssertEqual(result, 8)
        }
    }
}
