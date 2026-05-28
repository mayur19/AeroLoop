import AppKit
import AVFoundation

/// An NSView subclass that hosts an AVPlayerLayer for looping video playback.
class VideoPlayerView: NSView {

    // MARK: - Private Properties

    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layer = CALayer()
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer = CALayer()
        wantsLayer = true
    }

    override func makeBackingLayer() -> CALayer {
        return CALayer()
    }

    // MARK: - Video Loading

    /// Loads a video from the given URL and begins looping playback.
    func loadVideo(url: URL, displayMode: DisplayMode, muted: Bool = true) {
        cleanup()

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(items: [item])
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = displayMode.avLayerVideoGravity
        layer.frame = bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        self.layer?.addSublayer(layer)

        queuePlayer.isMuted = muted

        self.player = queuePlayer
        self.playerLayer = layer
        self.playerLooper = looper
    }

    // MARK: - Playback Controls

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func setDisplayMode(_ mode: DisplayMode) {
        playerLayer?.videoGravity = mode.avLayerVideoGravity
    }

    // MARK: - Layout

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    // MARK: - Cleanup

    /// Tears down the player, removes sublayers, and nils all references.
    func cleanup() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLooper = nil
        playerLayer = nil
        player = nil
    }
}
