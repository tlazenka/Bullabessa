struct ReferenceError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

struct TypeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

protocol Func {
    func apply(_ evaluationResult: [EvaluationResult]) throws -> EvaluationResult
}

struct Function: Func {
    let argNames: [String]
    let body: Expression
    let scope: Scope

    func apply(_ evaluationResult: [EvaluationResult]) throws -> EvaluationResult {
        if evaluationResult.count != argNames.count {
            throw TypeError("Wrong number of arguments")
        }

        var localScope = scope

        for (i, arg) in evaluationResult.enumerated() {
            localScope[argNames[i]] = arg
        }

        return try evaluate(expr: body, scope: &localScope)
    }
}

enum EvaluationResult {
    case string(String)
    case number(Int)
    case bool(Bool)
    case array
    case function(Func)
}

func evaluate(expr: Expression, scope: inout Scope) throws -> EvaluationResult {
    switch expr {
    case let .numberValue(number):
        return .number(number)
    case let .stringValue(string):
        return .string(string)

    case let .word(name):
        guard let result = scope[name] else {
            throw ReferenceError("Undefined binding: \(name)")
        }
        return result
    case let .apply(`operator`, args):
        switch `operator` {
        case let .word(name):
            if let r = specialForms[name] {
                return try r(args, &scope)
            }
        default:
            break
        }
        let op = try evaluate(expr: `operator`, scope: &scope)

        guard case let .function(function) = op else {
            throw TypeError("Applying a non-function.")
        }

        let arg = try args.map { arg in try evaluate(expr: arg, scope: &scope) }
        for a in arg {
            switch a {
            case .array, .number, .string, .bool:
                continue
            case .function:
                throw TypeError("Unexpected function argument")
            }
        }

        return try function.apply(arg)
    }
}

typealias Scope = [String: EvaluationResult]
typealias Args = [Expression]

let specialForms: [String: (Args, inout Scope) throws -> EvaluationResult] = {
    var result = [String: (Args, inout Scope) throws -> EvaluationResult]()
    result["do"] = {
        args, scope in
        var localScope = scope
        var value: EvaluationResult = .bool(false)
        for arg in args {
            value = try evaluate(expr: arg, scope: &localScope)
        }
        return value
    }

    result["define"] = {
        args, scope in

        guard args.count == 2, case let .word(name) = args.first else {
            throw SyntaxError("Incorrect use of define")
        }

        let value = try evaluate(expr: args[1], scope: &scope)
        scope[name] = value

        return value
    }

    result["fun"] = {
        args, scope in

        guard !args.isEmpty else {
            throw SyntaxError("Functions need a body")
        }

        var argNames = [String]()

        for arg in args.prefix(args.count - 1) {
            guard case let .word(name) = arg else {
                throw SyntaxError("Parameter names must be words")
            }
            argNames.append(name)
        }

        guard let body = args.last, case .apply = body else {
            throw SyntaxError("Functions need a body")
        }

        let function = Function(argNames: argNames, body: body, scope: scope)

        return EvaluationResult.function(function)
    }

    return result
}()
