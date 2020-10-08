/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE for this sample’s licensing information

 Abstract:
 An extension to NSLock to simplify executing critical code.

 This file was modified from the original.
 */

import Foundation

extension NSLock {
    func withCriticalScope<T>(_ block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension NSRecursiveLock {
    func withCriticalScope<T>(_ block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
