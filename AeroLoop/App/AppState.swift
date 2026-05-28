import AppKit
import Combine
import Foundation
import SwiftUI

/// Central coordinator that owns all sub-managers and exposes a unified state
/// surface for SwiftUI views via `@EnvironmentObject`.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Sub-managers
    
    static let shared = AppState()

    let wallpaperEngine = WallpaperEngine()
    let settings = SettingsManager()
    let batteryMonitor = BatteryMonitor()
    let library = WallpaperLibraryService()
    let playlists = PlaylistService()
    let fullscreenDetector = FullscreenDetector()
    lazy var scheduleManager = ScheduleManager(engine: wallpaperEngine, settings: settings, playlists: playlists, batteryMonitor: batteryMonitor)

    // MARK: - Forwarded Published Properties

    @Published var isPlaying: Bool = false
    @Published var currentWallpaper: WallpaperItem?
    
    // MARK: - Error State
    struct AppError: Identifiable {
        let id = UUID()
        let message: String
    }
    @Published var appError: AppError?

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Forward engine state to our own published properties.
        wallpaperEngine.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)

        wallpaperEngine.$currentWallpapers
            .receive(on: RunLoop.main)
            .sink { [weak self] wallpapers in
                self?.currentWallpaper = wallpapers.values.first
            }
            .store(in: &cancellables)

        // Start monitors
        batteryMonitor.startMonitoring()
        fullscreenDetector.startMonitoring()
        
        // Start schedules after a short delay to let GRDB load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.scheduleManager.startMonitoring()
        }

        // Observe battery and fullscreen state changes — auto-pause based on settings.
        Publishers.CombineLatest(batteryMonitor.$isOnBattery, fullscreenDetector.$isFullscreenActive)
            .removeDuplicates { $0 == $1 }
            .receive(on: RunLoop.main)
            .sink { [weak self] onBattery, inFullscreen in
                guard let self else { return }
                
                let shouldPauseForBattery = onBattery && self.settings.pauseOnBattery
                let shouldPauseForFullscreen = inFullscreen && self.settings.pauseInFullscreen
                
                if shouldPauseForBattery {
                    self.wallpaperEngine.pause(reason: .battery)
                } else {
                    self.wallpaperEngine.resume(reason: .battery)
                }
                
                if shouldPauseForFullscreen {
                    self.wallpaperEngine.pause(reason: .fullscreen)
                } else {
                    self.wallpaperEngine.resume(reason: .fullscreen)
                }
            }
            .store(in: &cancellables)
            
        // Observe settings changes to propagate them dynamically.
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Delay slightly so the new value is actually set
                DispatchQueue.main.async {
                    self.wallpaperEngine.updateSettings(
                        muted: self.settings.audioMuted,
                        displayMode: self.settings.displayMode,
                        qualityMode: self.settings.qualityMode
                    )
                }
            }
            .store(in: &cancellables)

        // Restore the last wallpaper if onboarding is complete.
        if settings.hasCompletedOnboarding {
            if let activePlaylistIdStr = settings.activePlaylistId, 
               let activePlaylistId = UUID(uuidString: activePlaylistIdStr) {
                // If a playlist was active, the PlaylistService will fetch it eventually,
                // but we might need to wait for it. We'll handle playlist restoration in a Task.
                Task {
                    // Small delay to let PlaylistService fetch initial DB state
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if let playlistWithItems = self.playlists.playlists.first(where: { $0.playlist.id == activePlaylistId }) {
                        self.wallpaperEngine.applyPlaylist(playlistWithItems)
                    }
                }
            } else if let lastItem = settings.lastWallpaper {
                wallpaperEngine.applyWallpaper(lastItem)
            }
        }
    }

    // MARK: - Public Methods

    /// Apply a new wallpaper and persist the choice.
    func applyWallpaper(_ item: WallpaperItem) {
        wallpaperEngine.applyWallpaper(item)
        settings.saveLastWallpaper(item)
        settings.clearActivePlaylist()
    }
    
    /// Apply a playlist and persist the choice.
    func applyPlaylist(_ playlist: PlaylistWithItems) {
        wallpaperEngine.applyPlaylist(playlist)
        settings.saveActivePlaylist(id: playlist.playlist.id.uuidString)
        
        do {
            try SharedPaths.ensureDirectoryExists(at: SharedPaths.containerURL)
            let jsonData = try JSONEncoder().encode(playlist)
            try jsonData.write(to: SharedPaths.activePlaylistURL, options: .atomic)
        } catch {
            print("[AppState] Failed to save active playlist to JSON: \(error)")
        }
    }

    /// Toggle between play and pause.
    func togglePlayback() {
        if isPlaying {
            wallpaperEngine.pause(reason: .manual)
        } else {
            wallpaperEngine.resume(reason: .manual)
        }
    }

    /// Pause playback.
    func pause() {
        wallpaperEngine.pause(reason: .manual)
    }

    /// Resume playback.
    func resume() {
        wallpaperEngine.resume(reason: .manual)
    }

    /// Stop playback entirely.
    func stop() {
        wallpaperEngine.stop()
    }

    /// Restore the macOS original wallpaper and clear the saved state.
    func restoreOriginalWallpaper() {
        wallpaperEngine.restoreOriginalWallpaper()
        settings.clearLastWallpaper()
        settings.clearActivePlaylist()
    }
}
