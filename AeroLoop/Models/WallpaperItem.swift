import CoreGraphics
import Foundation

/// Represents a video wallpaper in the user's library.
struct WallpaperItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var url: URL
    var title: String
    var duration: TimeInterval
    var resolution: CGSize
    var fileSize: Int64
    var displayMode: DisplayMode
    var isFavorite: Bool
    var dateAdded: Date
    var bookmarkData: Data?

    init(
        id: UUID = UUID(),
        url: URL,
        title: String? = nil,
        duration: TimeInterval = 0,
        resolution: CGSize = .zero,
        fileSize: Int64 = 0,
        displayMode: DisplayMode = .fill,
        isFavorite: Bool = false,
        dateAdded: Date = Date(),
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
        self.duration = duration
        self.resolution = resolution
        self.fileSize = fileSize
        self.displayMode = displayMode
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.bookmarkData = bookmarkData
    }

    // MARK: - Formatted Accessors

    /// Human-readable file size (e.g., "12.4 MB").
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// Human-readable duration (e.g., "1:30" or "1:02:15").
    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    /// Resolution as a readable string (e.g., "3840×2160").
    var resolutionFormatted: String {
        "\(Int(resolution.width))×\(Int(resolution.height))"
    }

    /// Whether the video file still exists at the stored URL.
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// Convenience label combining resolution and duration.
    var metadataLabel: String {
        "\(resolutionFormatted) · \(durationFormatted)"
    }
}
