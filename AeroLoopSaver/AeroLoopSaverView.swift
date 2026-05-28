import ScreenSaver
import AppKit
import AVFoundation

@objc(AeroLoopSaverView)
class AeroLoopSaverView: ScreenSaverView {

    // Minimal DTOs to parse active_playlist.json without importing GRDB
    private struct SaverPlaylist: Decodable {
        let id: UUID
        let title: String
        let rotationInterval: TimeInterval
        let shuffle: Bool
    }

    private struct SaverPlaylistWithItems: Decodable {
        let playlist: SaverPlaylist
        let items: [WallpaperItem]
    }

    private var videoPlayerView: VideoPlayerView?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupVideoPlayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideoPlayer()
    }

    private var activePlaylist: SaverPlaylistWithItems?
    private var playlistIndex: Int = 0
    private var shuffledIndices: [Int] = []
    private var rotationTimer: Timer?

    private func setupVideoPlayer() {
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.backgroundColor = NSColor.black.cgColor

        let playerView = VideoPlayerView()
        playerView.frame = self.bounds
        playerView.autoresizingMask = [.width, .height]
        self.addSubview(playerView)
        self.videoPlayerView = playerView

        // 1. Check for Active Playlist
        let playlistURL = SharedPaths.activePlaylistURL
        if let data = try? Data(contentsOf: playlistURL),
           let playlist = try? JSONDecoder().decode(SaverPlaylistWithItems.self, from: data),
           !playlist.items.isEmpty {

            self.activePlaylist = playlist
            self.playlistIndex = 0

            if playlist.playlist.shuffle {
                self.shuffledIndices = Array(0..<playlist.items.count).shuffled()
            } else {
                self.shuffledIndices = Array(0..<playlist.items.count)
            }

            applyCurrentPlaylistItem()

            rotationTimer = Timer.scheduledTimer(withTimeInterval: playlist.playlist.rotationInterval, repeats: true) { [weak self] _ in
                self?.nextPlaylistItem()
            }
            return
        }

        // 2. Fallback to single active wallpaper
        let settingsURL = SharedPaths.settingsURL
        var loadedWallpaper: WallpaperItem?

        do {
            let data = try Data(contentsOf: settingsURL)
            loadedWallpaper = try JSONDecoder().decode(WallpaperItem.self, from: data)
        } catch {
            print("Failed to load settings.json: \(error)")
        }

        if let wallpaper = loadedWallpaper {
            applyWallpaper(wallpaper)
        } else {
            showError("No active wallpaper found. Please select a video in the AeroLoop app.")
        }
    }

    private func nextPlaylistItem() {
        guard let playlist = activePlaylist, !playlist.items.isEmpty else { return }

        playlistIndex = (playlistIndex + 1) % playlist.items.count

        if playlistIndex == 0 && playlist.playlist.shuffle {
            shuffledIndices = Array(0..<playlist.items.count).shuffled()
        }

        applyCurrentPlaylistItem()
    }

    private func applyCurrentPlaylistItem() {
        guard let playlist = activePlaylist, !playlist.items.isEmpty else { return }
        let item = playlist.items[shuffledIndices[playlistIndex]]
        applyWallpaper(item)
    }

    private func applyWallpaper(_ wallpaper: WallpaperItem) {
        let isReadable = FileManager.default.isReadableFile(atPath: wallpaper.url.path)

        if isReadable {
            videoPlayerView?.loadVideo(
                url: wallpaper.url,
                displayMode: wallpaper.displayMode,
                muted: true
            )
            videoPlayerView?.play()
        } else {
            showError("Cannot access video file.\nFile: \(wallpaper.url.lastPathComponent)")
        }
    }

    private func showError(_ text: String) {
        let textField = NSTextField(labelWithString: text)
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 20)
        textField.alignment = .center
        textField.frame = self.bounds
        textField.autoresizingMask = [.width, .height]
        self.addSubview(textField)
    }

    override func startAnimation() {
        super.startAnimation()
        videoPlayerView?.play()
    }

    override func stopAnimation() {
        super.stopAnimation()
        videoPlayerView?.pause()
    }

    override var hasConfigureSheet: Bool {
        return false
    }

    override var configureSheet: NSWindow? {
        return nil
    }
}
