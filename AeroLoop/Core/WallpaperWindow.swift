import AppKit
import AVFoundation
import SwiftUI

/// A borderless, desktop-level window used to render a live video wallpaper
/// behind the desktop icons.
class WallpaperWindow: NSWindow {

    // MARK: - Properties

    private let playerView: VideoPlayerView
    private var screenObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(screen: NSScreen) {
        let frame = screen.frame
        playerView = VideoPlayerView(frame: NSRect(origin: .zero, size: frame.size))

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Desktop-level configuration
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = true
        hasShadow = false
        backgroundColor = .black
        ignoresMouseEvents = true
        isReleasedWhenClosed = false

        let overlayHostingView = NSHostingView(rootView: OverlayView(settings: AppState.shared.settings))
        overlayHostingView.frame = playerView.bounds
        overlayHostingView.autoresizingMask = [.width, .height]
        
        // Ensure NSHostingView has a transparent background
        overlayHostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        playerView.addSubview(overlayHostingView)
        contentView = playerView
        orderFront(nil)

        // Observe screen layout changes
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, let currentScreen = self.screen ?? NSScreen.main else { return }
            self.updateFrame(for: currentScreen)
        }
    }

    // MARK: - Public API

    /// Sets a video on the player view and prepares for playback.
    func setVideo(url: URL, displayMode: DisplayMode, muted: Bool) {
        playerView.loadVideo(url: url, displayMode: displayMode, muted: muted)
    }

    func play() {
        playerView.play()
    }

    /// Pauses video playback. Named to avoid conflict with `NSResponder.pause(_:)`.
    func pausePlayback() {
        playerView.pause()
    }

    func setMuted(_ muted: Bool) {
        playerView.setMuted(muted)
    }

    func setDisplayMode(_ mode: DisplayMode) {
        playerView.setDisplayMode(mode)
    }

    /// Repositions and resizes the window to match the given screen.
    func updateFrame(for screen: NSScreen) {
        setFrame(screen.frame, display: true)
        playerView.frame = NSRect(origin: .zero, size: screen.frame.size)
    }

    // MARK: - Window Behavior Overrides

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // MARK: - Cleanup

    /// Cleans up the player view, removes the observer, and closes the window.
    func cleanup() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
        playerView.cleanup()
        close()
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
