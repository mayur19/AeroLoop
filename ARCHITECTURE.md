# AeroLoop Architecture

AeroLoop is a native macOS application built with Swift 5.9 and SwiftUI. It consists of two main targets:
1. **AeroLoop (App):** The main menu bar application that manages the library, settings, and desktop wallpaper windows.
2. **AeroLoopSaver (Bundle):** A native `.saver` plugin that runs in the macOS `legacyScreenSaver` process.

## App Sandbox & App Groups
To comply with Mac App Store guidelines, both targets are sandboxed. They communicate and share data through an **App Group** (`group.com.greekerlabs.aeroloop`).

*   **File Storage:** When a user imports a video, it is securely copied to the App Group container (`SharedPaths.libraryURL`).
*   **Settings:** Both the app and the screen saver read from a shared `UserDefaults` suite.
*   **State:** The main app writes the active wallpaper state to a `settings.json` or `active_playlist.json` file inside the App Group container. The heavily sandboxed Screen Saver process reads this JSON to know what to play.

## Key Components

### `Core/`
Contains the heavy lifting for video playback and window management.
*   `WallpaperWindow.swift`: A transparent, click-through `NSWindow` placed at the desktop level (`kCGDesktopWindowLevel`).
*   `VideoPlayerView.swift`: Wraps `AVPlayer` and `AVPlayerLayer` for efficient, hardware-accelerated video rendering.

### `Services/`
Background managers and system observers.
*   `SharedPaths.swift`: The central source of truth for resolving App Group paths.
*   `BatteryMonitor.swift`: Uses `IOKit` to detect power source changes.
*   `FullscreenDetector.swift`: Uses `NSWorkspace` notifications to detect when other apps enter native fullscreen mode, allowing AeroLoop to pause playback and save resources.
*   `WallpaperLibraryService.swift`: Wraps GRDB for SQLite persistence of the user's wallpaper library.

### `Models/`
Domain models like `WallpaperItem`, `Playlist`, and scaling preferences (`DisplayMode`, `QualityMode`).

## Project Generation
AeroLoop uses **XcodeGen**. The `AeroLoop.xcodeproj` file is git-ignored. To modify targets, build settings, or add files, you must edit `project.yml` and run `xcodegen generate`.
