import Foundation

/// Pure, side-effect-free resolution of which playlist should be active for a
/// given set of conditions.
///
/// Extracted from `ScheduleManager` so the precedence rules can be unit-tested
/// without touching `NSApp`, GRDB, or any singletons. `ScheduleManager` owns the
/// impure parts (observing battery/appearance changes and applying the result).
enum ScheduleDecision {

    /// Resolves the target playlist ID using fixed precedence:
    /// `battery` > `night` (dark mode) > `day` (light mode).
    ///
    /// A candidate is only chosen when its configured ID string is present and
    /// parses as a valid `UUID`; otherwise the next rule is considered. Returns
    /// `nil` when no rule produces a usable playlist.
    static func resolvedPlaylistID(
        isOnBattery: Bool,
        isDarkMode: Bool,
        batteryPlaylistId: String?,
        nightPlaylistId: String?,
        dayPlaylistId: String?
    ) -> UUID? {
        if isOnBattery, let id = uuid(from: batteryPlaylistId) {
            return id
        }
        if isDarkMode, let id = uuid(from: nightPlaylistId) {
            return id
        }
        if !isDarkMode, let id = uuid(from: dayPlaylistId) {
            return id
        }
        return nil
    }

    private static func uuid(from string: String?) -> UUID? {
        guard let string else { return nil }
        return UUID(uuidString: string)
    }
}
