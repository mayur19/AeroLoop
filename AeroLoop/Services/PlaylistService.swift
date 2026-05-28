import Foundation
import GRDB

@MainActor
class PlaylistService: ObservableObject {
    @Published var playlists: [PlaylistWithItems] = []

    private let dbManager = DatabaseManager.shared

    init() {
        Task {
            await fetchAll()
        }
    }

    func fetchAll() async {
        do {
            let fetchedPlaylists = try await dbManager.dbPool.read { db in
                let request = Playlist.including(all: Playlist.items)
                return try PlaylistWithItems.fetchAll(db, request)
            }
            self.playlists = fetchedPlaylists
        } catch {
            print("[PlaylistService] Failed to fetch playlists: \(error)")
        }
    }

    func createPlaylist(title: String, rotationInterval: TimeInterval = 300, shuffle: Bool = false) async -> Playlist {
        let playlist = Playlist(title: title, rotationInterval: rotationInterval, shuffle: shuffle)
        do {
            try await dbManager.dbPool.write { db in
                var p = playlist
                try p.insert(db)
            }
            await fetchAll()
        } catch {
            print("[PlaylistService] Failed to create playlist: \(error)")
        }
        return playlist
    }

    func deletePlaylist(_ playlist: Playlist) async {
        do {
            try await dbManager.dbPool.write { db in
                try playlist.delete(db)
            }
            await fetchAll()
        } catch {
            print("[PlaylistService] Failed to delete playlist: \(error)")
        }
    }

    func updatePlaylist(_ playlist: Playlist) async {
        do {
            try await dbManager.dbPool.write { db in
                var p = playlist
                try p.update(db)
            }
            await fetchAll()
        } catch {
            print("[PlaylistService] Failed to update playlist: \(error)")
        }
    }

    func addWallpaper(_ wallpaper: WallpaperItem, to playlist: Playlist) async {
        do {
            try await dbManager.dbPool.write { db in
                // Find current max position
                let maxPos = try PlaylistMembership.filter(PlaylistMembership.Columns.playlistId == playlist.id.uuidString)
                    .select(max(PlaylistMembership.Columns.position))
                    .fetchOne(db) as Int? ?? -1

                var membership = PlaylistMembership(
                    playlistId: playlist.id,
                    wallpaperId: wallpaper.id,
                    position: maxPos + 1
                )
                try membership.insert(db)
            }
            await fetchAll()
        } catch {
            print("[PlaylistService] Failed to add wallpaper to playlist: \(error)")
        }
    }

    func removeWallpaper(_ wallpaper: WallpaperItem, from playlist: Playlist) async {
        do {
            try await dbManager.dbPool.write { db in
                try PlaylistMembership.filter(
                    PlaylistMembership.Columns.playlistId == playlist.id.uuidString &&
                    PlaylistMembership.Columns.wallpaperId == wallpaper.id.uuidString
                ).deleteAll(db)
            }
            await fetchAll()
        } catch {
            print("[PlaylistService] Failed to remove wallpaper from playlist: \(error)")
        }
    }
}
