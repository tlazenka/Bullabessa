/*
 Copyright (c) 2015 Oliver Williams.

 This file was modified from the original.

 */

infix operator ~>~: FunctionCompositionPrecedence
infix operator ~>: FunctionCompositionPrecedence
infix operator >~: FunctionCompositionPrecedence

typealias JSObject = [String: JSValue]
func makeObj(_ values: [(String, JSValue)]) -> JSObject {
    var record = JSObject()
    for (name, val) in values {
        record[name] = val
    }
    return record
}

enum JSValue: CustomStringConvertible {
    case string(String)
    case number(Double)
    case object(JSObject)
    case array([JSValue])
    case bool(Bool)
    case null

    static func make(_ s: String) -> JSValue { return string(s) }
    static func make(_ n: Double) -> JSValue { return number(n) }
    static func make(_ b: Bool) -> JSValue { return bool(b) }
    static func make(_ o: JSObject) -> JSValue { return object(o) }
    static func makeary(_ a: [JSValue]) -> JSValue { return array(a) }

    var description: String {
        switch self {
        case let .string(s): return s
        case let .number(n): return "\(n)"
        case let .object(obj): return "\(obj)"
        case let .bool(b): return "\(b)"
        case let .array(a): return "\(a)"
        case .null: return "null"
        }
    }
}

struct JSParser: Parser {
    static let skip = regex("\\s*")
    static let dquote = const("\"")
    static let ocurly = const("{") ~> skip
    static let ccurly = const("}") ~> skip
    static let obrack = const("[") ~> skip
    static let cbrack = const("]") ~> skip
    static let comma = const(",") ~> skip
    static let colon = const(":") ~> skip

    static let string = dquote >~ regex("[^\"]*") ~> dquote ~> skip
    static let stringval = string |> JSValue.make
    static let number = FloatParser(strict: false) |> JSValue.make
    static let object = LateBound<JSObject>()
    static let objval = object |> JSValue.make
    static let array = LateBound<JSValue>()
    static let bool = (const(true) | const(false)) |> JSValue.make
    static let null = token(const("null"), value: JSValue.null)
    static let value = (null | objval | array | bool | stringval | number) ~> skip

    static let pair = string ~>~ (colon >~ value)
    static let objimpl = ocurly >~ sepby(pair, comma) ~> ccurly |> makeObj
    static let arrayimpl = obrack >~ sepby(value, comma) ~> cbrack |> JSValue.makeary

    static func parse(_ str: String) -> JSObject? {
        let stream = CharStream(str: str)
        return parse(stream)
    }

    static func parse(_ stream: CharStream) -> JSObject? {
        object.inner = objimpl.parse
        array.inner = arrayimpl.parse
        return object.parse(stream)
    }

    // Parse implementation
    typealias Target = JSObject
    func parse(_ stream: CharStream) -> Target? {
        return JSParser.parse(stream)
    }
}
