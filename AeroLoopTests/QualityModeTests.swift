import XCTest
@testable import AeroLoop

final class QualityModeTests: XCTestCase {

    func testAllCasesPresent() {
        XCTAssertEqual(QualityMode.allCases, [.eco, .balanced, .high])
    }

    func testIdentifierMatchesRawValue() {
        for mode in QualityMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    func testTargetFPS() {
        XCTAssertEqual(QualityMode.eco.targetFPS, 15)
        XCTAssertEqual(QualityMode.balanced.targetFPS, 30)
        XCTAssertEqual(QualityMode.high.targetFPS, 60)
    }

    func testTargetFPSIncreasesWithQuality() {
        XCTAssertLessThan(QualityMode.eco.targetFPS, QualityMode.balanced.targetFPS)
        XCTAssertLessThan(QualityMode.balanced.targetFPS, QualityMode.high.targetFPS)
    }

    func testPresentationStringsAreNonEmpty() {
        for mode in QualityMode.allCases {
            XCTAssertFalse(mode.label.isEmpty)
            XCTAssertFalse(mode.description.isEmpty)
            XCTAssertFalse(mode.systemImage.isEmpty)
        }
    }

    func testCodableRoundTrip() throws {
        for mode in QualityMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(QualityMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
}
