import Foundation
import GRDB

extension WallpaperItem: FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column("id")
        static let url = Column("url")
        static let title = Column("title")
        static let duration = Column("duration")
        static let resolutionWidth = Column("resolutionWidth")
        static let resolutionHeight = Column("resolutionHeight")
        static let fileSize = Column("fileSize")
        static let displayMode = Column("displayMode")
        static let isFavorite = Column("isFavorite")
        static let dateAdded = Column("dateAdded")
        static let bookmarkData = Column("bookmarkData")
    }
    
    init(row: Row) throws {
        let idString: String = row[Columns.id]
        id = UUID(uuidString: idString) ?? UUID()
        let urlString: String = row[Columns.url]
        url = URL(fileURLWithPath: urlString)
        title = row[Columns.title]
        duration = row[Columns.duration]
        let w: Double = row[Columns.resolutionWidth]
        let h: Double = row[Columns.resolutionHeight]
        resolution = CGSize(width: w, height: h)
        fileSize = row[Columns.fileSize]
        let modeStr: String = row[Columns.displayMode]
        displayMode = DisplayMode(rawValue: modeStr) ?? .fill
        isFavorite = row[Columns.isFavorite]
        dateAdded = row[Columns.dateAdded]
        bookmarkData = row[Columns.bookmarkData]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.url] = url.path
        container[Columns.title] = title
        container[Columns.duration] = duration
        container[Columns.resolutionWidth] = Double(resolution.width)
        container[Columns.resolutionHeight] = Double(resolution.height)
        container[Columns.fileSize] = fileSize
        container[Columns.displayMode] = displayMode.rawValue
        container[Columns.isFavorite] = isFavorite
        container[Columns.dateAdded] = dateAdded
        container[Columns.bookmarkData] = bookmarkData
    }
}

/// Service for managing the wallpaper library database.
@MainActor
class WallpaperLibraryService: ObservableObject {
    @Published var items: [WallpaperItem] = []
    
    private let dbManager = DatabaseManager.shared
    
    init() {
        Task {
            await fetchAll()
        }
    }
    
    func fetchAll() async {
        do {
            let fetchedItems = try await dbManager.dbPool.read { db in
                try WallpaperItem.order(WallpaperItem.Columns.dateAdded.desc).fetchAll(db)
            }
            self.items = fetchedItems
        } catch {
            print("[LibraryService] Failed to fetch items: \(error)")
        }
    }
    
    func add(_ item: WallpaperItem) async {
        do {
            try await dbManager.dbPool.write { db in
                var itemToSave = item
                try itemToSave.insert(db)
            }
            await fetchAll()
        } catch {
            print("[LibraryService] Failed to add item: \(error)")
        }
    }
    
    func update(_ item: WallpaperItem) async {
        do {
            try await dbManager.dbPool.write { db in
                var itemToSave = item
                try itemToSave.update(db)
            }
            await fetchAll()
        } catch {
            print("[LibraryService] Failed to update item: \(error)")
        }
    }
    
    func delete(_ item: WallpaperItem) async {
        do {
            try await dbManager.dbPool.write { db in
                try item.delete(db)
            }
            await fetchAll()
        } catch {
            print("[LibraryService] Failed to delete item: \(error)")
        }
    }
}
