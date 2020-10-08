/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE for this sample’s licensing information

 Abstract:
 The file shows how to make an OperationCondition that composes another OperationCondition.

 This file was modified from the original.
 */

import Foundation

/**
 A simple condition that causes another condition to not enqueue its dependency.
 This is useful (for example) when you want to verify that you have access to
 the user's location, but you do not want to prompt them for permission if you
 do not already have it.
 */
public
struct SilentCondition<T: OperationCondition>: OperationCondition {
    let condition: T

    public static var name: String {
        return "Silent<\(T.name)>"
    }

    public static var isMutuallyExclusive: Bool {
        return T.isMutuallyExclusive
    }

    public init(condition: T) {
        self.condition = condition
    }

    public func dependencyForOperation(_: Operation) -> Foundation.Operation? {
        // Returning nil means we will never a dependency to be generated.
        return nil
    }

    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        condition.evaluateForOperation(operation, completion: completion)
    }
}