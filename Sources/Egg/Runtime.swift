let topScope: Scope = {
    var result = Scope()
    result["print"] = .function(Print())
    result["+"] = .function(Add())
    return result
}()

struct Print: Func {
    func apply(_ evaluationResult: [EvaluationResult]) throws -> EvaluationResult {
        print(evaluationResult)
        return evaluationResult.first!
    }
}

struct Add: Func {
    func apply(_ evaluationResult: [EvaluationResult]) throws -> EvaluationResult {
        let numbers: [Int] = try evaluationResult.map {
            guard case let .number(number) = $0 else {
                throw ReferenceError("Add function requires numbers")
            }
            return number
        }

        return .number(numbers.reduce(0) { $0 + $1 })
    }
}
