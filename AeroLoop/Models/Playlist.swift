import Foundation
import GRDB

/// Represents a collection of wallpapers that can be played in sequence or shuffled.
struct Playlist: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var rotationInterval: TimeInterval // e.g. 300 for 5 minutes
    var shuffle: Bool
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        title: String,
        rotationInterval: TimeInterval = 300,
        shuffle: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rotationInterval = rotationInterval
        self.shuffle = shuffle
        self.dateCreated = dateCreated
    }
}

extension Playlist: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column("id")
        static let title = Column("title")
        static let rotationInterval = Column("rotationInterval")
        static let shuffle = Column("shuffle")
        static let dateCreated = Column("dateCreated")
    }

    init(row: Row) throws {
        let idString: String = row[Columns.id]
        id = UUID(uuidString: idString) ?? UUID()
        title = row[Columns.title]
        rotationInterval = row[Columns.rotationInterval]
        shuffle = row[Columns.shuffle]
        dateCreated = row[Columns.dateCreated]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.title] = title
        container[Columns.rotationInterval] = rotationInterval
        container[Columns.shuffle] = shuffle
        container[Columns.dateCreated] = dateCreated
    }
}

/// Represents the many-to-many relationship mapping a wallpaper to a playlist.
struct PlaylistMembership: Codable, Equatable, Hashable {
    let playlistId: UUID
    let wallpaperId: UUID
    var position: Int
}

extension PlaylistMembership: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let playlistId = Column("playlistId")
        static let wallpaperId = Column("wallpaperId")
        static let position = Column("position")
    }

    init(row: Row) throws {
        let pIdString: String = row[Columns.playlistId]
        let wIdString: String = row[Columns.wallpaperId]
        playlistId = UUID(uuidString: pIdString) ?? UUID()
        wallpaperId = UUID(uuidString: wIdString) ?? UUID()
        position = row[Columns.position]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.playlistId] = playlistId.uuidString
        container[Columns.wallpaperId] = wallpaperId.uuidString
        container[Columns.position] = position
    }
}

// MARK: - GRDB Associations

extension Playlist {
    static let memberships = hasMany(PlaylistMembership.self)
    static let items = hasMany(WallpaperItem.self, through: memberships, using: PlaylistMembership.wallpaper).forKey("items")
}

extension PlaylistMembership {
    static let playlist = belongsTo(Playlist.self)
    static let wallpaper = belongsTo(WallpaperItem.self)
}

struct PlaylistWithItems: FetchableRecord, Codable, Equatable {
    var playlist: Playlist
    var items: [WallpaperItem]
}
