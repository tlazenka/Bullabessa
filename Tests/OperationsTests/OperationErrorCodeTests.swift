//
//  Created by Matt McMurry on 10/1/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

import XCTest
@testable import Operations

class OperationErrorCodeTests: XCTestCase {
    func testOperationErrorCodeEqualityLHS() {
        let opErrorCode = OperationErrorCode.conditionFailed

        XCTAssertTrue(opErrorCode == 1)
    }

    func testOperationErrorCodeEqualityLHS_wrong() {
        let opErrorCode = OperationErrorCode.conditionFailed

        XCTAssertFalse(opErrorCode == 2)
    }

    func testOperationErrorCodeEqualityRHS() {
        let opErrorCode = OperationErrorCode.executionFailed

        XCTAssertTrue(opErrorCode == 2)
    }

    func testOperationErrorCodeEqualityRHS_wrong() {
        let opErrorCode = OperationErrorCode.executionFailed

        XCTAssertFalse(opErrorCode == 1)
    }
}
