import AppIntents
import Foundation

struct PlayWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Wallpaper"
    static var description: IntentDescription? = "Resumes playback of the current wallpaper."
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.resume()
        return .result()
    }
}

struct PauseWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Wallpaper"
    static var description: IntentDescription? = "Pauses playback of the current wallpaper."
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.pause()
        return .result()
    }
}

struct TogglePlaybackIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Wallpaper Playback"
    static var description: IntentDescription? = "Toggles playback between play and pause."
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.togglePlayback()
        return .result()
    }
}

struct NextWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Wallpaper"
    static var description: IntentDescription? = "Skips to the next wallpaper in the active playlist."
    
    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.wallpaperEngine.nextWallpaper()
        return .result()
    }
}

struct AeroLoopShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TogglePlaybackIntent(),
            phrases: [
                "Toggle playback in \(.applicationName)",
                "Play or pause \(.applicationName)"
            ],
            shortTitle: "Toggle Playback",
            systemImageName: "playpause.fill"
        )
        
        AppShortcut(
            intent: NextWallpaperIntent(),
            phrases: [
                "Next wallpaper in \(.applicationName)",
                "Skip wallpaper in \(.applicationName)"
            ],
            shortTitle: "Next Wallpaper",
            systemImageName: "forward.fill"
        )
    }
}
