/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE for this sample’s licensing information

 Abstract:
 This file shows how to implement the OperationObserver protocol.

 This file was modified from the original.
 */

import Foundation

/**
 `TimeoutObserver` is a way to make an `Operation` automatically time out and
 cancel after a specified time interval.
 */
public class TimeoutObserver: OperationObserver {
    // MARK: Properties

    static let timeoutKey = "Timeout"

    fileprivate let timeout: TimeInterval

    // MARK: Initialization

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    // MARK: OperationObserver

    public func operationDidStart(_ operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = DispatchTime.now() + timeout

        DispatchQueue.global(qos: operation.qualityOfService).asyncAfter(deadline: when) {
            /*
                 Cancel the operation if it hasn't finished and hasn't already
                 been cancelled.
             */
            if !operation.isFinished, !operation.isCancelled {
                let error = NSError(code: .executionFailed, userInfo: [
                    type(of: self).timeoutKey: self.timeout,
                ])

                operation.cancelWithError(error)
            }
        }
    }

    public func operationDidCancel(_: Operation) {
        // No op.
    }

    public func operation(_: Operation, didProduceOperation _: Foundation.Operation) {
        // No op.
    }

    public func operationDidFinish(_: Operation, errors _: [NSError]) {
        // No op.
    }
}
