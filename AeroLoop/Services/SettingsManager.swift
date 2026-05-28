import Foundation
import ServiceManagement
import SwiftUI

/// Manages persistent user settings via @AppStorage (UserDefaults-backed).
class SettingsManager: ObservableObject {

    // MARK: - Shared Defaults

    // Use App Group shared UserDefaults so both the main app and the
    // sandboxed screen saver can read the same settings.
    static let sharedDefaults: UserDefaults = SharedPaths.sharedDefaults

    // MARK: - Stored Settings

    @AppStorage("aeroloop.launchAtLogin", store: sharedDefaults) var launchAtLogin: Bool = false
    @AppStorage("aeroloop.showInDock", store: sharedDefaults) var showInDock: Bool = false
    @AppStorage("aeroloop.pauseOnBattery", store: sharedDefaults) var pauseOnBattery: Bool = true
    @AppStorage("aeroloop.pauseInFullscreen", store: sharedDefaults) var pauseInFullscreen: Bool = true
    @AppStorage("aeroloop.qualityModeRaw", store: sharedDefaults) var qualityModeRaw: String = QualityMode.balanced.rawValue
    @AppStorage("aeroloop.displayModeRaw", store: sharedDefaults) var displayModeRaw: String = DisplayMode.fill.rawValue
    @AppStorage("aeroloop.audioMuted", store: sharedDefaults) var audioMuted: Bool = true
    @AppStorage("aeroloop.hasCompletedOnboarding", store: sharedDefaults) var hasCompletedOnboarding: Bool = false
    @AppStorage("aeroloop.syncAllDisplays", store: sharedDefaults) var syncAllDisplays: Bool = true
    @AppStorage("aeroloop.lastWallpaperData", store: sharedDefaults) var lastWallpaperData: Data = Data()

    // Smart Schedules
    @AppStorage("aeroloop.dayPlaylistId", store: sharedDefaults) var dayPlaylistId: String?
    @AppStorage("aeroloop.nightPlaylistId", store: sharedDefaults) var nightPlaylistId: String?
    @AppStorage("aeroloop.batteryPlaylistId", store: sharedDefaults) var batteryPlaylistId: String?

    // UI Overlays
    @AppStorage("aeroloop.showClockOverlay", store: sharedDefaults) var showClockOverlay: Bool = false

    // MARK: - Computed Properties

    /// The current quality mode, derived from the stored raw value.
    var qualityMode: QualityMode {
        get { QualityMode(rawValue: qualityModeRaw) ?? .balanced }
        set { qualityModeRaw = newValue.rawValue }
    }

    /// The current display mode, derived from the stored raw value.
    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .fill }
        set { displayModeRaw = newValue.rawValue }
    }

    /// The last-applied wallpapers, decoded from stored JSON data. Maps displayID (as String) to WallpaperItem.
    var lastWallpapers: [String: WallpaperItem] {
        get {
            guard !lastWallpaperData.isEmpty else { return [:] }
            return (try? JSONDecoder().decode([String: WallpaperItem].self, from: lastWallpaperData)) ?? [:]
        }
        set {
            lastWallpaperData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // For backwards compatibility and the primary display, we can expose a current/last item
    var lastWallpaper: WallpaperItem? {
        lastWallpapers.values.first
    }

    // MARK: - Launch at Login

    /// Registers or unregisters the app for launch-at-login using SMAppService.
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
        } catch {
            print("[SettingsManager] Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }

    // MARK: - Wallpaper Persistence

    /// Encodes and stores the given wallpaper item for session restoration.
    /// Also copies the video into the App Group container and writes a settings.json file
    /// so the heavily sandboxed macOS Screen Saver process can reliably read it.
    func saveLastWallpaper(_ item: WallpaperItem, for displayID: CGDirectDisplayID? = nil) {
        var itemToSave = item

        let fm = FileManager.default
        let containerURL = SharedPaths.containerURL

        do {
            try SharedPaths.ensureDirectoryExists(at: containerURL)

            let destURL = SharedPaths.wallpaperDestination(for: item.url, displayID: displayID)

            if fm.fileExists(atPath: destURL.path) && destURL != item.url {
                try fm.removeItem(at: destURL)
            }

            // Copy the file to the shared directory if it's not already there
            if destURL != item.url {
                try fm.copyItem(at: item.url, to: destURL)
            }

            // Update the URL to point to the shared file so the Screen Saver can read it
            itemToSave.url = destURL

            // Write the JSON representation so the Screen Saver can read it directly
            let jsonData = try JSONEncoder().encode(itemToSave)
            try jsonData.write(to: SharedPaths.settingsURL, options: .atomic)

        } catch {
            print("[SettingsManager] Failed to copy wallpaper to App Group container: \(error.localizedDescription)")
        }

        var currentWallpapers = lastWallpapers
        if let displayID = displayID, !syncAllDisplays {
            currentWallpapers[String(displayID)] = itemToSave
        } else {
            // If syncing all displays, or no specific display provided, apply to all currently known
            currentWallpapers.removeAll()
            currentWallpapers["primary"] = itemToSave
        }
        lastWallpapers = currentWallpapers
    }

    @AppStorage("aeroloop.activePlaylistId", store: sharedDefaults) var activePlaylistId: String?
    @AppStorage("aeroloop.activePlaylistShuffle", store: sharedDefaults) var activePlaylistShuffle: Bool = false

    /// Clears the stored last-wallpaper data.
    func clearLastWallpaper() {
        lastWallpaperData = Data()
    }

    // MARK: - Playlist Persistence

    func saveActivePlaylist(id: String) {
        activePlaylistId = id
    }

    func clearActivePlaylist() {
        activePlaylistId = nil
        try? FileManager.default.removeItem(at: SharedPaths.activePlaylistURL)
    }
}
