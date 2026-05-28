import AppKit
import Combine
import Foundation

@MainActor
final class ScheduleManager: ObservableObject {
    
    private let engine: WallpaperEngine
    private let settings: SettingsManager
    private let playlists: PlaylistService
    private let batteryMonitor: BatteryMonitor
    
    private var cancellables = Set<AnyCancellable>()
    
    init(engine: WallpaperEngine, settings: SettingsManager, playlists: PlaylistService, batteryMonitor: BatteryMonitor) {
        self.engine = engine
        self.settings = settings
        self.playlists = playlists
        self.batteryMonitor = batteryMonitor
    }
    
    func startMonitoring() {
        // Monitor Battery State
        batteryMonitor.$isOnBattery
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] onBattery in
                self?.evaluateConditions()
            }
            .store(in: &cancellables)
            
        // Monitor System Appearance (Light/Dark Mode) via KVO on effective appearance
        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateConditions()
            }
            .store(in: &cancellables)
            
        // Observe Settings Changes (in case user changes a schedule playlist)
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.evaluateConditions()
                }
            }
            .store(in: &cancellables)
            
        // Initial evaluation
        evaluateConditions()
    }
    
    private func evaluateConditions() {
        // 1. Check Battery Playlist
        if batteryMonitor.isOnBattery, let idStr = settings.batteryPlaylistId, let id = UUID(uuidString: idStr) {
            applyPlaylistIfDifferent(id: id)
            return
        }
        
        // 2. Check Day / Night Playlists
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isDarkMode, let idStr = settings.nightPlaylistId, let id = UUID(uuidString: idStr) {
            applyPlaylistIfDifferent(id: id)
            return
        }
        
        if !isDarkMode, let idStr = settings.dayPlaylistId, let id = UUID(uuidString: idStr) {
            applyPlaylistIfDifferent(id: id)
            return
        }
    }
    
    private func applyPlaylistIfDifferent(id: UUID) {
        // Avoid re-applying the same playlist if it's already active
        if let currentIdStr = settings.activePlaylistId, UUID(uuidString: currentIdStr) == id {
            return
        }
        
        Task {
            // Give GRDB a moment if we're at launch
            if let pw = playlists.playlists.first(where: { $0.playlist.id == id }) {
                AppState.shared.applyPlaylist(pw)
            }
        }
    }
}
