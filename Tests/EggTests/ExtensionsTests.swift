import XCTest
@testable import Egg

final class ExtensionsTests: XCTestCase {
    func testExtensions() throws {
        let string = "a"

        XCTAssertEqual(string.substring(startOffset: 1), "")
        XCTAssertEqual(string.substring(startOffset: 0), "a")
    }
}
