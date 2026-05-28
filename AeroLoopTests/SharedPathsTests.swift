import Foundation
import XCTest
@testable import AeroLoop

final class SharedPathsTests: XCTestCase {

    func testAppGroupIdentifier() {
        XCTAssertEqual(SharedPaths.appGroupIdentifier, "group.com.greekerlabs.aeroloop")
    }

    func testWallpaperDestinationWithoutDisplayID() {
        let source = URL(fileURLWithPath: "/tmp/cool.mov")
        let dest = SharedPaths.wallpaperDestination(for: source)
        XCTAssertEqual(dest.lastPathComponent, "ActiveWallpaper.mov")
    }

    func testWallpaperDestinationWithDisplayID() {
        let source = URL(fileURLWithPath: "/tmp/cool.mp4")
        let dest = SharedPaths.wallpaperDestination(for: source, displayID: 3)
        XCTAssertEqual(dest.lastPathComponent, "ActiveWallpaper_3.mp4")
    }

    func testWallpaperDestinationFallsBackToMP4WhenNoExtension() {
        let source = URL(fileURLWithPath: "/tmp/cool")
        let dest = SharedPaths.wallpaperDestination(for: source)
        XCTAssertEqual(dest.lastPathComponent, "ActiveWallpaper.mp4")
    }

    func testWallpaperDestinationLivesInContainer() {
        let source = URL(fileURLWithPath: "/tmp/cool.mov")
        let dest = SharedPaths.wallpaperDestination(for: source)
        XCTAssertEqual(dest.deletingLastPathComponent().path, SharedPaths.containerURL.path)
    }

    func testNamedDirectories() {
        XCTAssertEqual(SharedPaths.libraryURL.lastPathComponent, "Library")
        XCTAssertEqual(SharedPaths.thumbnailsURL.lastPathComponent, "Thumbnails")
    }

    func testNamedFiles() {
        XCTAssertEqual(SharedPaths.activePlaylistURL.lastPathComponent, "active_playlist.json")
        XCTAssertEqual(SharedPaths.settingsURL.lastPathComponent, "settings.json")
    }

    func testSubpathsShareContainerRoot() {
        let root = SharedPaths.containerURL.path
        XCTAssertEqual(SharedPaths.libraryURL.deletingLastPathComponent().path, root)
        XCTAssertEqual(SharedPaths.thumbnailsURL.deletingLastPathComponent().path, root)
    }
}
