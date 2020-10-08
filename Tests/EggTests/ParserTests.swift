import XCTest
@testable import Egg

final class ParserTests: XCTestCase {
    func testParser() throws {
        do {
            let result = try parse(program: "\"abc\"")
            guard case let .stringValue(value) = result else {
                throw TypeError("Expected string")
            }

            XCTAssertEqual(value, "abc")
        }

        do {
            XCTAssertThrowsError(try parse(program: "()")) { error in
                XCTAssert(error is SyntaxError)
            }
        }

        do {
            let result = try parse(program: "abc()")

            XCTAssertEqual(result, Expression.apply(operator: .word(name: "abc"), args: []))
        }

        do {
            let result = try parse(program: "abc(\"param\", 3, var)")

            XCTAssertEqual(result, Expression.apply(operator: .word(name: "abc"), args: [.stringValue(string: "param"), .numberValue(number: 3), .word(name: "var")]))
        }

        do {
            let result = try parse(program: "abc(def())")

            XCTAssertEqual(result, Expression.apply(operator: .word(name: "abc"), args: [.apply(operator: .word(name: "def"), args: [])]))
        }

        do {
            let result = try parse(program: "abc()()")

            XCTAssertEqual(result, Expression.apply(operator: .apply(operator: .word(name: "abc"), args: []), args: []))
        }
    }

    func testParsec() throws {
        do {
            XCTAssertThrowsError(try parsec(program: "()")) { error in
                XCTAssert(error is SyntaxError)
            }
        }

        do {
            let result = try parsec(program: "(abc)")

            XCTAssertEqual(result, Expression.apply(operator: .word(name: "abc"), args: []))
        }

        do {
            let result = try parsec(program: "(abc (def))")

            XCTAssertEqual(result, Expression.apply(operator: .word(name: "abc"), args: [.apply(operator: .word(name: "def"), args: [])]))
        }

        do {
            let result = try parsec(program: "((abc))")

            XCTAssertEqual(result, Expression.apply(operator: .apply(operator: .word(name: "abc"), args: []), args: []))
        }
    }
}
