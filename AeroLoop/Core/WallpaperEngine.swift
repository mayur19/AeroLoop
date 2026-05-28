import AppKit
import Combine
import Foundation

extension NSScreen {
    /// Returns the unique hardware display identifier.
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

/// The central engine that manages wallpaper windows and playback state across multiple displays.
@MainActor
class WallpaperEngine: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentWallpapers: [CGDirectDisplayID: WallpaperItem] = [:]
    @Published private(set) var activePlaylist: PlaylistWithItems?

    // For backwards compatibility with single-monitor views
    var currentWallpaper: WallpaperItem? {
        currentWallpapers.values.first
    }

    // MARK: - Private Properties

    private var wallpaperWindows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private var originalWallpaperURLs: [CGDirectDisplayID: URL] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?
    
    private var rotationTimer: Timer?
    private var playlistIndex: Int = 0
    private var shuffledIndices: [Int] = []

    // MARK: - Initialization

    init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChanges()
            }
        }
    }

    deinit {
        rotationTimer?.invalidate()
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Screen Handling

    private func handleScreenChanges() {
        let currentDisplayIDs = Set(NSScreen.screens.compactMap { $0.displayID })

        // 1. Remove windows for displays that were disconnected
        for (displayID, window) in wallpaperWindows {
            if !currentDisplayIDs.contains(displayID) {
                window.cleanup()
                wallpaperWindows.removeValue(forKey: displayID)
                currentWallpapers.removeValue(forKey: displayID)
            }
        }

        // 2. Update frames for existing displays
        for screen in NSScreen.screens {
            guard let displayID = screen.displayID,
                  let window = wallpaperWindows[displayID] else { continue }
            window.updateFrame(for: screen)
        }
        
        // 3. (Optional) Auto-apply wallpaper to newly connected displays
        if isPlaying {
            // Apply a default or playlist if necessary
        }
    }

    // MARK: - Wallpaper Management

    /// Applies a wallpaper item. If displayID is nil, applies to all screens or respects syncAllDisplays.
    func applyWallpaper(_ item: WallpaperItem, to displayID: CGDirectDisplayID? = nil, isFromPlaylist: Bool = false) {
        if !isFromPlaylist {
            stopPlaylistRotation()
        }
        
        let settings = SettingsManager.sharedDefaults
        let muted = settings.bool(forKey: "aeroloop.audioMuted")
        let syncAllDisplays = settings.bool(forKey: "aeroloop.syncAllDisplays")
        
        let targetScreens = NSScreen.screens.filter { screen in
            guard let id = screen.displayID else { return false }
            return displayID == nil || syncAllDisplays || id == displayID
        }
        
        for screen in targetScreens {
            guard let id = screen.displayID else { continue }

            // Save original wallpaper URL for later restoration
            if originalWallpaperURLs[id] == nil {
                originalWallpaperURLs[id] = NSWorkspace.shared.desktopImageURL(for: screen)
            }

            // Reuse existing window or create a new one
            let window = wallpaperWindows[id] ?? WallpaperWindow(screen: screen)
            
            window.setVideo(
                url: item.url,
                displayMode: item.displayMode,
                muted: muted
            )
            
            if activePauseReasons.isEmpty {
                window.play()
            } else {
                window.pausePlayback()
            }

            wallpaperWindows[id] = window
            currentWallpapers[id] = item
        }

        isPlaying = activePauseReasons.isEmpty
    }
    
    /// Updates the settings of all active windows on the fly
    func updateSettings(muted: Bool, displayMode: DisplayMode, qualityMode: QualityMode) {
        for window in wallpaperWindows.values {
            window.setMuted(muted)
            // If the wallpaper item doesn't dictate a specific override, or if we want to force default display mode, we could update it.
            // For now, only the mute state is globally overridden dynamically.
        }
    }

    // MARK: - Playlists
    
    func applyPlaylist(_ playlist: PlaylistWithItems) {
        guard !playlist.items.isEmpty else { return }
        
        activePlaylist = playlist
        playlistIndex = 0
        
        if playlist.playlist.shuffle {
            shuffledIndices = Array(0..<playlist.items.count).shuffled()
        } else {
            shuffledIndices = Array(0..<playlist.items.count)
        }
        
        applyWallpaper(playlist.items[shuffledIndices[0]], isFromPlaylist: true)
        startPlaylistRotation(interval: playlist.playlist.rotationInterval)
    }
    
    private func startPlaylistRotation(interval: TimeInterval) {
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextWallpaper()
            }
        }
    }
    
    private func stopPlaylistRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        activePlaylist = nil
        shuffledIndices.removeAll()
    }
    
    func nextWallpaper() {
        guard let playlist = activePlaylist, !playlist.items.isEmpty else { return }
        
        playlistIndex = (playlistIndex + 1) % playlist.items.count
        
        // Reshuffle if we hit the end of a shuffled playlist
        if playlistIndex == 0 && playlist.playlist.shuffle {
            shuffledIndices = Array(0..<playlist.items.count).shuffled()
        }
        
        let nextItem = playlist.items[shuffledIndices[playlistIndex]]
        applyWallpaper(nextItem, isFromPlaylist: true)
    }

    // MARK: - Playback Controls
    
    enum PauseReason: Hashable {
        case manual
        case battery
        case fullscreen
    }

    private var activePauseReasons: Set<PauseReason> = []

    /// Pauses video playback on all screens for a specific reason.
    func pause(reason: PauseReason = .manual) {
        activePauseReasons.insert(reason)
        updatePlaybackState()
    }

    /// Resumes video playback on all screens by removing a specific reason.
    func resume(reason: PauseReason = .manual) {
        activePauseReasons.remove(reason)
        updatePlaybackState()
    }
    
    private func updatePlaybackState() {
        if activePauseReasons.isEmpty {
            for window in wallpaperWindows.values {
                window.play()
            }
            isPlaying = true
        } else {
            for window in wallpaperWindows.values {
                window.pausePlayback()
            }
            isPlaying = false
        }
    }

    /// Stops playback entirely, destroys all wallpaper windows, and clears state.
    func stop() {
        stopPlaylistRotation()
        for window in wallpaperWindows.values {
            window.cleanup()
        }
        wallpaperWindows.removeAll()
        currentWallpapers.removeAll()
        isPlaying = false
    }

    /// Stops the live wallpaper and restores the user's original desktop images on all screens.
    func restoreOriginalWallpaper() {
        stop()

        for screen in NSScreen.screens {
            guard let displayID = screen.displayID,
                  let originalURL = originalWallpaperURLs[displayID] else { continue }

            do {
                try NSWorkspace.shared.setDesktopImageURL(originalURL, for: screen, options: [:])
            } catch {
                print("[WallpaperEngine] Failed to restore original wallpaper for display \(displayID): \(error.localizedDescription)")
            }
        }

        originalWallpaperURLs.removeAll()
    }

    /// Updates the display mode on all active wallpaper windows.
    func setDisplayMode(_ mode: DisplayMode) {
        for window in wallpaperWindows.values {
            window.setDisplayMode(mode)
        }
    }

    /// Updates the mute state on all active wallpaper windows.
    func setMuted(_ muted: Bool) {
        for window in wallpaperWindows.values {
            window.setMuted(muted)
        }
    }
}
