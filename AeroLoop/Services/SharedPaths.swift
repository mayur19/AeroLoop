import Foundation

/// Centralized path manager for AeroLoop shared data.
///
/// All file I/O that must be shared between the main app and the screen saver
/// goes through the App Group container, which is accessible under sandbox.
enum SharedPaths {

    /// The App Group identifier shared between the main app and the screen saver.
    static let appGroupIdentifier = "group.com.greekerlabs.aeroloop"

    /// Root URL of the shared App Group container.
    /// Falls back to `/Users/Shared/AeroLoop` only if the container is unavailable
    /// (should not happen once entitlements are configured).
    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url
        }
        // Fallback for development without proper provisioning
        return URL(fileURLWithPath: "/Users/Shared/AeroLoop", isDirectory: true)
    }

    /// Directory for imported video files shared with the screen saver.
    static var libraryURL: URL {
        containerURL.appendingPathComponent("Library", isDirectory: true)
    }

    /// Directory for cached thumbnail images.
    static var thumbnailsURL: URL {
        containerURL.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    /// Path to the active playlist JSON used by the screen saver.
    static var activePlaylistURL: URL {
        containerURL.appendingPathComponent("active_playlist.json")
    }

    /// Path to the single-wallpaper settings JSON used by the screen saver.
    static var settingsURL: URL {
        containerURL.appendingPathComponent("settings.json")
    }

    /// Shared UserDefaults suite for cross-process settings.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }

    /// Ensures a directory exists, creating it if necessary.
    static func ensureDirectoryExists(at url: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Returns the destination URL for a wallpaper file in the shared Library directory.
    static func wallpaperDestination(for sourceURL: URL, displayID: UInt32? = nil) -> URL {
        let ext = sourceURL.pathExtension
        let suffix = displayID != nil ? "_\(displayID!)" : ""
        return containerURL.appendingPathComponent("ActiveWallpaper\(suffix).\(ext.isEmpty ? "mp4" : ext)")
    }
}
