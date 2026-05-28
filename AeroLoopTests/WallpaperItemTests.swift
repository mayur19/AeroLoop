import CoreGraphics
import Foundation
import XCTest
@testable import AeroLoop

final class WallpaperItemTests: XCTestCase {

    private func makeItem(
        title: String? = nil,
        duration: TimeInterval = 0,
        resolution: CGSize = .zero,
        fileSize: Int64 = 0
    ) -> WallpaperItem {
        WallpaperItem(
            url: URL(fileURLWithPath: "/tmp/sample-clip.mov"),
            title: title,
            duration: duration,
            resolution: resolution,
            fileSize: fileSize
        )
    }

    func testDefaultTitleDerivedFromFilename() {
        let item = makeItem()
        XCTAssertEqual(item.title, "sample-clip")
    }

    func testExplicitTitleIsPreserved() {
        let item = makeItem(title: "My Wallpaper")
        XCTAssertEqual(item.title, "My Wallpaper")
    }

    func testResolutionFormatted() {
        let item = makeItem(resolution: CGSize(width: 3840, height: 2160))
        XCTAssertEqual(item.resolutionFormatted, "3840×2160")
    }

    func testDurationFormattedUnderOneHour() {
        // Positional style with .pad zero-formatting pads the leading unit too.
        let item = makeItem(duration: 90)
        XCTAssertEqual(item.durationFormatted, "01:30")
    }

    func testDurationFormattedOverOneHourIncludesHours() {
        let item = makeItem(duration: 3661) // 1h 1m 1s
        XCTAssertEqual(item.durationFormatted, "01:01:01")
    }

    func testMetadataLabelCombinesResolutionAndDuration() {
        let item = makeItem(duration: 90, resolution: CGSize(width: 1920, height: 1080))
        XCTAssertEqual(item.metadataLabel, "1920×1080 · 01:30")
    }

    func testFileSizeFormattedIsNonEmpty() {
        let item = makeItem(fileSize: 12_400_000)
        XCTAssertFalse(item.fileSizeFormatted.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let original = WallpaperItem(
            url: URL(fileURLWithPath: "/tmp/clip.mp4"),
            title: "Clip",
            duration: 42,
            resolution: CGSize(width: 1280, height: 720),
            fileSize: 2048,
            displayMode: .fit,
            isFavorite: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WallpaperItem.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testEqualityDistinguishesByIdentity() {
        let a = makeItem(title: "Same")
        let b = makeItem(title: "Same")
        XCTAssertNotEqual(a, b, "Items with distinct UUIDs should not be equal")
        XCTAssertEqual(a, a)
    }

    func testHashableUsableInSet() {
        let a = makeItem(title: "A")
        let b = makeItem(title: "B")
        let set: Set<WallpaperItem> = [a, b, a]
        XCTAssertEqual(set.count, 2)
    }
}
