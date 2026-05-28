import Foundation
import GRDB

/// Manages the local SQLite database for the wallpaper library.
final class DatabaseManager {
    static let shared = DatabaseManager()

    var dbPool: DatabasePool!

    private init() {
        do {
            try setupDatabase()
        } catch {
            print("[DatabaseManager] Initialization failed: \(error)")
        }
    }

    private func setupDatabase() throws {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let aeroLoopDir = appSupportURL.appendingPathComponent("AeroLoop", isDirectory: true)

        if !FileManager.default.fileExists(atPath: aeroLoopDir.path) {
            try FileManager.default.createDirectory(at: aeroLoopDir, withIntermediateDirectories: true)
        }

        let dbURL = aeroLoopDir.appendingPathComponent("library.sqlite")
        
        var config = Configuration()
        #if DEBUG
        config.prepareDatabase { db in
            db.trace { print("[GRDB] \($0)") }
        }
        #endif
        
        dbPool = try DatabasePool(path: dbURL.path, configuration: config)

        try migrator.migrate(dbPool)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "wallpaperItem") { t in
                t.column("id", .text).primaryKey()
                t.column("url", .text).notNull()
                t.column("title", .text).notNull()
                t.column("duration", .double).notNull()
                t.column("resolutionWidth", .double).notNull()
                t.column("resolutionHeight", .double).notNull()
                t.column("fileSize", .integer).notNull()
                t.column("displayMode", .text).notNull()
                t.column("isFavorite", .boolean).notNull().defaults(to: false)
                t.column("dateAdded", .datetime).notNull()
            }
        }
        
        migrator.registerMigration("v2") { db in
            try db.create(table: "playlist") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("rotationInterval", .double).notNull()
                t.column("shuffle", .boolean).notNull().defaults(to: false)
                t.column("dateCreated", .datetime).notNull()
            }
            
            try db.create(table: "playlistMembership") { t in
                t.column("playlistId", .text).notNull().references("playlist", onDelete: .cascade)
                t.column("wallpaperId", .text).notNull().references("wallpaperItem", onDelete: .cascade)
                t.column("position", .integer).notNull()
                t.primaryKey(["playlistId", "wallpaperId"])
            }
        }

        migrator.registerMigration("v3") { db in
            try db.alter(table: "wallpaperItem") { t in
                t.add(column: "bookmarkData", .blob)
            }
        }

        return migrator
    }
}
