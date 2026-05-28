import SwiftUI
import UniformTypeIdentifiers

/// The dropdown menu content shown from the menu bar icon.
struct MenuBarView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    @State private var isFilePickerPresented = false

    var body: some View {
        // MARK: - Now Playing

        if let activePlaylist = appState.wallpaperEngine.activePlaylist {
            Text(activePlaylist.playlist.title)
                .font(.headline)
            Text("Playing playlist")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let wallpaper = appState.currentWallpaper {
            Text(wallpaper.title)
                .font(.headline)
            Text(wallpaper.metadataLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("No wallpaper active")
                .foregroundStyle(.secondary)
        }

        Divider()

        // MARK: - Playback Controls

        if appState.currentWallpaper != nil {
            Button {
                appState.togglePlayback()
            } label: {
                Label(
                    appState.isPlaying ? "Pause" : "Resume",
                    systemImage: appState.isPlaying ? "pause.fill" : "play.fill"
                )
            }
            .keyboardShortcut("p", modifiers: [.command])

            if appState.wallpaperEngine.activePlaylist != nil {
                Button {
                    appState.wallpaperEngine.nextWallpaper()
                } label: {
                    Label("Next Wallpaper", systemImage: "forward.fill")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }

        Divider()

        // MARK: - Actions

        Button {
            isFilePickerPresented = true
        } label: {
            Label("Change Wallpaper…", systemImage: "photo.on.rectangle")
        }
        .keyboardShortcut("o", modifiers: [.command])
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }

        Button {
            appState.restoreOriginalWallpaper()
        } label: {
            Label("Restore Original Wallpaper", systemImage: "arrow.uturn.backward")
        }
        .disabled(appState.currentWallpaper == nil)

        Divider()

        // MARK: - Toggles

        Toggle(isOn: Binding(
            get: { appState.settings.pauseOnBattery },
            set: { appState.settings.pauseOnBattery = $0 }
        )) {
            Label("Battery Saver", systemImage: "battery.100")
        }

        Divider()

        // MARK: - Navigation

        Button {
            openWindow(id: "library")
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        } label: {
            Label("Open Library", systemImage: "rectangle.stack")
        }
        .keyboardShortcut("l", modifiers: [.command])

        Button {
            openWindow(id: "settings")
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        } label: {
            Label("Settings…", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        // MARK: - Quit

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit AeroLoop", systemImage: "xmark.circle")
        }
        .keyboardShortcut("q", modifiers: [.command])
    }

    // MARK: - Helpers

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }

        // Start security-scoped access.
        let didStart = url.startAccessingSecurityScopedResource()

        // Create a security-scoped bookmark before losing access
        let bookmark = BookmarkManager.createBookmark(for: url)

        Task {
            do {
                let durableURL = try await VideoMetadataService.importVideoToLibrary(url: url)
                var item = await VideoMetadataService.extractMetadata(from: durableURL)
                item.bookmarkData = bookmark
                appState.applyWallpaper(item)
                await appState.library.add(item)
            } catch {
                appState.appError = AppState.AppError(message: "Failed to import video: \(error.localizedDescription)")
            }
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
    }
}
