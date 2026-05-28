import Foundation
import XCTest
@testable import AeroLoop

final class PlaylistTests: XCTestCase {

    func testPlaylistInitDefaults() {
        let playlist = Playlist(title: "Nature")
        XCTAssertEqual(playlist.title, "Nature")
        XCTAssertEqual(playlist.rotationInterval, 300)
        XCTAssertFalse(playlist.shuffle)
    }

    func testPlaylistInitCustomValues() {
        let playlist = Playlist(title: "Focus", rotationInterval: 600, shuffle: true)
        XCTAssertEqual(playlist.rotationInterval, 600)
        XCTAssertTrue(playlist.shuffle)
    }

    func testPlaylistCodableRoundTrip() throws {
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let original = Playlist(id: id, title: "Ocean", rotationInterval: 120, shuffle: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Playlist.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.id, id)
    }

    func testMembershipCodableRoundTrip() throws {
        let original = PlaylistMembership(
            playlistId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            wallpaperId: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            position: 4
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PlaylistMembership.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.position, 4)
    }

    func testPlaylistEquatable() {
        let id = UUID()
        let a = Playlist(id: id, title: "A")
        let b = Playlist(id: id, title: "A")
        XCTAssertEqual(a, b)
    }
}
