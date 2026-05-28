import AVFoundation
import XCTest
@testable import AeroLoop

final class DisplayModeTests: XCTestCase {

    func testAllCasesPresent() {
        XCTAssertEqual(DisplayMode.allCases, [.fill, .fit, .stretch])
    }

    func testIdentifierMatchesRawValue() {
        for mode in DisplayMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    func testRawValues() {
        XCTAssertEqual(DisplayMode.fill.rawValue, "fill")
        XCTAssertEqual(DisplayMode.fit.rawValue, "fit")
        XCTAssertEqual(DisplayMode.stretch.rawValue, "stretch")
    }

    func testVideoGravityMapping() {
        XCTAssertEqual(DisplayMode.fill.avLayerVideoGravity, .resizeAspectFill)
        XCTAssertEqual(DisplayMode.fit.avLayerVideoGravity, .resizeAspect)
        XCTAssertEqual(DisplayMode.stretch.avLayerVideoGravity, .resize)
    }

    func testPresentationStringsAreNonEmpty() {
        for mode in DisplayMode.allCases {
            XCTAssertFalse(mode.label.isEmpty)
            XCTAssertFalse(mode.description.isEmpty)
            XCTAssertFalse(mode.systemImage.isEmpty)
        }
    }

    func testCodableRoundTrip() throws {
        for mode in DisplayMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(DisplayMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
}
