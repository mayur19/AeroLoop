import Foundation

/// Manages security-scoped bookmarks for user-selected video files.
///
/// Under App Sandbox, the app loses access to user-selected files after restart.
/// Security-scoped bookmarks persist this access across launches.
enum BookmarkManager {

    // MARK: - Bookmark Creation

    /// Creates a security-scoped bookmark from a URL obtained via file picker.
    static func createBookmark(for url: URL) -> Data? {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmarkData
        } catch {
            print("[BookmarkManager] Failed to create bookmark for \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Bookmark Resolution

    /// Resolves a security-scoped bookmark back to a URL and starts accessing it.
    /// Returns the resolved URL, or `nil` if the bookmark is stale or invalid.
    @discardableResult
    static func resolveBookmark(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                print("[BookmarkManager] Bookmark is stale for \(url.lastPathComponent), re-creating.")
                // Attempt to re-create the bookmark if we still have access
                if url.startAccessingSecurityScopedResource() {
                    // The caller is responsible for stopping access when done
                    return url
                }
                return nil
            }

            if url.startAccessingSecurityScopedResource() {
                return url
            }

            return nil
        } catch {
            print("[BookmarkManager] Failed to resolve bookmark: \(error.localizedDescription)")
            return nil
        }
    }

    /// Stops accessing a security-scoped resource.
    static func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
