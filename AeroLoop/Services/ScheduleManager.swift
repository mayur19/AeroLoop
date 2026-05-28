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
            .sink { [weak self] _ in
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
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Precedence (battery > night > day) lives in the pure, testable
        // ScheduleDecision; this method only wires in the live conditions and
        // applies the result.
        guard let id = ScheduleDecision.resolvedPlaylistID(
            isOnBattery: batteryMonitor.isOnBattery,
            isDarkMode: isDarkMode,
            batteryPlaylistId: settings.batteryPlaylistId,
            nightPlaylistId: settings.nightPlaylistId,
            dayPlaylistId: settings.dayPlaylistId
        ) else { return }

        applyPlaylistIfDifferent(id: id)
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
